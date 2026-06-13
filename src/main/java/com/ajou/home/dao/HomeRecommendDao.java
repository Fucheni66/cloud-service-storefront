package com.ajou.home.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.home.model.HomeRecommend;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * 首页热门产品推荐卡片数据访问对象。全部使用 PreparedStatement，连接由 try-with-resources 关闭。
 */
public class HomeRecommendDao {

    private static final String COLUMNS =
            "id, tab, title, description, icon, spec_text, price, unit, instance_code, "
            + "is_active, sort_order, created_at, updated_at";

    /** 全部卡片（后台），按标签、排序、id 升序。 */
    public List<HomeRecommend> findAll() throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM home_recommends "
                + "ORDER BY FIELD(tab,'basic','business','gpu'), sort_order ASC, id ASC";
        return query(sql);
    }

    /** 后台列表筛选：tab 为空返回全部，否则按标签过滤（含未展示），按排序、id 升序。 */
    public List<HomeRecommend> findForAdmin(String tab) throws SQLException {
        if (tab == null || tab.isBlank()) {
            return findAll();
        }
        String sql = "SELECT " + COLUMNS + " FROM home_recommends "
                + "WHERE tab = ? ORDER BY sort_order ASC, id ASC";
        List<HomeRecommend> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tab.trim());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /** 某标签下的启用卡片（前台），按排序升序。 */
    public List<HomeRecommend> findActiveByTab(String tab) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM home_recommends "
                + "WHERE is_active = 1 AND tab = ? ORDER BY sort_order ASC, id ASC";
        List<HomeRecommend> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tab);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /** 按主键查询，不存在返回 null。 */
    public HomeRecommend findById(int id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT " + COLUMNS + " FROM home_recommends WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 新增，返回自增主键。 */
    public int insert(HomeRecommend r) throws SQLException {
        String sql = "INSERT INTO home_recommends "
                + "(tab, title, description, icon, spec_text, price, unit, instance_code, is_active, sort_order) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            bindCommon(ps, r);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    /** 更新。 */
    public void update(HomeRecommend r) throws SQLException {
        String sql = "UPDATE home_recommends SET "
                + "tab = ?, title = ?, description = ?, icon = ?, spec_text = ?, price = ?, unit = ?, "
                + "instance_code = ?, is_active = ?, sort_order = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindCommon(ps, r);
            ps.setInt(11, r.getId());
            ps.executeUpdate();
        }
    }

    /** 删除。 */
    public void delete(int id) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM home_recommends WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 启用/停用切换。 */
    public void setActive(int id, boolean active) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE home_recommends SET is_active = ? WHERE id = ?")) {
            ps.setInt(1, active ? 1 : 0);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    private List<HomeRecommend> query(String sql) throws SQLException {
        List<HomeRecommend> list = new ArrayList<>();
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
    private void bindCommon(PreparedStatement ps, HomeRecommend r) throws SQLException {
        ps.setString(1, r.getTab());
        ps.setString(2, r.getTitle());
        ps.setString(3, r.getDescription());
        ps.setString(4, r.getIcon());
        ps.setString(5, r.getSpecText());
        ps.setString(6, r.getPrice());
        ps.setString(7, r.getUnit());
        ps.setString(8, r.getInstanceCode());
        ps.setInt(9, r.isActive() ? 1 : 0);
        ps.setInt(10, r.getSortOrder());
    }

    private HomeRecommend mapRow(ResultSet rs) throws SQLException {
        HomeRecommend r = new HomeRecommend();
        r.setId(rs.getInt("id"));
        r.setTab(rs.getString("tab"));
        r.setTitle(rs.getString("title"));
        r.setDescription(rs.getString("description"));
        r.setIcon(rs.getString("icon"));
        r.setSpecText(rs.getString("spec_text"));
        r.setPrice(rs.getString("price"));
        r.setUnit(rs.getString("unit"));
        r.setInstanceCode(rs.getString("instance_code"));
        r.setActive(rs.getInt("is_active") == 1);
        r.setSortOrder(rs.getInt("sort_order"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        r.setUpdatedAt(rs.getTimestamp("updated_at"));
        return r;
    }
}
