package com.ajou.api;

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
import java.util.UUID;

/**
 * Google 登录（前台路径兼容 PHP /google_login.php）。
 *
 * <p>演示环境：解析 Google ID Token(JWT) 的 payload 取得 sub/email/name/picture 并落库，
 * 不做签名校验。生产环境应调用 Google tokeninfo 校验 aud/iss/exp/签名。</p>
 */
@WebServlet("/google_login.php")
public class GoogleLoginServlet extends HttpServlet {

    private final UserDao userDao = new UserDao();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
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
        String email = payload.path("email").asText("");
        String name = payload.path("name").asText(email);
        String picture = payload.path("picture").asText("");
        if (sub.isEmpty() || email.isEmpty()) {
            Json.fail(resp, 422, "Google 凭证缺少必要信息");
            return;
        }
        try {
            User u = userDao.findByGoogleSub(sub);
            if (u == null) {
                u = new User();
                u.setExtId("google_user_" + UUID.randomUUID().toString().replace("-", ""));
                u.setProvider("google");
                u.setEmail(email);
                u.setDisplayName(name);
                u.setPicture(picture);
                u.setGoogleSub(sub);
                u.setEmailVerified(true);
                int id = userDao.insertCustomer(u);
                u.setId(id);
            } else {
                userDao.updateGoogleProfile(u.getId(), name, picture);
                u.setDisplayName(name);
                u.setPicture(picture);
            }
            String token = AuthSupport.issueToken(u.getId());
            AuthSupport.writeLogin(resp, u, token, "Google 登录成功");
        } catch (SQLException e) {
            Json.fail(resp, 500, "Google 登录失败，请稍后重试");
        }
    }

    /** 解析 JWT 的 payload 段（不验签）。 */
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
