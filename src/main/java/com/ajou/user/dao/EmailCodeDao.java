package com.ajou.user.dao;

import com.ajou.common.db.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * 邮箱验证码数据访问。验证码按场景（register/login/reset）隔离，互不通用。
 */
public class EmailCodeDao {

    /** 写入验证码，10 分钟有效。 */
    public void insert(String email, String code, String scene) throws SQLException {
        String sql = "INSERT INTO email_codes (email, code, scene, expires_at) "
                + "VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 10 MINUTE))";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, code);
            ps.setString(3, scene);
            ps.executeUpdate();
        }
    }

    /** 校验并消费验证码：匹配场景、未用、未过期则置 used 并返回 true。 */
    public boolean consume(String email, String code, String scene) throws SQLException {
        String sql = "UPDATE email_codes SET used = 1 "
                + "WHERE email = ? AND code = ? AND scene = ? AND used = 0 AND expires_at > NOW() "
                + "ORDER BY id DESC LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, code);
            ps.setString(3, scene);
            return ps.executeUpdate() > 0;
        }
    }

    /**
     * 指定邮箱+场景下，最近 seconds 秒内是否已发送过验证码（频率限制，防刷与防邮箱被风控）。
     */
    public boolean sentWithin(String email, String scene, int seconds) throws SQLException {
        String sql = "SELECT 1 FROM email_codes "
                + "WHERE email = ? AND scene = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? SECOND) "
                + "LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, scene);
            ps.setInt(3, seconds);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
}
