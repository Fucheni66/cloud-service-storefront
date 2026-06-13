package com.ajou.api;

import com.ajou.common.security.PasswordUtil;
import com.ajou.common.web.Json;
import com.ajou.user.dao.EmailCodeDao;
import com.ajou.user.dao.UserDao;
import com.ajou.user.model.User;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * 忘记密码 / 重置密码。请求 {@code {email, code, password}}。
 * 校验 reset 场景验证码 → 重置 BCrypt 密码哈希。
 */
@WebServlet("/auth_reset.php")
public class PasswordResetServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();
    private final EmailCodeDao codeDao = new EmailCodeDao();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        JsonNode body = Json.readBody(req);
        String email = Json.str(body, "email").trim().toLowerCase();
        String code = Json.str(body, "code").trim();
        String password = Json.str(body, "password");

        if (email.isEmpty() || !email.contains("@")) {
            Json.fail(resp, 422, "请输入有效的邮箱");
            return;
        }
        if (password.length() < 6) {
            Json.fail(resp, 422, "新密码长度至少 6 位");
            return;
        }
        try {
            User u = userDao.findByEmail(email);
            if (u == null) {
                Json.fail(resp, 422, "该邮箱尚未注册");
                return;
            }
            if (!codeDao.consume(email, code, "reset")) {
                Json.fail(resp, 422, "验证码无效或已过期");
                return;
            }
            userDao.updatePassword(u.getId(), PasswordUtil.hash(password));

            java.util.Map<String, Object> data = Json.map();
            data.put("message", "密码已重置，请使用新密码登录");
            Json.ok(resp, data);
        } catch (SQLException e) {
            Json.fail(resp, 500, "密码重置失败，请稍后重试");
        }
    }
}
