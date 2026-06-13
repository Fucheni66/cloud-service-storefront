package com.ajou.community.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.community.model.CommunityReply;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * 社区回复数据访问对象。
 */
public class CommunityReplyDao {

    private static final String COLUMNS =
            "id, question_id, author_name, is_official, content, like_count, status, created_at";

    /** 某问题下的已发布回复，按时间正序。 */
    public List<CommunityReply> findPublishedByQuestion(int questionId) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM community_replies "
                + "WHERE question_id = ? AND status = 'published' ORDER BY created_at ASC, id ASC";
        return queryByQuestion(sql, questionId);
    }

    /** 某问题下的全部回复（后台用），按时间正序。 */
    public List<CommunityReply> findAllByQuestion(int questionId) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM community_replies "
                + "WHERE question_id = ? ORDER BY created_at ASC, id ASC";
        return queryByQuestion(sql, questionId);
    }

    /** 新增回复，返回自增主键。 */
    public int insert(CommunityReply r) throws SQLException {
        String sql = "INSERT INTO community_replies "
                + "(question_id, author_name, is_official, content, like_count, status) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, r.getQuestionId());
            ps.setString(2, r.getAuthorName());
            ps.setInt(3, r.isOfficial() ? 1 : 0);
            ps.setString(4, r.getContent());
            ps.setInt(5, r.getLikeCount());
            ps.setString(6, r.getStatus() == null ? "published" : r.getStatus());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    /** 删除回复。 */
    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM community_replies WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    private List<CommunityReply> queryByQuestion(String sql, int questionId) throws SQLException {
        List<CommunityReply> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, questionId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    private CommunityReply mapRow(ResultSet rs) throws SQLException {
        CommunityReply r = new CommunityReply();
        r.setId(rs.getInt("id"));
        r.setQuestionId(rs.getInt("question_id"));
        r.setAuthorName(rs.getString("author_name"));
        r.setOfficial(rs.getInt("is_official") == 1);
        r.setContent(rs.getString("content"));
        r.setLikeCount(rs.getInt("like_count"));
        r.setStatus(rs.getString("status"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        return r;
    }
}
