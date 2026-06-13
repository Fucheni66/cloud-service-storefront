package com.ajou.common.db;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

/**
 * JDBC 连接工具。
 *
 * <p>雏形阶段使用 {@link DriverManager} 直连，每次 {@code getConnection} 新建连接，
 * 由调用方用 try-with-resources 关闭，足够支撑低并发的后台场景。
 * 后续接入前台高并发时再替换为连接池（HikariCP / Tomcat JNDI DataSource）。</p>
 */
public final class DbUtil {

    private static final String URL;
    private static final String USERNAME;
    private static final String PASSWORD;

    static {
        try (InputStream in = DbUtil.class.getResourceAsStream("/db.properties")) {
            if (in == null) {
                throw new IllegalStateException("找不到 db.properties");
            }
            Properties props = new Properties();
            props.load(in);
            // Connector/J 8+ 可自动注册驱动，此处显式加载更稳妥
            Class.forName(props.getProperty("jdbc.driver"));
            URL = props.getProperty("jdbc.url");
            USERNAME = props.getProperty("jdbc.username");
            PASSWORD = props.getProperty("jdbc.password");
        } catch (Exception e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    private DbUtil() {
    }

    /** 获取一个新的数据库连接，调用方负责关闭。 */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USERNAME, PASSWORD);
    }
}
