package com.ajou.dynamics.web;

import com.ajou.dynamics.dao.DynamicCategoryDao;
import com.ajou.dynamics.dao.DynamicPostDao;
import com.ajou.dynamics.model.DynamicPost;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Date;
import java.sql.SQLException;

/**
 * 产品动态文章管理（CMS 发布）。单 Servlet 按 action 分发（Model 2）。
 *
 * <pre>
 * GET  /admin/dynamics                       列表（支持 ?category= 与 ?q= 筛选）
 * GET  /admin/dynamics?action=new            新增表单
 * GET  /admin/dynamics?action=edit&id        编辑表单
 * POST /admin/dynamics (action=save)         保存（新增/更新）
 * POST /admin/dynamics (action=delete)       删除
 * POST /admin/dynamics (action=toggle)       发布/下线
 * </pre>
 */
@WebServlet("/admin/dynamics")
public class DynamicPostServlet extends HttpServlet {

    private static final String LIST_VIEW = "/WEB-INF/views/admin/dynamics/list.jsp";
    private static final String FORM_VIEW = "/WEB-INF/views/admin/dynamics/form.jsp";
    private static final int PAGE_SIZE = 10;

    private final DynamicPostDao dao = new DynamicPostDao();
    private final DynamicCategoryDao categoryDao = new DynamicCategoryDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("new".equals(action)) {
                req.setAttribute("post", new DynamicPost());
                req.setAttribute("formMode", "new");
                req.setAttribute("categories", categoryDao.findActive());
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else if ("edit".equals(action)) {
                DynamicPost post = dao.findById(parseInt(req.getParameter("id"), 0));
                if (post == null) {
                    resp.sendRedirect(req.getContextPath() + "/admin/dynamics");
                    return;
                }
                req.setAttribute("post", post);
                req.setAttribute("formMode", "edit");
                req.setAttribute("categories", categoryDao.findActive());
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else {
                String category = req.getParameter("category");
                String keyword = req.getParameter("q");

                long total = dao.countSearch(category, keyword);
                int totalPages = (int) Math.max(1, (total + PAGE_SIZE - 1) / PAGE_SIZE);
                int page = parseInt(req.getParameter("page"), 1);
                if (page < 1) {
                    page = 1;
                }
                if (page > totalPages) {
                    page = totalPages;
                }
                int offset = (page - 1) * PAGE_SIZE;

                req.setAttribute("posts", dao.searchPaged(category, keyword, offset, PAGE_SIZE));
                req.setAttribute("categories", categoryDao.findAll());
                req.setAttribute("categoryFilter", category == null ? "" : category);
                req.setAttribute("keyword", keyword == null ? "" : keyword);
                req.setAttribute("total", total);
                req.setAttribute("page", page);
                req.setAttribute("totalPages", totalPages);
                req.setAttribute("pageSize", PAGE_SIZE);
                req.getRequestDispatcher(LIST_VIEW).forward(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("查询产品动态失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("delete".equals(action)) {
                dao.delete(parseInt(req.getParameter("id"), 0));
                resp.sendRedirect(req.getContextPath() + "/admin/dynamics");
            } else if ("toggle".equals(action)) {
                int id = parseInt(req.getParameter("id"), 0);
                boolean published = "1".equals(req.getParameter("published"));
                dao.setPublished(id, published);
                resp.sendRedirect(req.getContextPath() + "/admin/dynamics");
            } else {
                save(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("保存产品动态失败", e);
        }
    }

    private void save(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {
        int id = parseInt(req.getParameter("id"), 0);
        DynamicPost post = bindForm(req, id);

        String error = validate(post);
        if (error == null && dao.existsBySlug(post.getSlug(), id)) {
            error = "URL 标识「" + post.getSlug() + "」已存在";
        }
        if (error == null && !categoryDao.existsByCode(post.getCategory(), 0)) {
            error = "分类不存在，请先在「动态分类」中创建";
        }
        if (error != null) {
            req.setAttribute("post", post);
            req.setAttribute("formMode", id > 0 ? "edit" : "new");
            req.setAttribute("categories", categoryDao.findActive());
            req.setAttribute("error", error);
            req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            return;
        }

        if (id > 0) {
            dao.update(post);
        } else {
            dao.insert(post);
        }
        resp.sendRedirect(req.getContextPath() + "/admin/dynamics");
    }

    /** 把表单参数绑定到 DynamicPost。 */
    private DynamicPost bindForm(HttpServletRequest req, int id) {
        DynamicPost post = new DynamicPost();
        post.setId(id);
        post.setSlug(trim(req.getParameter("slug")));
        post.setCategory(trim(req.getParameter("category")));
        post.setTitle(trim(req.getParameter("title")));
        post.setSummary(trim(req.getParameter("summary")));
        post.setContent(normalizeNewlines(req.getParameter("content")));
        post.setProductScope(trim(req.getParameter("productScope")));
        post.setBadgeText(trim(req.getParameter("badgeText")));
        post.setPublished(req.getParameter("published") != null);
        post.setSortOrder(parseInt(req.getParameter("sortOrder"), 0));
        post.setPublishedAt(parseDate(req.getParameter("publishedAt")));
        return post;
    }

    private String validate(DynamicPost p) {
        if (p.getSlug() == null || p.getSlug().isEmpty()) {
            return "URL 标识不能为空";
        }
        if (!p.getSlug().matches("[A-Za-z0-9_-]{2,64}")) {
            return "URL 标识只能含字母、数字、下划线、连字符，长度 2-64";
        }
        if (p.getCategory() == null || p.getCategory().isEmpty()) {
            return "请选择分类";
        }
        if (p.getTitle() == null || p.getTitle().isEmpty()) {
            return "标题不能为空";
        }
        return null;
    }

    private String trim(String s) {
        return s == null ? null : s.trim();
    }

    /** 统一换行符为 \n，便于前台按段落渲染。 */
    private String normalizeNewlines(String s) {
        if (s == null) {
            return null;
        }
        return s.replace("\r\n", "\n").replace("\r", "\n").trim();
    }

    private int parseInt(String s, int defVal) {
        try {
            return s == null || s.isBlank() ? defVal : Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return defVal;
        }
    }

    /** yyyy-MM-dd → java.sql.Date，非法或空返回 null。 */
    private Date parseDate(String s) {
        try {
            return s == null || s.isBlank() ? null : Date.valueOf(s.trim());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
