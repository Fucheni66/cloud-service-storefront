package com.ajou.order.web;

import com.ajou.order.dao.CloudOrderDao;
import com.ajou.order.model.CloudOrder;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * 订单管理（交易视角）。
 *
 * <pre>
 * GET  /admin/orders                  列表（?status=&q=）
 * GET  /admin/orders?action=detail&id 详情
 * POST /admin/orders (action=pay)     标记开通（pending→running）
 * POST /admin/orders (action=delete)  删除
 * </pre>
 */
@WebServlet("/admin/orders")
public class OrderServlet extends HttpServlet {

    private static final String LIST_VIEW = "/WEB-INF/views/admin/orders/list.jsp";
    private static final String DETAIL_VIEW = "/WEB-INF/views/admin/orders/detail.jsp";
    private final CloudOrderDao dao = new CloudOrderDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("detail".equals(action)) {
                CloudOrder order = dao.findById(parseInt(req.getParameter("id")));
                if (order == null) {
                    resp.sendRedirect(req.getContextPath() + "/admin/orders");
                    return;
                }
                req.setAttribute("order", order);
                req.setAttribute("from", "orders");
                req.getRequestDispatcher(DETAIL_VIEW).forward(req, resp);
            } else {
                String status = req.getParameter("status");
                String keyword = req.getParameter("q");
                req.setAttribute("orders", dao.search(status, keyword));
                req.setAttribute("status", status == null ? "" : status);
                req.setAttribute("q", keyword == null ? "" : keyword);
                req.getRequestDispatcher(LIST_VIEW).forward(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("查询订单失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        int id = parseInt(req.getParameter("id"));
        try {
            if ("pay".equals(action)) {
                dao.markPaid(id);
            } else if ("delete".equals(action)) {
                dao.delete(id);
            }
            resp.sendRedirect(req.getContextPath() + "/admin/orders");
        } catch (SQLException e) {
            throw new ServletException("更新订单失败", e);
        }
    }

    private int parseInt(String s) {
        try {
            return s == null || s.isBlank() ? 0 : Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
