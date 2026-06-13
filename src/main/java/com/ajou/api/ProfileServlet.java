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
import java.util.Base64;
import java.util.Map;

/**
 * 前台个人中心 API（需 Authorization: Bearer token）。
 *
 * <pre>
 * GET  /api/profile               当前用户信息（含是否已绑定 Google / 是否设置过密码）
 * POST /api/profile/password      修改密码 {oldPassword, newPassword}
 * POST /api/profile/google/bind   关联登录-绑定 Google {credential}
 * POST /api/profile/google/unbind 关联登录-解绑 Google
 * </pre>
 */
@WebServlet(urlPatterns = {"/api/profile", "/api/profile/*"})
public class ProfileServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try {
            User u = currentUser(req);
            if (u == null) {
                Json.fail(resp, 401, "登录已失效，请重新登录");
                return;
            }
            Json.ok(resp, profileData(u));
        } catch (SQLException e) {
            Json.fail(resp, 500, "读取个人信息失败");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String path = req.getPathInfo() == null ? "" : req.getPathInfo();
        try {
            User u = currentUser(req);
            if (u == null) {
                Json.fail(resp, 401, "登录已失效，请重新登录");
                return;
            }
            switch (path) {
                case "/password":    changePassword(req, resp, u); break;
                case "/google/bind": bindGoogle(req, resp, u); break;
                case "/google/unbind": unbindGoogle(resp, u); break;
                default: Json.fail(resp, 404, "未知操作");
            }
        } catch (SQLException e) {
            Json.fail(resp, 500, "操作失败，请稍后重试");
        }
    }

    // ---- 修改密码 ----
    private void changePassword(HttpServletRequest req, HttpServletResponse resp, User u)
            throws IOException, SQLException {
        JsonNode body = Json.readBody(req);
        String oldPassword = Json.str(body, "oldPassword");
        String newPassword = Json.str(body, "newPassword");
        if (newPassword.length() < 6) {
            Json.fail(resp, 422, "新密码长度至少 6 位");
            return;
        }
        boolean hasPassword = u.getPasswordHash() != null && !u.getPasswordHash().isBlank();
        if (hasPassword && !PasswordUtil.verify(oldPassword, u.getPasswordHash())) {
            Json.fail(resp, 422, "原密码不正确");
            return;
        }
        userDao.updatePassword(u.getId(), PasswordUtil.hash(newPassword));
        Map<String, Object> data = Json.map();
        data.put("message", hasPassword ? "密码已修改" : "密码已设置，之后可用邮箱+密码登录");
        Json.ok(resp, data);
    }

    // ---- 绑定 Google ----
    private void bindGoogle(HttpServletRequest req, HttpServletResponse resp, User u)
            throws IOException, SQLException {
        JsonNode body = Json.readBody(req);
        String credential = Json.str(body, "credential");
        if (credential.isEmpty()) {
            credential = Json.str(body, "id_token");
        }
        JsonNode payload = decodeJwtPayload(credential);
        if (payload == null) {
            Json.fail(resp, 422, "无效的 Google 凭证");
            return;
        }
        String sub = payload.path("sub").asText("");
        String picture = payload.path("picture").asText("");
        if (sub.isEmpty()) {
            Json.fail(resp, 422, "Google 凭证缺少必要信息");
            return;
        }
        User owner = userDao.findByGoogleSub(sub);
        if (owner != null && owner.getId() != u.getId()) {
            Json.fail(resp, 409, "该 Google 账号已绑定到其他用户");
            return;
        }
        userDao.bindGoogle(u.getId(), sub, picture);
        User fresh = userDao.findById(u.getId());
        Map<String, Object> data = profileData(fresh);
        data.put("message", "已绑定 Google，下次可一键快速登录");
        Json.ok(resp, data);
    }

    // ---- 解绑 Google ----
    private void unbindGoogle(HttpServletResponse resp, User u) throws IOException, SQLException {
        boolean hasPassword = u.getPasswordHash() != null && !u.getPasswordHash().isBlank();
        if (!hasPassword) {
            Json.fail(resp, 422, "请先设置登录密码，再解绑 Google，以免无法登录");
            return;
        }
        userDao.unbindGoogle(u.getId());
        User fresh = userDao.findById(u.getId());
        Map<String, Object> data = profileData(fresh);
        data.put("message", "已解绑 Google");
        Json.ok(resp, data);
    }

    // ---- 辅助 ----
    private Map<String, Object> profileData(User u) {
        Map<String, Object> data = Json.map();
        Map<String, Object> user = Json.map();
        user.put("email", u.getEmail());
        String name = (u.getDisplayName() != null && !u.getDisplayName().isBlank())
                ? u.getDisplayName() : u.getEmail();
        user.put("name", name);
        user.put("provider", u.getProvider());
        user.put("picture", u.getPicture() == null ? "" : u.getPicture());
        user.put("googleBound", u.getGoogleSub() != null && !u.getGoogleSub().isBlank());
        user.put("hasPassword", u.getPasswordHash() != null && !u.getPasswordHash().isBlank());
        data.put("user", user);
        return data;
    }

    private User currentUser(HttpServletRequest req) throws SQLException {
        Integer userId = AuthSupport.userIdFromRequest(req);
        return userId == null ? null : userDao.findById(userId);
    }

    private JsonNode decodeJwtPayload(String jwt) {
        try {
            String[] parts = jwt.split("\\.");
            if (parts.length < 2) {
                return null;
            }
            byte[] json = Base64.getUrlDecoder().decode(parts[1]);
            return Json.MAPPER.readTree(json);
        } catch (Exception e) {
            return null;
        }
    }
}
