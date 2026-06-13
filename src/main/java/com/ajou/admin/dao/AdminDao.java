package com.ajou.admin.dao;

import com.ajou.admin.model.Admin;
import com.ajou.common.db.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * 管理员数据访问对象。全部使用 PreparedStatement 防止 SQL 注入，
 * 连接由 try-with-resources 自动关闭。
 */
public class AdminDao {

    /** 按用户名查询管理员，不存在返回 null。 */
    public Admin findByUsername(String username) throws SQLException {
        String sql = "SELECT id, username, password_hash, display_name, role, created_at, last_login_at "
                + "FROM admins WHERE username = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 用户名是否已存在。 */
    public boolean existsByUsername(String username) throws SQLException {
        String sql = "SELECT 1 FROM admins WHERE username = ? LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** 插入新管理员，返回自增主键。 */
    public int insert(Admin admin) throws SQLException {
        String sql = "INSERT INTO admins (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, admin.getUsername());
            ps.setString(2, admin.getPasswordHash());
            ps.setString(3, admin.getDisplayName());
            ps.setString(4, admin.getRole() == null ? "admin" : admin.getRole());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    return keys.getInt(1);
                }
            }
            return 0;
        }
    }

    /** 更新最近登录时间为当前时间。 */
    public void updateLastLogin(int id) throws SQLException {
        String sql = "UPDATE admins SET last_login_at = NOW() WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 管理员总数。 */
    public long count() throws SQLException {
        String sql = "SELECT COUNT(*) FROM admins";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    /** 最近注册的管理员，按创建时间倒序。 */
    public List<Admin> findRecent(int limit) throws SQLException {
        String sql = "SELECT id, username, password_hash, display_name, role, created_at, last_login_at "
                + "FROM admins ORDER BY created_at DESC, id DESC LIMIT ?";
        List<Admin> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    private Admin mapRow(ResultSet rs) throws SQLException {
        Admin a = new Admin();
        a.setId(rs.getInt("id"));
        a.setUsername(rs.getString("username"));
        a.setPasswordHash(rs.getString("password_hash"));
        a.setDisplayName(rs.getString("display_name"));
        a.setRole(rs.getString("role"));
        a.setCreatedAt(rs.getTimestamp("created_at"));
        a.setLastLoginAt(rs.getTimestamp("last_login_at"));
        return a;
    }
}
