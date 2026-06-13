package com.ajou.api;

import com.ajou.common.mail.MailException;
import com.ajou.common.mail.SmtpMailService;
import com.ajou.common.web.Json;
import com.ajou.user.dao.EmailCodeDao;
import com.ajou.user.dao.UserDao;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.security.SecureRandom;
import java.sql.SQLException;
import java.util.Map;
import java.util.Set;

/**
 * 发送邮箱验证码（前台路径兼容 PHP /auth_code.php）。
 *
 * <p>请求 {@code {email, scene}}，scene 取 register/login/reset，默认 register。
 * 验证码经 SMTP 真实发送到邮箱，不再随响应明文返回。60 秒内同邮箱同场景限发一次。</p>
 */
@WebServlet("/auth_code.php")
public class AuthCodeServlet extends HttpServlet {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final Set<String> SCENES = Set.of("register", "login", "reset");
    private static final int RESEND_INTERVAL_SECONDS = 60;

    private final EmailCodeDao codeDao = new EmailCodeDao();
    private final UserDao userDao = new UserDao();
    private final SmtpMailService mailService = new SmtpMailService();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        JsonNode body = Json.readBody(req);
        String email = Json.str(body, "email").trim().toLowerCase();
        String scene = Json.str(body, "scene").trim();
        if (!SCENES.contains(scene)) {
            scene = "register";
        }
        if (email.isEmpty() || !email.contains("@")) {
            Json.fail(resp, 422, "请输入有效的邮箱");
            return;
        }

        try {
            // 场景前置校验：注册要求邮箱未占用；登录/找回要求邮箱已注册。
            boolean exists = userDao.findByEmail(email) != null;
            if ("register".equals(scene) && exists) {
                Json.fail(resp, 422, "该邮箱已注册，请直接登录");
                return;
            }
            if (("login".equals(scene) || "reset".equals(scene)) && !exists) {
                Json.fail(resp, 422, "该邮箱尚未注册");
                return;
            }

            if (codeDao.sentWithin(email, scene, RESEND_INTERVAL_SECONDS)) {
                Json.fail(resp, 429, "验证码发送过于频繁，请稍后再试");
                return;
            }

            if (!mailService.isConfigured()) {
                Json.fail(resp, 503, "邮件服务尚未配置，请联系管理员在后台设置 SMTP");
                return;
            }

            String code = String.format("%06d", RANDOM.nextInt(1_000_000));
            codeDao.insert(email, code, scene);
            mailService.sendVerificationCode(email, code, scene);
        } catch (SQLException e) {
            Json.fail(resp, 500, "验证码发送失败，请重试");
            return;
        } catch (MailException e) {
            Json.fail(resp, 502, e.getMessage());
            return;
        }

        Map<String, Object> data = Json.map();
        data.put("email", email);
        data.put("message", "验证码已发送至邮箱，请查收（10 分钟内有效）");
        Json.ok(resp, data);
    }
}
