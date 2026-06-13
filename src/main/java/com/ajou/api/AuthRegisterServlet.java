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
import java.util.UUID;

/**
 * 邮箱注册（前台路径兼容 PHP /auth_register.php）。
 * 校验验证码 → 查重 → BCrypt → 落 users(provider=email) → 签发 token。
 */
@WebServlet("/auth_register.php")
public class AuthRegisterServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();
    private final EmailCodeDao codeDao = new EmailCodeDao();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        JsonNode body = Json.readBody(req);
        String email = Json.str(body, "email").trim().toLowerCase();
        String password = Json.str(body, "password");
        String code = Json.str(body, "code").trim();

        if (email.isEmpty() || !email.contains("@")) {
            Json.fail(resp, 422, "请输入有效的邮箱");
            return;
        }
        if (password.length() < 6) {
            Json.fail(resp, 422, "密码长度至少 6 位");
            return;
        }
        try {
            if (userDao.findByEmail(email) != null) {
                Json.fail(resp, 422, "该邮箱已注册");
                return;
            }
            if (!codeDao.consume(email, code, "register")) {
                Json.fail(resp, 422, "验证码无效或已过期");
                return;
            }
            User u = new User();
            u.setExtId("email_user_" + UUID.randomUUID().toString().replace("-", ""));
            u.setProvider("email");
            u.setEmail(email);
            u.setDisplayName(email);
            u.setEmailVerified(true);
            u.setPasswordHash(PasswordUtil.hash(password));
            int id = userDao.insertCustomer(u);
            u.setId(id);
            String token = AuthSupport.issueToken(id);
            AuthSupport.writeLogin(resp, u, token, "注册成功");
        } catch (SQLException e) {
            Json.fail(resp, 500, "注册失败，请稍后重试");
        }
    }
}
