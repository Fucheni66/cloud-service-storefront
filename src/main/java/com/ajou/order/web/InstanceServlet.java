package com.ajou.order.web;

import com.ajou.order.dao.CloudOrderDao;
import com.ajou.order.model.CloudOrder;
import com.ajou.product.dao.ProductSpecDao;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * 云实例管理（资源视角）：展示已开通的实例，支持续费 / 释放。
 *
 * <pre>
 * GET  /admin/instances                  实例列表（运行中 + 已到期）
 * GET  /admin/instances?action=detail&id 详情（复用订单详情页）
 * POST /admin/instances (action=renew)   续费 1 个月
 * POST /admin/instances (action=release) 释放（status=released）
 * </pre>
 */
@WebServlet("/admin/instances")
public class InstanceServlet extends HttpServlet {

    private static final String LIST_VIEW = "/WEB-INF/views/admin/instances/list.jsp";
    private static final String DETAIL_VIEW = "/WEB-INF/views/admin/orders/detail.jsp";
    private final CloudOrderDao dao = new CloudOrderDao();
    private final ProductSpecDao specDao = new ProductSpecDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("detail".equals(action)) {
                CloudOrder order = dao.findById(parseInt(req.getParameter("id")));
                if (order == null) {
                    resp.sendRedirect(req.getContextPath() + "/admin/instances");
                    return;
                }
                req.setAttribute("order", order);
                req.setAttribute("from", "instances");
                req.getRequestDispatcher(DETAIL_VIEW).forward(req, resp);
            } else {
                String instanceCode = req.getParameter("instanceCode");
                String keyword = req.getParameter("q");
                String status = req.getParameter("status");
                req.setAttribute("instances", dao.findInstances(instanceCode, keyword, status));
                req.setAttribute("specs", specDao.findAll());
                req.setAttribute("instanceCode", instanceCode == null ? "" : instanceCode);
                req.setAttribute("q", keyword == null ? "" : keyword);
                req.setAttribute("status", status == null ? "" : status);
                req.getRequestDispatcher(LIST_VIEW).forward(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("查询云实例失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        int id = parseInt(req.getParameter("id"));
        try {
            if ("renew".equals(action)) {
                dao.renew(id, 1);
            } else if ("release".equals(action)) {
                dao.updateStatus(id, "released");
            }
            resp.sendRedirect(req.getContextPath() + "/admin/instances");
        } catch (SQLException e) {
            throw new ServletException("操作云实例失败", e);
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
