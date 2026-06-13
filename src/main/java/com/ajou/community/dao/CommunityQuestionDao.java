package com.ajou.community.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.community.model.CommunityQuestion;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * 社区问答数据访问对象。回复数通过关联子查询读取，避免冗余字段不一致。
 */
public class CommunityQuestionDao {

    /** 列查询统一带上已发布回复数 reply_count。 */
    private static final String SELECT =
            "SELECT q.id, q.slug, q.tag, q.category, q.type, q.title, q.summary, q.content, "
            + "q.recommendation, q.contact, q.author_name, q.status, q.created_at, q.updated_at, "
            + "(SELECT COUNT(*) FROM community_replies r WHERE r.question_id = q.id "
            + " AND r.status = 'published') AS reply_count "
            + "FROM community_questions q";

    /** 全部问题（后台用），按创建时间倒序。 */
    public List<CommunityQuestion> findAll() throws SQLException {
        String sql = SELECT + " ORDER BY q.created_at DESC, q.id DESC";
        return query(sql);
    }

    /** 按状态过滤（后台用），status 为空时返回全部。 */
    public List<CommunityQuestion> findByStatus(String status) throws SQLException {
        if (status == null || status.isBlank()) {
            return findAll();
        }
        String sql = SELECT + " WHERE q.status = ? ORDER BY q.created_at DESC, q.id DESC";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                List<CommunityQuestion> list = new ArrayList<>();
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
                return list;
            }
        }
    }

    /** 已发布问题（前台列表）。 */
    public List<CommunityQuestion> findPublished() throws SQLException {
        String sql = SELECT + " WHERE q.status = 'published' ORDER BY q.created_at DESC, q.id DESC";
        return query(sql);
    }

    /** 按主键查询，不存在返回 null。 */
    public CommunityQuestion findById(int id) throws SQLException {
        String sql = SELECT + " WHERE q.id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 按 slug 查询，不存在返回 null。 */
    public CommunityQuestion findBySlug(String slug) throws SQLException {
        String sql = SELECT + " WHERE q.slug = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, slug);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** slug 是否已存在（编辑时用 excludeId 排除自身，新增传 0）。 */
    public boolean existsBySlug(String slug, int excludeId) throws SQLException {
        String sql = "SELECT 1 FROM community_questions WHERE slug = ? AND id <> ? LIMIT 1";
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
    public int insert(CommunityQuestion q) throws SQLException {
        String sql = "INSERT INTO community_questions "
                + "(slug, tag, category, type, title, summary, content, recommendation, "
                + "contact, author_name, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindCommon(ps, q);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    /** 更新。 */
    public void update(CommunityQuestion q) throws SQLException {
        String sql = "UPDATE community_questions SET "
                + "slug = ?, tag = ?, category = ?, type = ?, title = ?, summary = ?, content = ?, "
                + "recommendation = ?, contact = ?, author_name = ?, status = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindCommon(ps, q);
            ps.setInt(12, q.getId());
            ps.executeUpdate();
        }
    }

    /** 删除（回复由数据库外键无约束，需调用方先删回复或保留为孤儿；此处一并删除回复）。 */
    public void delete(int id) throws SQLException {
        try (Connection conn = DbUtil.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM community_replies WHERE question_id = ?")) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM community_questions WHERE id = ?")) {
                ps.setInt(1, id);
                ps.executeUpdate();
            }
        }
    }

    /** 仅更新状态（审核发布/关闭）。 */
    public void setStatus(int id, String status) throws SQLException {
        String sql = "UPDATE community_questions SET status = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    /** 问题总数。 */
    public long count() throws SQLException {
        String sql = "SELECT COUNT(*) FROM community_questions";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    /** 待审核问题数（后台角标）。 */
    public long countPending() throws SQLException {
        String sql = "SELECT COUNT(*) FROM community_questions WHERE status = 'pending'";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    private List<CommunityQuestion> query(String sql) throws SQLException {
        List<CommunityQuestion> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /** 绑定除主键外的公共字段（insert/update 复用，占位序号 1-11）。 */
    private void bindCommon(PreparedStatement ps, CommunityQuestion q) throws SQLException {
        ps.setString(1, q.getSlug());
        ps.setString(2, q.getTag());
        ps.setString(3, q.getCategory());
        ps.setString(4, q.getType());
        ps.setString(5, q.getTitle());
        ps.setString(6, q.getSummary());
        ps.setString(7, q.getContent());
        ps.setString(8, q.getRecommendation());
        ps.setString(9, q.getContact());
        ps.setString(10, q.getAuthorName());
        ps.setString(11, q.getStatus());
    }

    private CommunityQuestion mapRow(ResultSet rs) throws SQLException {
        CommunityQuestion q = new CommunityQuestion();
        q.setId(rs.getInt("id"));
        q.setSlug(rs.getString("slug"));
        q.setTag(rs.getString("tag"));
        q.setCategory(rs.getString("category"));
        q.setType(rs.getString("type"));
        q.setTitle(rs.getString("title"));
        q.setSummary(rs.getString("summary"));
        q.setContent(rs.getString("content"));
        q.setRecommendation(rs.getString("recommendation"));
        q.setContact(rs.getString("contact"));
        q.setAuthorName(rs.getString("author_name"));
        q.setStatus(rs.getString("status"));
        q.setCreatedAt(rs.getTimestamp("created_at"));
        q.setUpdatedAt(rs.getTimestamp("updated_at"));
        q.setReplyCount(rs.getInt("reply_count"));
        return q;
    }
}
