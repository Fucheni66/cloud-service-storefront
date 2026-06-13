package com.ajou.dynamics.web;

import com.ajou.common.web.Json;
import com.ajou.dynamics.dao.DynamicCategoryDao;
import com.ajou.dynamics.dao.DynamicPostDao;
import com.ajou.dynamics.model.DynamicCategory;
import com.ajou.dynamics.model.DynamicPost;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Date;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 前台产品动态 API（公开访问，路径在 /admin/* 之外）。
 *
 * <pre>
 * GET /api/dynamics                  已发布文章列表 + 启用分类（供 product-dynamics.jsp 渲染导航与卡片）
 * GET /api/dynamics?category=xxx      指定分类的已发布文章（供精选教程等场景）
 * GET /api/dynamics?slug=xxx          单篇详情 + 相关文章（供 product-dynamics-detail.jsp 渲染）
 * </pre>
 */
@WebServlet("/api/dynamics")
public class DynamicApiServlet extends HttpServlet {

    private final DynamicPostDao dao = new DynamicPostDao();
    private final DynamicCategoryDao categoryDao = new DynamicCategoryDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String slug = req.getParameter("slug");
        String category = req.getParameter("category");
        try {
            if (slug != null && !slug.isBlank()) {
                writeDetail(resp, slug.trim());
            } else {
                writeList(resp, category);
            }
        } catch (SQLException e) {
            throw new ServletException("读取产品动态失败", e);
        }
    }

    /** 列表：仅已发布；category 非空时按分类过滤。附带启用分类清单。 */
    private void writeList(HttpServletResponse resp, String category) throws SQLException, IOException {
        List<DynamicPost> source = (category != null && !category.isBlank())
                ? dao.findPublishedByCategory(category.trim())
                : dao.findPublished();

        List<Map<String, Object>> posts = new ArrayList<>();
        for (DynamicPost p : source) {
            posts.add(toListItem(p));
        }

        List<Map<String, Object>> categories = new ArrayList<>();
        for (DynamicCategory c : categoryDao.findActive()) {
            Map<String, Object> m = Json.map();
            m.put("code", c.getCode());
            m.put("name", c.getName());
            m.put("color", c.getColor());
            categories.add(m);
        }

        Map<String, Object> data = Json.map();
        data.put("posts", posts);
        data.put("categories", categories);
        Json.ok(resp, data);
    }

    /** 详情：未发布或不存在返回 404。 */
    private void writeDetail(HttpServletResponse resp, String slug) throws SQLException, IOException {
        DynamicPost post = dao.findBySlug(slug);
        if (post == null || !post.isPublished()) {
            Json.fail(resp, HttpServletResponse.SC_NOT_FOUND, "动态不存在或未发布");
            return;
        }
        try {
            dao.increaseView(post.getId());
        } catch (SQLException ignore) {
            // 浏览计数失败不影响详情返回
        }

        Map<String, Object> item = toListItem(post);
        item.put("content", post.getContent() == null ? "" : post.getContent());

        List<Map<String, Object>> related = new ArrayList<>();
        for (DynamicPost p : dao.findPublished()) {
            Map<String, Object> r = Json.map();
            r.put("slug", p.getSlug());
            r.put("title", p.getTitle());
            related.add(r);
        }

        Map<String, Object> data = Json.map();
        data.put("post", item);
        data.put("related", related);
        Json.ok(resp, data);
    }

    private Map<String, Object> toListItem(DynamicPost p) {
        Map<String, Object> m = Json.map();
        m.put("slug", p.getSlug());
        m.put("category", p.getCategory());
        m.put("categoryLabel", p.getCategoryLabel());
        m.put("color", p.getCategoryColor() == null ? "blue" : p.getCategoryColor());
        m.put("badgeText", p.getEffectiveBadge());
        m.put("title", p.getTitle());
        m.put("summary", p.getSummary() == null ? "" : p.getSummary());
        m.put("productScope", p.getProductScope() == null ? "" : p.getProductScope());
        m.put("publishedAt", formatDate(p.getPublishedAt()));
        return m;
    }

    private String formatDate(Date d) {
        return d == null ? "" : d.toString();
    }
}
