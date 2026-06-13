package com.ajou.user.dao;

import com.ajou.common.db.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * 前台登录 token 数据访问。
 */
public class AuthTokenDao {

    /** 保存一个 token → user 的映射。 */
    public void insert(String token, int userId) throws SQLException {
        String sql = "INSERT INTO auth_tokens (token, user_id) VALUES (?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, token);
            ps.setInt(2, userId);
            ps.executeUpdate();
        }
    }

    /** 按 token 查 user_id，不存在返回 null。 */
    public Integer findUserId(String token) throws SQLException {
        if (token == null || token.isBlank()) {
            return null;
        }
        String sql = "SELECT user_id FROM auth_tokens WHERE token = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, token);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
        }
    }
}
