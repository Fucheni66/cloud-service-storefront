package com.ajou.dynamics.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.dynamics.model.DynamicPost;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * 产品动态文章数据访问对象。全部使用 PreparedStatement，连接由 try-with-resources 关闭。
 * 查询联表 dynamic_categories 以带出分类显示名与配色。
 */
public class DynamicPostDao {

    private static final String SELECT_BASE =
            "SELECT p.id, p.slug, p.category, p.title, p.summary, p.content, p.product_scope, "
            + "p.badge_text, p.is_published, p.sort_order, p.view_count, p.published_at, "
            + "p.created_at, p.updated_at, c.name AS category_name, c.color AS category_color "
            + "FROM dynamic_posts p LEFT JOIN dynamic_categories c ON c.code = p.category";

    private static final String ORDER = " ORDER BY p.sort_order ASC, p.published_at DESC, p.id DESC";

    /** 全部文章（后台）。 */
    public List<DynamicPost> findAll() throws SQLException {
        return query(SELECT_BASE + ORDER);
    }

    /**
     * 后台筛选：按分类标识 + 关键词（标题/标识/摘要）过滤。两者均可为空。
     */
    public List<DynamicPost> search(String category, String keyword) throws SQLException {
        List<Object> args = new ArrayList<>();
        String where = buildWhere(category, keyword, args);
        StringBuilder sql = new StringBuilder(SELECT_BASE).append(where).append(ORDER);

        List<DynamicPost> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < args.size(); i++) {
                ps.setObject(i + 1, args.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /**
     * 后台分页筛选：按分类 + 关键词过滤，limit/offset 分页。
     */
    public List<DynamicPost> searchPaged(String category, String keyword, int offset, int limit)
            throws SQLException {
        List<Object> args = new ArrayList<>();
        String where = buildWhere(category, keyword, args);

        StringBuilder sql = new StringBuilder(SELECT_BASE).append(where).append(ORDER)
                .append(" LIMIT ? OFFSET ?");
        args.add(limit);
        args.add(offset);

        List<DynamicPost> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < args.size(); i++) {
                ps.setObject(i + 1, args.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /** 后台筛选条件下的总条数（分页用）。 */
    public long countSearch(String category, String keyword) throws SQLException {
        List<Object> args = new ArrayList<>();
        String where = buildWhere(category, keyword, args);
        String sql = "SELECT COUNT(*) FROM dynamic_posts p" + where;
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < args.size(); i++) {
                ps.setObject(i + 1, args.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong(1) : 0L;
            }
        }
    }

    /** 拼装 search/分页/计数共用的 WHERE 子句，并把参数追加到 args。 */
    private String buildWhere(String category, String keyword, List<Object> args) {
        List<String> conds = new ArrayList<>();
        if (category != null && !category.isBlank()) {
            conds.add("p.category = ?");
            args.add(category.trim());
        }
        if (keyword != null && !keyword.isBlank()) {
            conds.add("(p.title LIKE ? OR p.slug LIKE ? OR p.summary LIKE ?)");
            String like = "%" + keyword.trim() + "%";
            args.add(like);
            args.add(like);
            args.add(like);
        }
        return conds.isEmpty() ? "" : " WHERE " + String.join(" AND ", conds);
    }

    /** 已发布文章（前台列表）。 */
    public List<DynamicPost> findPublished() throws SQLException {
        return query(SELECT_BASE + " WHERE p.is_published = 1" + ORDER);
    }

    /** 某分类下的已发布文章（前台精选教程等场景）。 */
    public List<DynamicPost> findPublishedByCategory(String code) throws SQLException {
        String sql = SELECT_BASE + " WHERE p.is_published = 1 AND p.category = ?" + ORDER;
        List<DynamicPost> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /** 按主键查询，不存在返回 null。 */
    public DynamicPost findById(int id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(SELECT_BASE + " WHERE p.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 按 slug 查询，不存在返回 null。 */
    public DynamicPost findBySlug(String slug) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(SELECT_BASE + " WHERE p.slug = ?")) {
            ps.setString(1, slug);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** slug 是否已存在（编辑时用 excludeId 排除自身，新增传 0）。 */
    public boolean existsBySlug(String slug, int excludeId) throws SQLException {
        String sql = "SELECT 1 FROM dynamic_posts WHERE slug = ? AND id <> ? LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, slug);
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** 新增，返回自增主键。 */
    public int insert(DynamicPost p) throws SQLException {
        String sql = "INSERT INTO dynamic_posts "
                + "(slug, category, title, summary, content, product_scope, badge_text, "
                + "is_published, sort_order, published_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindCommon(ps, p);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    /** 更新。 */
    public void update(DynamicPost p) throws SQLException {
        String sql = "UPDATE dynamic_posts SET "
                + "slug = ?, category = ?, title = ?, summary = ?, content = ?, product_scope = ?, "
                + "badge_text = ?, is_published = ?, sort_order = ?, published_at = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindCommon(ps, p);
            ps.setInt(11, p.getId());
            ps.executeUpdate();
        }
    }

    /** 删除。 */
    public void delete(int id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM dynamic_posts WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 发布/下线切换。 */
    public void setPublished(int id, boolean published) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE dynamic_posts SET is_published = ? WHERE id = ?")) {
            ps.setInt(1, published ? 1 : 0);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    /** 浏览次数 +1（详情页访问时调用，失败不影响主流程）。 */
    public void increaseView(int id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE dynamic_posts SET view_count = view_count + 1 WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 文章总数。 */
    public long count() throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM dynamic_posts");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    private List<DynamicPost> query(String sql) throws SQLException {
        List<DynamicPost> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /** 绑定除主键外的公共字段（insert/update 复用，占位序号 1-10）。 */
    private void bindCommon(PreparedStatement ps, DynamicPost p) throws SQLException {
        ps.setString(1, p.getSlug());
        ps.setString(2, p.getCategory());
        ps.setString(3, p.getTitle());
        ps.setString(4, p.getSummary());
        ps.setString(5, p.getContent());
        ps.setString(6, p.getProductScope());
        ps.setString(7, p.getBadgeText());
        ps.setInt(8, p.isPublished() ? 1 : 0);
        ps.setInt(9, p.getSortOrder());
        ps.setDate(10, p.getPublishedAt());
    }

    private DynamicPost mapRow(ResultSet rs) throws SQLException {
        DynamicPost p = new DynamicPost();
        p.setId(rs.getInt("id"));
        p.setSlug(rs.getString("slug"));
        p.setCategory(rs.getString("category"));
        p.setTitle(rs.getString("title"));
        p.setSummary(rs.getString("summary"));
        p.setContent(rs.getString("content"));
        p.setProductScope(rs.getString("product_scope"));
        p.setBadgeText(rs.getString("badge_text"));
        p.setPublished(rs.getInt("is_published") == 1);
        p.setSortOrder(rs.getInt("sort_order"));
        p.setViewCount(rs.getInt("view_count"));
        p.setPublishedAt(rs.getDate("published_at"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        p.setUpdatedAt(rs.getTimestamp("updated_at"));
        p.setCategoryName(rs.getString("category_name"));
        p.setCategoryColor(rs.getString("category_color"));
        return p;
    }
}
