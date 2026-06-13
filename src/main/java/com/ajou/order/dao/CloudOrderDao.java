package com.ajou.order.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.order.model.CloudOrder;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 云实例订单数据访问对象，服务于订单管理与云实例管理两个视角，并为仪表盘提供统计。
 */
public class CloudOrderDao {

    private static final String COLUMNS =
            "id, order_no, user_id, user_email, instance_code, instance_name, region, os, disk, "
            + "public_ip, billing, amount, status, created_at, paid_at, expire_at";

    /** 订单视角：按状态筛选 + 订单号/邮箱搜索。 */
    public List<CloudOrder> search(String status, String keyword) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT " + COLUMNS + " FROM cloud_orders WHERE 1=1");
        List<Object> params = new ArrayList<>();
        if (status != null && !status.isBlank()) {
            sql.append(" AND status = ?");
            params.add(status);
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (order_no LIKE ? OR user_email LIKE ?)");
            String like = "%" + keyword.trim() + "%";
            params.add(like);
            params.add(like);
        }
        sql.append(" ORDER BY created_at DESC, id DESC");
        return query(sql.toString(), params);
    }

    /** 云实例视角：已开通的实例（运行中 + 已到期），按到期时间升序。 */
    public List<CloudOrder> findInstances() throws SQLException {
        return findInstances(null, null, null);
    }

    /**
     * 云实例视角（带筛选）：在「运行中 + 已到期」范围内按规格 / 用户邮箱 / 状态过滤。
     * instanceCode 为空不限规格；keyword 为空不限用户；status 仅接受 running/expired，其余视为不限。
     */
    public List<CloudOrder> findInstances(String instanceCode, String keyword, String status) throws SQLException {
        StringBuilder sql = new StringBuilder("SELECT " + COLUMNS
                + " FROM cloud_orders WHERE status IN ('running','expired')");
        List<Object> params = new ArrayList<>();
        if (instanceCode != null && !instanceCode.isBlank()) {
            sql.append(" AND instance_code = ?");
            params.add(instanceCode.trim());
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (user_email LIKE ? OR instance_name LIKE ? OR order_no LIKE ?)");
            String like = "%" + keyword.trim() + "%";
            params.add(like);
            params.add(like);
            params.add(like);
        }
        if ("running".equals(status) || "expired".equals(status)) {
            sql.append(" AND status = ?");
            params.add(status);
        }
        sql.append(" ORDER BY expire_at ASC, id ASC");
        return query(sql.toString(), params);
    }

    /** 按用户查其全部订单/实例（前台「我的服务」），按下单时间倒序。 */
    public List<CloudOrder> findByUserId(int userId) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM cloud_orders WHERE user_id = ? ORDER BY created_at DESC, id DESC";
        List<Object> params = new ArrayList<>();
        params.add(userId);
        return query(sql, params);
    }

    /** 前台下单：插入一条订单/实例，返回自增 id。 */
    public int insert(CloudOrder o) throws SQLException {
        String sql = "INSERT INTO cloud_orders "
                + "(order_no, user_id, user_email, instance_code, instance_name, region, os, disk, "
                + "public_ip, billing, amount, status, paid_at, expire_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, java.sql.Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, o.getOrderNo());
            if (o.getUserId() == null) {
                ps.setNull(2, java.sql.Types.INTEGER);
            } else {
                ps.setInt(2, o.getUserId());
            }
            ps.setString(3, o.getUserEmail());
            ps.setString(4, o.getInstanceCode());
            ps.setString(5, o.getInstanceName());
            ps.setString(6, o.getRegion());
            ps.setString(7, o.getOs());
            ps.setString(8, o.getDisk());
            ps.setString(9, o.getPublicIp());
            ps.setString(10, o.getBilling());
            ps.setBigDecimal(11, o.getAmount());
            ps.setString(12, o.getStatus());
            ps.setTimestamp(13, o.getPaidAt());
            ps.setDate(14, o.getExpireAt());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                return keys.next() ? keys.getInt(1) : 0;
            }
        }
    }

    /** 订单号是否已存在（去重）。 */
    public boolean existsByOrderNo(String orderNo) throws SQLException {
        String sql = "SELECT 1 FROM cloud_orders WHERE order_no = ? LIMIT 1";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, orderNo);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public CloudOrder findById(int id) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM cloud_orders WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public void updateStatus(int id, String status) throws SQLException {
        String sql = "UPDATE cloud_orders SET status = ? WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    /** 标记开通：pending → running，写支付时间，到期时间设为当前 +1 个月。 */
    public void markPaid(int id) throws SQLException {
        String sql = "UPDATE cloud_orders SET status = 'running', paid_at = NOW(), "
                + "expire_at = DATE_ADD(CURDATE(), INTERVAL 1 MONTH) WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /** 续费：到期时间延长指定月数，若已到期则置为运行中。 */
    public void renew(int id, int months) throws SQLException {
        String sql = "UPDATE cloud_orders SET "
                + "expire_at = DATE_ADD(GREATEST(COALESCE(expire_at, CURDATE()), CURDATE()), INTERVAL ? MONTH), "
                + "status = 'running' WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, months);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    public void delete(int id) throws SQLException {
        String sql = "DELETE FROM cloud_orders WHERE id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }

    /**
     * 批量删除某用户名下的订单/实例（后台用户详情页批量删除）。
     * 限定 user_id，避免越权删到其他用户的数据。返回实际删除条数。
     */
    public int deleteByIdsAndUser(List<Integer> ids, int userId) throws SQLException {
        if (ids == null || ids.isEmpty()) {
            return 0;
        }
        String placeholders = String.join(",", java.util.Collections.nCopies(ids.size(), "?"));
        String sql = "DELETE FROM cloud_orders WHERE user_id = ? AND id IN (" + placeholders + ")";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            for (int i = 0; i < ids.size(); i++) {
                ps.setInt(i + 2, ids.get(i));
            }
            return ps.executeUpdate();
        }
    }

    // ---- 仪表盘统计 ----

    /** 订单总数。 */
    public long count() throws SQLException {
        return scalarLong("SELECT COUNT(*) FROM cloud_orders");
    }

    /** 运行中实例数。 */
    public long countRunning() throws SQLException {
        return scalarLong("SELECT COUNT(*) FROM cloud_orders WHERE status = 'running'");
    }

    /** 未来 days 天内即将到期的运行中实例数。 */
    public long countExpiringSoon(int days) throws SQLException {
        String sql = "SELECT COUNT(*) FROM cloud_orders WHERE status = 'running' "
                + "AND expire_at IS NOT NULL AND expire_at BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL ? DAY)";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, days);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong(1) : 0L;
            }
        }
    }

    /** 本月营收：本月已支付（非 pending）订单金额之和。 */
    public BigDecimal sumRevenueThisMonth() throws SQLException {
        String sql = "SELECT COALESCE(SUM(amount), 0) FROM cloud_orders "
                + "WHERE status <> 'pending' AND paid_at >= DATE_FORMAT(CURDATE(), '%Y-%m-01')";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
        }
    }

    // ---- 辅助 ----

    private List<CloudOrder> query(String sql, List<Object> params) throws SQLException {
        List<CloudOrder> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
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

    private long scalarLong(String sql) throws SQLException {
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    private CloudOrder mapRow(ResultSet rs) throws SQLException {
        CloudOrder o = new CloudOrder();
        o.setId(rs.getInt("id"));
        o.setOrderNo(rs.getString("order_no"));
        int uid = rs.getInt("user_id");
        o.setUserId(rs.wasNull() ? null : uid);
        o.setUserEmail(rs.getString("user_email"));
        o.setInstanceCode(rs.getString("instance_code"));
        o.setInstanceName(rs.getString("instance_name"));
        o.setRegion(rs.getString("region"));
        o.setOs(rs.getString("os"));
        o.setDisk(rs.getString("disk"));
        o.setPublicIp(rs.getString("public_ip"));
        o.setBilling(rs.getString("billing"));
        o.setAmount(rs.getBigDecimal("amount"));
        o.setStatus(rs.getString("status"));
        o.setCreatedAt(rs.getTimestamp("created_at"));
        o.setPaidAt(rs.getTimestamp("paid_at"));
        o.setExpireAt(rs.getDate("expire_at"));
        return o;
    }
}
