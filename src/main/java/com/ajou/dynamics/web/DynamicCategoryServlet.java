package com.ajou.dynamics.web;

import com.ajou.dynamics.dao.DynamicCategoryDao;
import com.ajou.dynamics.model.CategoryColor;
import com.ajou.dynamics.model.DynamicCategory;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * 产品动态分类管理。单 Servlet 按 action 分发（Model 2）。
 *
 * <pre>
 * GET  /admin/dynamic-categories                列表
 * GET  /admin/dynamic-categories?action=new     新增表单
 * GET  /admin/dynamic-categories?action=edit&id 编辑表单
 * POST /admin/dynamic-categories (action=save)  保存
 * POST /admin/dynamic-categories (action=delete)删除（分类下有文章则拒绝）
 * POST /admin/dynamic-categories (action=toggle)启用/停用
 * </pre>
 */
@WebServlet("/admin/dynamic-categories")
public class DynamicCategoryServlet extends HttpServlet {

    private static final String LIST_VIEW = "/WEB-INF/views/admin/dynamic-categories/list.jsp";
    private static final String FORM_VIEW = "/WEB-INF/views/admin/dynamic-categories/form.jsp";
    private final DynamicCategoryDao dao = new DynamicCategoryDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("new".equals(action)) {
                req.setAttribute("category", new DynamicCategory());
                req.setAttribute("formMode", "new");
                req.setAttribute("colors", CategoryColor.options());
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else if ("edit".equals(action)) {
                DynamicCategory cat = dao.findById(parseInt(req.getParameter("id"), 0));
                if (cat == null) {
                    resp.sendRedirect(req.getContextPath() + "/admin/dynamic-categories");
                    return;
                }
                req.setAttribute("category", cat);
                req.setAttribute("formMode", "edit");
                req.setAttribute("colors", CategoryColor.options());
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else {
                req.setAttribute("categories", dao.findAll());
                req.getRequestDispatcher(LIST_VIEW).forward(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("查询动态分类失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("delete".equals(action)) {
                delete(req, resp);
            } else if ("toggle".equals(action)) {
                dao.setActive(parseInt(req.getParameter("id"), 0),
                        "1".equals(req.getParameter("active")));
                resp.sendRedirect(req.getContextPath() + "/admin/dynamic-categories");
            } else {
                save(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("保存动态分类失败", e);
        }
    }

    private void delete(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {
        int id = parseInt(req.getParameter("id"), 0);
        DynamicCategory cat = dao.findById(id);
        if (cat != null && dao.countPosts(cat.getCode()) > 0) {
            // 分类下仍有文章，拒绝删除（避免文章变成孤儿分类）
            req.getSession().setAttribute("flashError",
                    "分类「" + cat.getName() + "」下还有文章，无法删除。请先移走或删除这些文章。");
        } else {
            dao.delete(id);
        }
        resp.sendRedirect(req.getContextPath() + "/admin/dynamic-categories");
    }

    private void save(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {
        int id = parseInt(req.getParameter("id"), 0);
        DynamicCategory cat = bindForm(req, id);
        DynamicCategory old = id > 0 ? dao.findById(id) : null;

        String error = validate(cat);
        if (error == null && dao.existsByCode(cat.getCode(), id)) {
            error = "分类标识「" + cat.getCode() + "」已存在";
        }
        if (error != null) {
            req.setAttribute("category", cat);
            req.setAttribute("formMode", id > 0 ? "edit" : "new");
            req.setAttribute("colors", CategoryColor.options());
            req.setAttribute("error", error);
            req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            return;
        }

        if (id > 0) {
            dao.update(cat, old == null ? null : old.getCode());
        } else {
            dao.insert(cat);
        }
        resp.sendRedirect(req.getContextPath() + "/admin/dynamic-categories");
    }

    private DynamicCategory bindForm(HttpServletRequest req, int id) {
        DynamicCategory cat = new DynamicCategory();
        cat.setId(id);
        cat.setCode(trim(req.getParameter("code")));
        cat.setName(trim(req.getParameter("name")));
        String color = trim(req.getParameter("color"));
        cat.setColor(CategoryColor.isValid(color) ? color : "blue");
        cat.setSortOrder(parseInt(req.getParameter("sortOrder"), 0));
        cat.setActive(req.getParameter("active") != null);
        return cat;
    }

    private String validate(DynamicCategory c) {
        if (c.getCode() == null || c.getCode().isEmpty()) {
            return "分类标识不能为空";
        }
        if (!c.getCode().matches("[A-Za-z0-9_-]{2,32}")) {
            return "分类标识只能含字母、数字、下划线、连字符，长度 2-32";
        }
        if (c.getName() == null || c.getName().isEmpty()) {
            return "分类名称不能为空";
        }
        return null;
    }

    private String trim(String s) {
        return s == null ? null : s.trim();
    }

    private int parseInt(String s, int defVal) {
        try {
            return s == null || s.isBlank() ? defVal : Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return defVal;
        }
    }
}
