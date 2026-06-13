package com.ajou.config.dao;

import com.ajou.common.db.DbUtil;
import com.ajou.config.model.AppConfig;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 系统配置数据访问对象。
 */
public class AppConfigDao {

    private static final String COLUMNS =
            "config_key, config_group, config_value, label, is_secret, sort_order, updated_at";

    /** 按分组取配置项，按排序升序。 */
    public List<AppConfig> findByGroup(String group) throws SQLException {
        String sql = "SELECT " + COLUMNS + " FROM app_configs WHERE config_group = ? ORDER BY sort_order ASC";
        List<AppConfig> list = new ArrayList<>();
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, group);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    /** 取单个配置值，不存在返回 null（供前台 API 读取配置使用）。 */
    public String getValue(String key) throws SQLException {
        String sql = "SELECT config_value FROM app_configs WHERE config_key = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString(1) : null;
            }
        }
    }

    /** 更新单个配置值。 */
    public void updateValue(String key, String value) throws SQLException {
        String sql = "UPDATE app_configs SET config_value = ? WHERE config_key = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, value);
            ps.setString(2, key);
            ps.executeUpdate();
        }
    }

    private AppConfig mapRow(ResultSet rs) throws SQLException {
        AppConfig c = new AppConfig();
        c.setConfigKey(rs.getString("config_key"));
        c.setConfigGroup(rs.getString("config_group"));
        c.setConfigValue(rs.getString("config_value"));
        c.setLabel(rs.getString("label"));
        c.setSecret(rs.getInt("is_secret") == 1);
        c.setSortOrder(rs.getInt("sort_order"));
        c.setUpdatedAt(rs.getTimestamp("updated_at"));
        return c;
    }
}
