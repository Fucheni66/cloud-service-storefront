package com.ajou.user.web;

import com.ajou.order.dao.CloudOrderDao;
import com.ajou.user.dao.UserDao;
import com.ajou.user.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * 用户管理。用户由前台自助注册，后台只做查看 / 搜索 / 启用禁用 / 删除。
 *
 * <pre>
 * GET  /admin/users                       列表（支持 ?provider=&q=）
 * GET  /admin/users?action=detail&id      详情
 * POST /admin/users (action=toggle)       启用/禁用
 * POST /admin/users (action=delete)       删除
 * </pre>
 */
@WebServlet("/admin/users")
public class UserServlet extends HttpServlet {

    private static final String LIST_VIEW = "/WEB-INF/views/admin/users/list.jsp";
    private static final String DETAIL_VIEW = "/WEB-INF/views/admin/users/detail.jsp";
    private final UserDao dao = new UserDao();
    private final CloudOrderDao orderDao = new CloudOrderDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("detail".equals(action)) {
                User user = dao.findById(parseInt(req.getParameter("id")));
                if (user == null) {
                    resp.sendRedirect(req.getContextPath() + "/admin/users");
                    return;
                }
                req.setAttribute("user", user);
                req.setAttribute("orders", orderDao.findByUserId(user.getId()));
                req.getRequestDispatcher(DETAIL_VIEW).forward(req, resp);
            } else {
                String provider = req.getParameter("provider");
                String keyword = req.getParameter("q");
                req.setAttribute("users", dao.search(provider, keyword));
                req.setAttribute("provider", provider == null ? "" : provider);
                req.setAttribute("q", keyword == null ? "" : keyword);
                req.getRequestDispatcher(LIST_VIEW).forward(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("查询用户失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        int id = parseInt(req.getParameter("id"));
        try {
            if ("toggle".equals(action)) {
                String status = "disabled".equals(req.getParameter("status")) ? "disabled" : "active";
                dao.updateStatus(id, status);
            } else if ("delete".equals(action)) {
                dao.delete(id);
            } else if ("deleteOrders".equals(action)) {
                // 批量删除该用户购买的实例/订单；删后前台控制台实时查库即不再显示。
                List<Integer> orderIds = parseIds(req.getParameterValues("orderIds"));
                orderDao.deleteByIdsAndUser(orderIds, id);
                resp.sendRedirect(req.getContextPath() + "/admin/users?action=detail&id=" + id + "&ordersDeleted=1");
                return;
            }
            resp.sendRedirect(req.getContextPath() + "/admin/users");
        } catch (SQLException e) {
            throw new ServletException("更新用户失败", e);
        }
    }

    private int parseInt(String s) {
        try {
            return s == null || s.isBlank() ? 0 : Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private List<Integer> parseIds(String[] values) {
        List<Integer> ids = new ArrayList<>();
        if (values != null) {
            for (String v : values) {
                int id = parseInt(v);
                if (id > 0) {
                    ids.add(id);
                }
            }
        }
        return ids;
    }
}
