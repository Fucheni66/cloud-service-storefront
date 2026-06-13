package com.ajou.api;

import com.ajou.common.web.Json;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.management.ManagementFactory;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * 本机真实系统监控（前台控制台「监控概览」数据源）。
 *
 * <p>读取运行 Tomcat 的服务器本机指标，跨平台兼容 macOS 与 Linux(CentOS/Ubuntu 等)：
 * CPU/内存使用率经 {@code com.sun.management.OperatingSystemMXBean} 获取；磁盘使用率取根分区；
 * 公网带宽为相邻两次采样的网卡吞吐速率（Mbps，最佳努力）。需登录（Bearer token）。</p>
 *
 * 返回 {@code { success, cpu, mem, disk, net }}，数值为百分比 / Mbps。
 */
@WebServlet("/api/system-monitor")
public class SystemMonitorServlet extends HttpServlet {

    /** 网卡累计字节数 + 采样时刻，用于计算速率（进程内单实例，故用静态缓存）。 */
    private static volatile long lastNetBytes = -1L;
    private static volatile long lastNetNanos = 0L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            if (AuthSupport.userIdFromRequest(req) == null) {
                Json.fail(resp, 401, "登录已失效，请重新登录");
                return;
            }
        } catch (SQLException e) {
            Json.fail(resp, 500, "鉴权失败");
            return;
        }

        Map<String, Object> data = Json.map();
        data.put("cpu", readCpuPercent());
        data.put("mem", readMemPercent());
        data.put("disk", readDiskPercent());
        data.put("net", readNetMbps());
        data.put("host", System.getProperty("os.name", ""));
        Json.ok(resp, data);
    }

    /** CPU 使用率（整数百分比）。 */
    private int readCpuPercent() {
        try {
            com.sun.management.OperatingSystemMXBean os =
                    (com.sun.management.OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();
            double load = os.getCpuLoad();
            if (load < 0 || Double.isNaN(load)) {
                double avg = os.getSystemLoadAverage();
                int cores = Math.max(1, os.getAvailableProcessors());
                load = avg < 0 ? 0 : Math.min(1.0, avg / cores);
            }
            return clampPercent(load * 100.0);
        } catch (Throwable t) {
            return 0;
        }
    }

    /** 物理内存使用率（整数百分比）。 */
    private int readMemPercent() {
        try {
            com.sun.management.OperatingSystemMXBean os =
                    (com.sun.management.OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();
            long total = os.getTotalMemorySize();
            long free = os.getFreeMemorySize();
            if (total <= 0) {
                return 0;
            }
            return clampPercent((total - free) * 100.0 / total);
        } catch (Throwable t) {
            return 0;
        }
    }

    /** 根分区磁盘使用率（整数百分比）。 */
    private int readDiskPercent() {
        try {
            File root = new File("/");
            long total = root.getTotalSpace();
            long usable = root.getUsableSpace();
            if (total <= 0) {
                return 0;
            }
            return clampPercent((total - usable) * 100.0 / total);
        } catch (Throwable t) {
            return 0;
        }
    }

    /** 网卡吞吐速率（Mbps，相邻采样差分，最佳努力，失败返回 0）。 */
    private int readNetMbps() {
        try {
            long bytes = readTotalNetBytes();
            long now = System.nanoTime();
            if (bytes < 0) {
                return 0;
            }
            int mbps = 0;
            long prevBytes = lastNetBytes;
            long prevNanos = lastNetNanos;
            if (prevBytes >= 0 && now > prevNanos) {
                double seconds = (now - prevNanos) / 1_000_000_000.0;
                if (seconds > 0 && bytes >= prevBytes) {
                    double bitsPerSec = (bytes - prevBytes) * 8.0 / seconds;
                    mbps = (int) Math.round(bitsPerSec / 1_000_000.0);
                }
            }
            lastNetBytes = bytes;
            lastNetNanos = now;
            return Math.max(0, Math.min(10_000, mbps));
        } catch (Throwable t) {
            return 0;
        }
    }

    /** 读取所有非 lo 网卡的累计收发字节数之和，失败返回 -1。 */
    private long readTotalNetBytes() {
        String os = System.getProperty("os.name", "").toLowerCase();
        try {
            if (os.contains("linux")) {
                return readLinuxNetBytes();
            }
            if (os.contains("mac") || os.contains("darwin")) {
                return readMacNetBytes();
            }
        } catch (Exception e) {
            return -1L;
        }
        return -1L;
    }

    private long readLinuxNetBytes() throws IOException {
        Path proc = Path.of("/proc/net/dev");
        if (!Files.exists(proc)) {
            return -1L;
        }
        long total = 0L;
        for (String line : Files.readAllLines(proc, StandardCharsets.UTF_8)) {
            int colon = line.indexOf(':');
            if (colon < 0) {
                continue;
            }
            String iface = line.substring(0, colon).trim();
            if (iface.equals("lo") || iface.startsWith("lo")) {
                continue;
            }
            String[] cols = line.substring(colon + 1).trim().split("\\s+");
            if (cols.length >= 9) {
                total += parseLong(cols[0]);  // 接收字节
                total += parseLong(cols[8]);  // 发送字节
            }
        }
        return total;
    }

    private long readMacNetBytes() throws IOException, InterruptedException {
        Process p = new ProcessBuilder("/usr/bin/netstat", "-ibn").redirectErrorStream(true).start();
        long total = 0L;
        java.util.Set<String> seen = new java.util.HashSet<>();
        try (BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            boolean header = true;
            while ((line = r.readLine()) != null) {
                if (header) { header = false; continue; }   // 跳过表头
                String[] cols = line.trim().split("\\s+");
                if (cols.length < 11) {
                    continue;
                }
                String iface = cols[0];
                if (iface.startsWith("lo") || !seen.add(iface)) {
                    continue;   // 排除回环 + 每个网卡只计一次（netstat 每卡多行）
                }
                total += parseLong(cols[6]);   // Ibytes
                total += parseLong(cols[9]);   // Obytes
            }
        }
        p.waitFor();
        return total;
    }

    private long parseLong(String s) {
        try {
            return Long.parseLong(s.trim());
        } catch (NumberFormatException e) {
            return 0L;
        }
    }

    private int clampPercent(double v) {
        if (Double.isNaN(v)) {
            return 0;
        }
        return (int) Math.round(Math.max(0, Math.min(100, v)));
    }
}
