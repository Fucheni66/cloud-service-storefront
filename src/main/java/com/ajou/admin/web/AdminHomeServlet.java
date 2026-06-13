package com.ajou.admin.web;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

/**
 * 后台入口：/admin 与 /admin/ 重定向到仪表盘（未登录时再由过滤器转登录页）。
 * 使得 http://localhost:8080/admin/ 直接进入后台。
 */
@WebServlet(urlPatterns = {"/admin", "/admin/"})
public class AdminHomeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/admin/dashboard");
    }
}
