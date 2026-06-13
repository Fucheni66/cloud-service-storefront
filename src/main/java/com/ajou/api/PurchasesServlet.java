package com.ajou.api;

import com.ajou.common.web.Json;
import com.ajou.order.dao.CloudOrderDao;
import com.ajou.order.model.CloudOrder;
import com.ajou.user.dao.UserDao;
import com.ajou.user.model.User;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * 我的服务 / 购买记录（前台路径兼容 PHP /purchases.php）。
 * GET：按 Bearer token 返回本人订单/实例列表；POST：支付成功后写一条订单。
 */
@WebServlet("/purchases.php")
public class PurchasesServlet extends HttpServlet {

    private static final String STATUS_CLASS_RUNNING = "bg-green-50 text-green-600 border-green-200";
    private static final String STATUS_CLASS_EXPIRED = "bg-red-50 text-red-500 border-red-200";
    private static final Random RANDOM = new Random();

    private final CloudOrderDao orderDao = new CloudOrderDao();
    private final UserDao userDao = new UserDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            Integer uid = AuthSupport.userIdFromRequest(req);
            if (uid == null) {
                Json.fail(resp, 401, "login is required");
                return;
            }
            User user = userDao.findById(uid);
            List<CloudOrder> orders = orderDao.findByUserId(uid);
            List<Map<String, Object>> items = new ArrayList<>();
            for (CloudOrder o : orders) {
                items.add(toItem(o));
            }
            Map<String, Object> data = Json.map();
            if (user != null) {
                data.put("user", AuthSupport.userMap(user));
            }
            data.put("items", items);
            Json.ok(resp, data);
        } catch (SQLException e) {
            Json.fail(resp, 500, "查询失败");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            Integer uid = AuthSupport.userIdFromRequest(req);
            if (uid == null) {
                Json.fail(resp, 401, "login is required");
                return;
            }
            User user = userDao.findById(uid);
            JsonNode body = Json.readBody(req);
            String orderNo = Json.str(body, "order_id");
            if (orderNo.isEmpty()) {
                Json.fail(resp, 422, "order_id is required");
                return;
            }
            JsonNode svc = body.get("service");
            if (svc == null) {
                svc = Json.MAPPER.createObjectNode();
            }

            // 幂等：订单号已存在则直接返回
            if (orderDao.existsByOrderNo(orderNo)) {
                Map<String, Object> data = Json.map();
                data.put("message", "purchase already exists");
                Json.ok(resp, data);
                return;
            }

            CloudOrder o = new CloudOrder();
            o.setOrderNo(orderNo);
            o.setUserId(uid);
            o.setUserEmail(user != null ? user.getEmail() : Json.str(svc, "user_email"));
            o.setInstanceCode(firstNonEmpty(Json.str(svc, "productCode"), Json.str(svc, "instance")));
            o.setInstanceName(firstNonEmpty(Json.str(svc, "name"), "云服务器"));
            o.setRegion(Json.str(svc, "region"));
            o.setOs(Json.str(svc, "os"));
            o.setDisk(Json.str(svc, "disk"));
            o.setBilling(firstNonEmpty(Json.str(svc, "billing"), "包年包月"));
            o.setPublicIp(resolveIp(Json.str(svc, "publicIp")));
            o.setAmount(parseMoney(firstNonEmpty(Json.str(svc, "monthlyCost"), Json.str(body, "amount"))));
            o.setStatus("running");
            o.setPaidAt(new Timestamp(System.currentTimeMillis()));
            o.setExpireAt(parseDate(Json.str(svc, "expireAt")));
            orderDao.insert(o);

            Map<String, Object> data = Json.map();
            data.put("item", toItem(o));
            data.put("message", "purchase saved");
            Json.ok(resp, data);
        } catch (SQLException e) {
            Json.fail(resp, 500, "保存失败");
        }
    }

    /** cloud_orders → 前台 items[] 字段。 */
    private Map<String, Object> toItem(CloudOrder o) {
        boolean running = "running".equals(o.getStatus());
        Map<String, Object> m = Json.map();
        m.put("id", o.getOrderNo());
        m.put("name", o.getInstanceName());
        m.put("category", isGpu(o.getInstanceCode()) ? "GPU 云服务器" : "云服务器 ECS");
        m.put("instance", instanceLabel(o.getInstanceCode()));
        m.put("region", o.getRegion());
        m.put("status", running ? "运行中" : ("expired".equals(o.getStatus()) ? "已到期" : o.getStatusLabel()));
        m.put("statusClass", running ? STATUS_CLASS_RUNNING : STATUS_CLASS_EXPIRED);
        m.put("publicIp", o.getPublicIp() == null ? "" : o.getPublicIp());
        m.put("os", o.getOs() == null ? "" : o.getOs());
        m.put("disk", o.getDisk() == null ? "" : o.getDisk());
        m.put("billing", o.getBilling() == null ? "" : o.getBilling());
        m.put("expireAt", o.getExpireAt() == null ? "按量资源" : o.getExpireAt().toString());
        m.put("monthlyCost", o.getAmount() == null ? "0.00" : o.getAmount().toString());
        m.put("paidAt", o.getPaidAt() == null ? "" : o.getPaidAt().toInstant().toString());
        return m;
    }

    private boolean isGpu(String code) {
        return code != null && code.startsWith("gpu");
    }

    private String instanceLabel(String code) {
        if (code == null) {
            return "";
        }
        switch (code) {
            case "2c4g":     return "2核 4G";
            case "4c8g":     return "4核 8G";
            case "8c16g":    return "8核 16G";
            case "gpu_t4":   return "GPU T4";
            case "gpu_a100": return "GPU A100";
            default:         return code;
        }
    }

    private String resolveIp(String ip) {
        if (ip != null && ip.matches("\\d{1,3}(\\.\\d{1,3}){3}")) {
            return ip;
        }
        return "39.105." + RANDOM.nextInt(256) + "." + (RANDOM.nextInt(254) + 1);
    }

    private String firstNonEmpty(String a, String b) {
        return a != null && !a.isBlank() ? a : b;
    }

    private BigDecimal parseMoney(String s) {
        try {
            return s == null || s.isBlank() ? BigDecimal.ZERO : new BigDecimal(s.trim());
        } catch (NumberFormatException e) {
            return BigDecimal.ZERO;
        }
    }

    private java.sql.Date parseDate(String s) {
        if (s == null || s.isBlank()) {
            return null;
        }
        try {
            return java.sql.Date.valueOf(LocalDate.parse(s.trim()));
        } catch (Exception e) {
            return null; // “按量资源”等非日期值
        }
    }
}
