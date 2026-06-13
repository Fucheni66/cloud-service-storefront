package com.ajou.admin.web;

import com.ajou.admin.dao.AdminDao;
import com.ajou.admin.model.Admin;
import com.ajou.common.security.PasswordUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.SQLException;

/**
 * 管理员登录。
 * GET 显示登录页（已登录则直接跳仪表盘）；POST 校验密码、写 session、更新最近登录时间。
 */
@WebServlet("/admin/login")
public class LoginServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/login.jsp";
    private final AdminDao adminDao = new AdminDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("admin") != null) {
            resp.sendRedirect(req.getContextPath() + "/admin/dashboard");
            return;
        }
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String username = req.getParameter("username");
        String password = req.getParameter("password");
        if (username != null) {
            username = username.trim();
        }

        Admin admin = null;
        try {
            if (username != null && !username.isEmpty()) {
                admin = adminDao.findByUsername(username);
            }
        } catch (SQLException e) {
            req.setAttribute("error", "数据库错误，请稍后重试");
            req.setAttribute("username", username);
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        // 统一提示，不泄露“用户名不存在 / 密码错误”的区别
        if (admin == null || !PasswordUtil.verify(password, admin.getPasswordHash())) {
            req.setAttribute("error", "用户名或密码错误");
            req.setAttribute("username", username);
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        // 防 session fixation：已有 session 则更换 id，否则新建
        HttpSession session = req.getSession(false);
        if (session == null) {
            session = req.getSession(true);
        } else {
            req.changeSessionId();
        }
        admin.setPasswordHash(null); // 不在 session 中保留哈希
        session.setAttribute("admin", admin);

        try {
            adminDao.updateLastLogin(admin.getId());
        } catch (SQLException ignored) {
            // 更新登录时间失败不影响登录主流程
        }

        resp.sendRedirect(req.getContextPath() + "/admin/dashboard");
    }
}
