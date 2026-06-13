package com.ajou.api;

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
 * 邮箱验证码登录（账号密码登录之外的备选方式）。请求 {@code {email, code}}。
 * 校验 login 场景验证码 → 命中已注册用户即签发 token。
 */
@WebServlet("/auth_login_code.php")
public class AuthLoginCodeServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();
    private final EmailCodeDao codeDao = new EmailCodeDao();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        JsonNode body = Json.readBody(req);
        String email = Json.str(body, "email").trim().toLowerCase();
        String code = Json.str(body, "code").trim();

        if (email.isEmpty() || !email.contains("@")) {
            Json.fail(resp, 422, "请输入有效的邮箱");
            return;
        }
        if (code.isEmpty()) {
            Json.fail(resp, 422, "请输入验证码");
            return;
        }
        try {
            User u = userDao.findByEmail(email);
            if (u == null) {
                Json.fail(resp, 422, "该邮箱尚未注册");
                return;
            }
            if (u.isDisabled()) {
                Json.fail(resp, 422, "该账号已被禁用");
                return;
            }
            if (!codeDao.consume(email, code, "login")) {
                Json.fail(resp, 422, "验证码无效或已过期");
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
