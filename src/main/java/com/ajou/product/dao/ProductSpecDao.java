package com.ajou.product.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.product.model.ProductSpec;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * 云产品规格数据访问对象。全部使用 PreparedStatement，连接由 try-with-resources 关闭。
 */
public class ProductSpecDao {

    private static final String COLUMNS =
            "id, instance_code, title, description, category, vcpu, memory_gb, "
            + "feature_spec, gpu_info, price_monthly, unit, badge_text, is_active, "
            + "sort_order, home_weight, created_at, updated_at";

    /** 全部规格，按排序权重升序。 */
    public List<ProductSpec> findAll() throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM product_specs ORDER BY sort_order ASC, id ASC";
        List<ProductSpec> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    /**
     * 首页「热门产品」：在售且 home_weight > 0，按权重降序、排序权重升序，取前 limit 条。
     */
    public List<ProductSpec> findHomeHot(int limit) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM product_specs "
                + "WHERE is_active = 1 AND home_weight > 0 "
                + "ORDER BY home_weight DESC, sort_order ASC, id ASC LIMIT ?";
        List<ProductSpec> list = new ArrayList<>();
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

    /** 按主键查询，不存在返回 null。 */
    public ProductSpec findById(int id) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM product_specs WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    /** 规格标识是否已存在（编辑时用 excludeId 排除自身，新增传 0）。 */
    public boolean existsByCode(String instanceCode, int excludeId) throws SQLException {
        String sql = "SELECT 1 FROM product_specs WHERE instance_code = ? AND id <> ? LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, instanceCode);
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** 新增，返回自增主键。 */
    public int insert(ProductSpec p) throws SQLException {
        String sql = "INSERT INTO product_specs "
                + "(instance_code, title, description, category, vcpu, memory_gb, feature_spec, "
                + "gpu_info, price_monthly, unit, badge_text, is_active, sort_order, home_weight) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
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
    public void update(ProductSpec p) throws SQLException {
        String sql = "UPDATE product_specs SET "
                + "instance_code = ?, title = ?, description = ?, category = ?, vcpu = ?, "
                + "memory_gb = ?, feature_spec = ?, gpu_info = ?, price_monthly = ?, unit = ?, "
                + "badge_text = ?, is_active = ?, sort_order = ?, home_weight = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindCommon(ps, p);
            ps.setInt(15, p.getId());
            ps.executeUpdate();
        }
    }

    /** 单独更新首页热门权重（首页配置页批量调权重用）。 */
    public void updateHomeWeight(int id, int weight) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE product_specs SET home_weight = ? WHERE id = ?")) {
            ps.setInt(1, weight);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    /** 删除。 */
    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM product_specs WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 上架/下架切换。 */
    public void setActive(int id, boolean active) throws SQLException {
        String sql = "UPDATE product_specs SET is_active = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, active ? 1 : 0);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    /** 规格总数。 */
    public long count() throws SQLException {
        String sql = "SELECT COUNT(*) FROM product_specs";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    /** 绑定除主键外的公共字段（insert/update 复用，占位序号 1-13）。 */
    private void bindCommon(PreparedStatement ps, ProductSpec p) throws SQLException {
        ps.setString(1, p.getInstanceCode());
        ps.setString(2, p.getTitle());
        ps.setString(3, p.getDescription());
        ps.setString(4, p.getCategory());
        ps.setInt(5, p.getVcpu());
        ps.setInt(6, p.getMemoryGb());
        ps.setString(7, p.getFeatureSpec());
        ps.setString(8, p.getGpuInfo());
        ps.setBigDecimal(9, p.getPriceMonthly());
        ps.setString(10, p.getUnit());
        ps.setString(11, p.getBadgeText());
        ps.setInt(12, p.isActive() ? 1 : 0);
        ps.setInt(13, p.getSortOrder());
        ps.setInt(14, p.getHomeWeight());
    }

    private ProductSpec mapRow(ResultSet rs) throws SQLException {
        ProductSpec p = new ProductSpec();
        p.setId(rs.getInt("id"));
        p.setInstanceCode(rs.getString("instance_code"));
        p.setTitle(rs.getString("title"));
        p.setDescription(rs.getString("description"));
        p.setCategory(rs.getString("category"));
        p.setVcpu(rs.getInt("vcpu"));
        p.setMemoryGb(rs.getInt("memory_gb"));
        p.setFeatureSpec(rs.getString("feature_spec"));
        p.setGpuInfo(rs.getString("gpu_info"));
        p.setPriceMonthly(rs.getBigDecimal("price_monthly"));
        p.setUnit(rs.getString("unit"));
        p.setBadgeText(rs.getString("badge_text"));
        p.setActive(rs.getInt("is_active") == 1);
        p.setSortOrder(rs.getInt("sort_order"));
        p.setHomeWeight(rs.getInt("home_weight"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        p.setUpdatedAt(rs.getTimestamp("updated_at"));
        return p;
    }
}
