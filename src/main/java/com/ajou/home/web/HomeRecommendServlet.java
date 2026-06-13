package com.ajou.home.web;

import com.ajou.home.dao.HomeRecommendDao;
import com.ajou.home.model.HomeRecommend;
import com.ajou.home.model.HomeTab;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;

/**
 * 首页「热门产品推荐」卡片管理。单 Servlet 按 action 分发（Model 2）。
 *
 * <pre>
 * GET  /admin/home-recommends                 列表（按标签分组）
 * GET  /admin/home-recommends?action=new      新增表单
 * GET  /admin/home-recommends?action=edit&id  编辑表单
 * POST /admin/home-recommends (action=save)   保存（新增/更新）
 * POST /admin/home-recommends (action=delete) 删除
 * POST /admin/home-recommends (action=toggle) 启用/停用
 * </pre>
 */
@WebServlet("/admin/home-recommends")
public class HomeRecommendServlet extends HttpServlet {

    private static final String LIST_VIEW = "/WEB-INF/views/admin/home-recommends/list.jsp";
    private static final String FORM_VIEW = "/WEB-INF/views/admin/home-recommends/form.jsp";

    private final HomeRecommendDao dao = new HomeRecommendDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("new".equals(action)) {
                req.setAttribute("item", new HomeRecommend());
                req.setAttribute("formMode", "new");
                req.setAttribute("tabs", HomeTab.all());
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else if ("edit".equals(action)) {
                HomeRecommend item = dao.findById(parseInt(req.getParameter("id"), 0));
                if (item == null) {
                    resp.sendRedirect(req.getContextPath() + "/admin/home-recommends");
                    return;
                }
                req.setAttribute("item", item);
                req.setAttribute("formMode", "edit");
                req.setAttribute("tabs", HomeTab.all());
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else {
                String tab = req.getParameter("tab");
                // 首次进入（无 tab 参数）默认展示第一个标签；选「全部标签」会显式传 tab=""
                if (tab == null) {
                    tab = HomeTab.all().keySet().iterator().next();
                }
                req.setAttribute("items", dao.findForAdmin(tab));
                req.setAttribute("tabs", HomeTab.all());
                req.setAttribute("tabFilter", tab);
                req.getRequestDispatcher(LIST_VIEW).forward(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("查询首页推荐失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("delete".equals(action)) {
                dao.delete(parseInt(req.getParameter("id"), 0));
                resp.sendRedirect(req.getContextPath() + "/admin/home-recommends");
            } else if ("toggle".equals(action)) {
                int id = parseInt(req.getParameter("id"), 0);
                boolean active = "1".equals(req.getParameter("active"));
                dao.setActive(id, active);
                resp.sendRedirect(req.getContextPath() + "/admin/home-recommends");
            } else {
                save(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("保存首页推荐失败", e);
        }
    }

    private void save(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {
        int id = parseInt(req.getParameter("id"), 0);
        HomeRecommend item = bindForm(req, id);

        String error = validate(item);
        if (error != null) {
            req.setAttribute("item", item);
            req.setAttribute("formMode", id > 0 ? "edit" : "new");
            req.setAttribute("tabs", HomeTab.all());
            req.setAttribute("error", error);
            req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            return;
        }

        if (id > 0) {
            dao.update(item);
        } else {
            dao.insert(item);
        }
        resp.sendRedirect(req.getContextPath() + "/admin/home-recommends");
    }

    /** 把表单参数绑定到 HomeRecommend。 */
    private HomeRecommend bindForm(HttpServletRequest req, int id) {
        HomeRecommend item = new HomeRecommend();
        item.setId(id);
        item.setTab(HomeTab.normalize(req.getParameter("tab")));
        item.setTitle(trim(req.getParameter("title")));
        item.setDescription(trim(req.getParameter("description")));
        String icon = trim(req.getParameter("icon"));
        item.setIcon(icon == null || icon.isEmpty() ? "fa-solid fa-server" : icon);
        item.setSpecText(trim(req.getParameter("specText")));
        item.setPrice(trim(req.getParameter("price")));
        String unit = trim(req.getParameter("unit"));
        item.setUnit(unit == null || unit.isEmpty() ? "/月起" : unit);
        item.setInstanceCode(trim(req.getParameter("instanceCode")));
        item.setActive(req.getParameter("active") != null);
        item.setSortOrder(parseInt(req.getParameter("sortOrder"), 0));
        return item;
    }

    private String validate(HomeRecommend r) {
        if (!HomeTab.isValid(r.getTab())) {
            return "标签不合法";
        }
        if (r.getTitle() == null || r.getTitle().isEmpty()) {
            return "卡片标题不能为空";
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
