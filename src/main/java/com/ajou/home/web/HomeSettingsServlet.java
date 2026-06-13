package com.ajou.home.web;

import com.ajou.config.dao.AppConfigDao;
import com.ajou.dynamics.dao.DynamicCategoryDao;
import com.ajou.dynamics.dao.DynamicPostDao;
import com.ajou.product.dao.ProductSpecDao;
import com.ajou.product.model.ProductSpec;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * 首页配置中心。集中维护：
 * <pre>
 * GET  /admin/home                       展示配置表单（产品动态展示 + 热门产品权重）
 * POST /admin/home (action=dynamic)      保存首页产品动态展示设置（分类 + 指定文章）
 * POST /admin/home (action=weights)      批量更新各规格的首页热门权重
 * </pre>
 * 产品动态展示设置存 app_configs 的 home 分组（home.dynamic_category / home.dynamic_slug）。
 */
@WebServlet("/admin/home")
public class HomeSettingsServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/home/index.jsp";
    private static final String KEY_CATEGORY = "home.dynamic_category";
    private static final String KEY_SLUG = "home.dynamic_slug";

    private final AppConfigDao configDao = new AppConfigDao();
    private final DynamicCategoryDao categoryDao = new DynamicCategoryDao();
    private final DynamicPostDao postDao = new DynamicPostDao();
    private final ProductSpecDao productDao = new ProductSpecDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            req.setAttribute("dynCategory", nv(configDao.getValue(KEY_CATEGORY)));
            req.setAttribute("dynSlug", nv(configDao.getValue(KEY_SLUG)));
            req.setAttribute("categories", categoryDao.findActive());
            req.setAttribute("posts", postDao.findPublished());
            req.setAttribute("products", productDao.findAll());
            req.setAttribute("saved", req.getParameter("saved"));
            req.getRequestDispatcher(VIEW).forward(req, resp);
        } catch (SQLException e) {
            throw new ServletException("读取首页配置失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("weights".equals(action)) {
                saveWeights(req);
                resp.sendRedirect(req.getContextPath() + "/admin/home?saved=weights");
            } else {
                saveDynamic(req);
                resp.sendRedirect(req.getContextPath() + "/admin/home?saved=dynamic");
            }
        } catch (SQLException e) {
            throw new ServletException("保存首页配置失败", e);
        }
    }

    /** 保存产品动态展示设置。 */
    private void saveDynamic(HttpServletRequest req) throws SQLException {
        String category = trim(req.getParameter("dynCategory"));
        String slug = trim(req.getParameter("dynSlug"));
        configDao.updateValue(KEY_CATEGORY, category);
        configDao.updateValue(KEY_SLUG, slug);
    }

    /** 批量更新各规格首页热门权重（表单字段名 weight_<id>）。 */
    private void saveWeights(HttpServletRequest req) throws SQLException {
        List<ProductSpec> products = productDao.findAll();
        for (ProductSpec p : products) {
            String raw = req.getParameter("weight_" + p.getId());
            if (raw == null) {
                continue;
            }
            int weight = parseInt(raw, p.getHomeWeight());
            if (weight < 0) {
                weight = 0;
            }
            if (weight != p.getHomeWeight()) {
                productDao.updateHomeWeight(p.getId(), weight);
            }
        }
    }

    private String nv(String s) {
        return s == null ? "" : s;
    }

    private String trim(String s) {
        return s == null ? "" : s.trim();
    }

    private int parseInt(String s, int defVal) {
        try {
            return s == null || s.isBlank() ? defVal : Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return defVal;
        }
    }
}
