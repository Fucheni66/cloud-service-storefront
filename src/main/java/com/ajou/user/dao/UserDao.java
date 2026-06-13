package com.ajou.user.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.user.model.User;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 用户数据访问对象。列表支持按 provider 筛选 + 关键字（邮箱/显示名）搜索。
 */
public class UserDao {

    private static final String COLUMNS =
            "id, ext_id, provider, email, display_name, picture, google_sub, "
            + "email_verified, login_count, password_hash, status, created_at, last_login_at";

    /** 按邮箱查询（含密码哈希），不存在返回 null。 */
    public User findByEmail(String email) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM users WHERE email = ? ORDER BY id LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 按 Google sub 查询，不存在返回 null。 */
    public User findByGoogleSub(String sub) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM users WHERE google_sub = ? LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, sub);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 前台注册/首次 Google 登录：插入用户，返回自增 id。 */
    public int insertCustomer(User u) throws SQLException {
        String sql = "INSERT INTO users (ext_id, provider, email, display_name, picture, google_sub, "
                + "email_verified, login_count, password_hash, status, last_login_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', NOW())";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, u.getExtId());
            ps.setString(2, u.getProvider());
            ps.setString(3, u.getEmail());
            ps.setString(4, u.getDisplayName());
            ps.setString(5, u.getPicture());
            ps.setString(6, u.getGoogleSub());
            ps.setInt(7, u.isEmailVerified() ? 1 : 0);
            ps.setInt(8, u.getLoginCount());
            ps.setString(9, u.getPasswordHash());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    /** 登录时更新最近登录时间与累计登录次数。 */
    public void touchLogin(int id) throws SQLException {
        String sql = "UPDATE users SET last_login_at = NOW(), login_count = login_count + 1 WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 同步 Google 用户最新资料。 */
    public void updateGoogleProfile(int id, String displayName, String picture) throws SQLException {
        String sql = "UPDATE users SET display_name = ?, picture = ?, last_login_at = NOW(), "
                + "login_count = login_count + 1 WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, displayName);
            ps.setString(2, picture);
            ps.setInt(3, id);
            ps.executeUpdate();
        }
    }

    /**
     * 条件查询。provider 为空表示全部；keyword 为空表示不限。
     */
    public List<User> search(String provider, String keyword) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT " + COLUMNS + " FROM users WHERE 1=1");
        List<Object> params = new ArrayList<>();
        if (provider != null && !provider.isBlank()) {
            sql.append(" AND provider = ?");
            params.add(provider);
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (email LIKE ? OR display_name LIKE ?)");
            String like = "%" + keyword.trim() + "%";
            params.add(like);
            params.add(like);
        }
        sql.append(" ORDER BY created_at DESC, id DESC");

        List<User> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public User findById(int id) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM users WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 启用 / 禁用。 */
    public void updateStatus(int id, String status) throws SQLException {
        String sql = "UPDATE users SET status = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM users WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 个人中心：更新密码哈希（找回密码 / 修改密码复用）。 */
    public void updatePassword(int id, String passwordHash) throws SQLException {
        String sql = "UPDATE users SET password_hash = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, passwordHash);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    /** 个人中心：将 Google 账号绑定到当前用户（写入 google_sub，可选同步头像）。 */
    public void bindGoogle(int id, String googleSub, String picture) throws SQLException {
        String sql = "UPDATE users SET google_sub = ?, "
                + "picture = COALESCE(NULLIF(picture, ''), ?) WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, googleSub);
            ps.setString(2, picture);
            ps.setInt(3, id);
            ps.executeUpdate();
        }
    }

    /** 个人中心：解除当前用户的 Google 绑定。 */
    public void unbindGoogle(int id) throws SQLException {
        String sql = "UPDATE users SET google_sub = NULL WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 用户总数（仪表盘用）。 */
    public long count() throws SQLException {
        String sql = "SELECT COUNT(*) FROM users";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    private User mapRow(ResultSet rs) throws SQLException {
        User u = new User();
        u.setId(rs.getInt("id"));
        u.setExtId(rs.getString("ext_id"));
        u.setProvider(rs.getString("provider"));
        u.setEmail(rs.getString("email"));
        u.setDisplayName(rs.getString("display_name"));
        u.setPicture(rs.getString("picture"));
        u.setGoogleSub(rs.getString("google_sub"));
        u.setEmailVerified(rs.getInt("email_verified") == 1);
        u.setLoginCount(rs.getInt("login_count"));
        u.setPasswordHash(rs.getString("password_hash"));
        u.setStatus(rs.getString("status"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        u.setLastLoginAt(rs.getTimestamp("last_login_at"));
        return u;
    }
}
