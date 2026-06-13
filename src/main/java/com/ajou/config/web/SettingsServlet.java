package com.ajou.config.web;

import com.ajou.common.mail.MailException;
import com.ajou.common.mail.SmtpMailService;
import com.ajou.config.dao.AppConfigDao;
import com.ajou.config.model.AppConfig;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.sql.SQLException;

/**
 * 系统配置（Google / 支付宝 / 微信 JSAPI / 站点）。
 * 按分组展示与保存；敏感项（is_secret）不回显，提交留空表示保持原值。
 */
@WebServlet("/admin/settings")
public class SettingsServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/settings.jsp";
    /** 合法分组，避免任意 group 注入。 */
    private static final Set<String> GROUPS = Set.of("google", "alipay", "wechat", "site", "ai", "smtp");
    private static final String DEFAULT_GROUP = "google";

    private final AppConfigDao dao = new AppConfigDao();
    private final SmtpMailService mailService = new SmtpMailService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String group = normalizeGroup(req.getParameter("group"));
        try {
            req.setAttribute("group", group);
            req.setAttribute("configs", dao.findByGroup(group));
            req.getRequestDispatcher(VIEW).forward(req, resp);
        } catch (SQLException e) {
            throw new ServletException("读取配置失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String group = normalizeGroup(req.getParameter("group"));

        // 发送测试邮件（SMTP 分组专用，独立于保存配置）
        if ("testMail".equals(req.getParameter("action"))) {
            sendTestMail(req, resp);
            return;
        }

        try {
            List<AppConfig> configs = dao.findByGroup(group);
            for (AppConfig c : configs) {
                String submitted = req.getParameter(c.getConfigKey());
                // 敏感项留空 → 保持原值；非敏感项按提交值更新（含清空）
                if (c.isSecret() && (submitted == null || submitted.isBlank())) {
                    continue;
                }
                if (submitted == null) {
                    submitted = "";
                }
                dao.updateValue(c.getConfigKey(), submitted.trim());
            }
            resp.sendRedirect(req.getContextPath() + "/admin/settings?group=" + group + "&saved=1");
        } catch (SQLException e) {
            throw new ServletException("保存配置失败", e);
        }
    }

    /** 发送一封测试邮件到指定邮箱，验证 SMTP 配置是否可用。 */
    private void sendTestMail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String to = req.getParameter("testTo");
        String base = req.getContextPath() + "/admin/settings?group=smtp";
        if (to == null || to.isBlank() || !to.contains("@")) {
            resp.sendRedirect(base + "&testError=" + enc("请输入有效的收件邮箱"));
            return;
        }
        try {
            String html = "<div style=\"font-family:sans-serif;color:#374151;\">"
                    + "<h2 style=\"color:#0052d9;\">AJOU 云服务 · SMTP 测试邮件</h2>"
                    + "<p>这是一封来自后台「系统设置 > SMTP 邮件」的测试邮件，收到即表示发信链路正常。</p>"
                    + "</div>";
            mailService.send(to.trim(), "【AJOU 云服务】SMTP 配置测试邮件", html);
            resp.sendRedirect(base + "&tested=1");
        } catch (MailException e) {
            resp.sendRedirect(base + "&testError=" + enc(e.getMessage()));
        }
    }

    private String enc(String s) {
        return java.net.URLEncoder.encode(s == null ? "" : s, java.nio.charset.StandardCharsets.UTF_8);
    }

    private String normalizeGroup(String group) {
        return group != null && GROUPS.contains(group) ? group : DEFAULT_GROUP;
    }
}
