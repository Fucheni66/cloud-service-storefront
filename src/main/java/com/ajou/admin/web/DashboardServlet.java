package com.ajou.admin.web;

import com.ajou.admin.dao.AdminDao;
import com.ajou.admin.model.DashboardStats;
import com.ajou.order.dao.CloudOrderDao;
import com.ajou.user.dao.UserDao;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * 后台首页仪表盘：查询真实统计后转发到视图。
 * 受 AdminAuthFilter 保护，未登录无法访问。
 */
@WebServlet("/admin/dashboard")
public class DashboardServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/dashboard.jsp";
    private final AdminDao adminDao = new AdminDao();
    private final UserDao userDao = new UserDao();
    private final CloudOrderDao orderDao = new CloudOrderDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        DashboardStats stats = new DashboardStats();
        try {
            stats.setAdminCount(adminDao.count());
            stats.setRecentAdmins(adminDao.findRecent(5));
            stats.setUserCount(userDao.count());                       // 真实：注册用户数
            stats.setMonthlyRevenue(orderDao.sumRevenueThisMonth());   // 真实：本月营收
            stats.setRunningInstances(orderDao.countRunning());        // 真实：运行中实例
            stats.setExpiringSoon(orderDao.countExpiringSoon(7));      // 真实：7 天内到期
        } catch (SQLException e) {
            req.setAttribute("dbError", "数据库连接失败，请确认 MySQL(8889) 已启动");
        }

        req.setAttribute("stats", stats);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }
}
