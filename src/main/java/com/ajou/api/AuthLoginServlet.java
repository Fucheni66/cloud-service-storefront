package com.ajou.api;

import com.ajou.common.security.PasswordUtil;
import com.ajou.common.web.Json;
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
 * 邮箱登录（前台路径兼容 PHP /auth_login.php）。
 */
@WebServlet("/auth_login.php")
public class AuthLoginServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        JsonNode body = Json.readBody(req);
        String email = Json.str(body, "email").trim().toLowerCase();
        String password = Json.str(body, "password");

        try {
            User u = email.isEmpty() ? null : userDao.findByEmail(email);
            if (u == null || u.isDisabled() || !PasswordUtil.verify(password, u.getPasswordHash())) {
                Json.fail(resp, 422, "邮箱或密码错误");
                return;
            }
            String token = AuthSupport.issueToken(u.getId());
            userDao.touchLogin(u.getId());
            AuthSupport.writeLogin(resp, u, token, "登录成功");
        } catch (SQLException e) {
            Json.fail(resp, 500, "登录失败，请稍后重试");
        }
    }
}
