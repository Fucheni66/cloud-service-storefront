package com.ajou.api;

import com.ajou.common.security.TokenService;
import com.ajou.common.web.Json;
import com.ajou.user.dao.AuthTokenDao;
import com.ajou.user.model.User;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 前台认证公共支撑：token 签发、登录响应、Bearer 解析。
 * 响应格式对齐前台 auth.js 期望（saveLoginInfo 读取 data.token / data.user.{name,email,picture}）。
 */
public final class AuthSupport {

    private static final AuthTokenDao TOKEN_DAO = new AuthTokenDao();

    private AuthSupport() {
    }

    /** 为用户签发并持久化一个 token。 */
    public static String issueToken(int userId) throws SQLException {
        String token = TokenService.generate();
        TOKEN_DAO.insert(token, userId);
        return token;
    }

    /** 构建前台需要的 user 对象。 */
    public static Map<String, Object> userMap(User u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getExtId());
        String name = (u.getDisplayName() != null && !u.getDisplayName().isBlank())
                ? u.getDisplayName() : u.getEmail();
        m.put("name", name);
        m.put("email", u.getEmail());
        m.put("picture", u.getPicture() == null ? "" : u.getPicture());
        m.put("provider", u.getProvider());
        return m;
    }

    /** 输出登录/注册成功响应：{ success, token, user, message }。 */
    public static void writeLogin(HttpServletResponse resp, User u, String token, String message)
            throws IOException {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("token", token);
        data.put("user", userMap(u));
        data.put("message", message);
        Json.ok(resp, data);
    }

    /** 从 Authorization: Bearer <token> 解析出 user_id，未登录返回 null。 */
    public static Integer userIdFromRequest(HttpServletRequest req) throws SQLException {
        String header = req.getHeader("Authorization");
        if (header == null || header.isBlank()) {
            return null;
        }
        String token = header.startsWith("Bearer ") ? header.substring(7).trim() : header.trim();
        return TOKEN_DAO.findUserId(token);
    }
}
