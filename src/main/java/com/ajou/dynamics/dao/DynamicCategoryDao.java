package com.ajou.dynamics.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.dynamics.model.DynamicCategory;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * 产品动态分类数据访问对象。
 */
public class DynamicCategoryDao {

    /** 列表带上该分类下的文章数 post_count（按 code 关联 dynamic_posts.category）。 */
    private static final String SELECT =
            "SELECT c.id, c.code, c.name, c.color, c.sort_order, c.is_active, c.created_at, c.updated_at, "
            + "(SELECT COUNT(*) FROM dynamic_posts p WHERE p.category = c.code) AS post_count "
            + "FROM dynamic_categories c";

    /** 全部分类（后台），按排序权重升序。 */
    public List<DynamicCategory> findAll() throws SQLException {
        return query(SELECT + " ORDER BY c.sort_order ASC, c.id ASC");
    }

    /** 启用中的分类（发布表单 / 前台导航）。 */
    public List<DynamicCategory> findActive() throws SQLException {
        return query(SELECT + " WHERE c.is_active = 1 ORDER BY c.sort_order ASC, c.id ASC");
    }

    public DynamicCategory findById(int id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(SELECT + " WHERE c.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** code 是否已存在（编辑时用 excludeId 排除自身，新增传 0）。 */
    public boolean existsByCode(String code, int excludeId) throws SQLException {
        String sql = "SELECT 1 FROM dynamic_categories WHERE code = ? AND id <> ? LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code);
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public int insert(DynamicCategory c) throws SQLException {
        String sql = "INSERT INTO dynamic_categories (code, name, color, sort_order, is_active) "
                + "VALUES (?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindCommon(ps, c);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    /**
     * 更新。若 code 改变，同步更新引用该分类的文章 dynamic_posts.category（保持外键一致）。
     */
    public void update(DynamicCategory c, String oldCode) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            String sql = "UPDATE dynamic_categories SET code = ?, name = ?, color = ?, "
                    + "sort_order = ?, is_active = ? WHERE id = ?";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                bindCommon(ps, c);
                ps.setInt(6, c.getId());
                ps.executeUpdate();
            }
            if (oldCode != null && !oldCode.equals(c.getCode())) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE dynamic_posts SET category = ? WHERE category = ?")) {
                    ps.setString(1, c.getCode());
                    ps.setString(2, oldCode);
                    ps.executeUpdate();
                }
            }
        }
    }

    public void delete(int id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM dynamic_categories WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    public void setActive(int id, boolean active) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE dynamic_categories SET is_active = ? WHERE id = ?")) {
            ps.setInt(1, active ? 1 : 0);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    /** 该分类下文章数（删除前校验）。 */
    public int countPosts(String code) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM dynamic_posts WHERE category = ?")) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    private List<DynamicCategory> query(String sql) throws SQLException {
        List<DynamicCategory> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    private void bindCommon(PreparedStatement ps, DynamicCategory c) throws SQLException {
        ps.setString(1, c.getCode());
        ps.setString(2, c.getName());
        ps.setString(3, c.getColor());
        ps.setInt(4, c.getSortOrder());
        ps.setInt(5, c.isActive() ? 1 : 0);
    }

    private DynamicCategory mapRow(ResultSet rs) throws SQLException {
        DynamicCategory c = new DynamicCategory();
        c.setId(rs.getInt("id"));
        c.setCode(rs.getString("code"));
        c.setName(rs.getString("name"));
        c.setColor(rs.getString("color"));
        c.setSortOrder(rs.getInt("sort_order"));
        c.setActive(rs.getInt("is_active") == 1);
        c.setCreatedAt(rs.getTimestamp("created_at"));
        c.setUpdatedAt(rs.getTimestamp("updated_at"));
        c.setPostCount(rs.getInt("post_count"));
        return c;
    }
}
