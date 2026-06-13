package com.ajou.home.web;

import com.ajou.common.web.Json;
import com.ajou.config.dao.AppConfigDao;
import com.ajou.dynamics.dao.DynamicPostDao;
import com.ajou.dynamics.model.DynamicPost;
import com.ajou.home.dao.HomeRecommendDao;
import com.ajou.home.model.HomeRecommend;
import com.ajou.product.dao.ProductSpecDao;
import com.ajou.product.model.ProductSpec;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * 前台首页数据 API（公开访问，路径在 /admin/* 之外）。一次返回首页三块动态数据：
 *
 * <pre>
 * GET /api/home
 *   hotProducts : 顶部「热门产品」浮层（product_specs.home_weight 降序前 4，需上架）
 *   recommend   : 「热门产品推荐」三标签卡片 { basic:[], business:[], gpu:[] }
 *   dynamic     : 浮层底部一条产品动态（按 app_configs home 配置解析）
 * </pre>
 */
@WebServlet("/api/home")
public class HomeApiServlet extends HttpServlet {

    private static final int HOT_LIMIT = 4;
    private static final String KEY_CATEGORY = "home.dynamic_category";
    private static final String KEY_SLUG = "home.dynamic_slug";
    private static final String[] TABS = {"basic", "business", "gpu"};

    private final ProductSpecDao productDao = new ProductSpecDao();
    private final HomeRecommendDao recommendDao = new HomeRecommendDao();
    private final DynamicPostDao postDao = new DynamicPostDao();
    private final AppConfigDao configDao = new AppConfigDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            Map<String, Object> data = Json.map();
            data.put("hotProducts", buildHotProducts());
            data.put("recommend", buildRecommend());
            data.put("dynamic", buildDynamic());
            Json.ok(resp, data);
        } catch (SQLException e) {
            throw new ServletException("读取首页数据失败", e);
        }
    }

    /** 顶部热门产品浮层。 */
    private List<Map<String, Object>> buildHotProducts() throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        for (ProductSpec p : productDao.findHomeHot(HOT_LIMIT)) {
            Map<String, Object> m = Json.map();
            m.put("instanceCode", p.getInstanceCode());
            m.put("title", p.getTitle());
            m.put("description", p.getDescription() == null ? "" : p.getDescription());
            m.put("price", money(p.getPriceMonthly()));
            m.put("unit", p.getUnit());
            m.put("badge", p.getBadgeText() == null ? "" : p.getBadgeText());
            m.put("gpu", p.isGpu());
            list.add(m);
        }
        return list;
    }

    /** 三标签推荐卡片。 */
    private Map<String, Object> buildRecommend() throws SQLException {
        Map<String, Object> recommend = Json.map();
        for (String tab : TABS) {
            List<Map<String, Object>> cards = new ArrayList<>();
            for (HomeRecommend r : recommendDao.findActiveByTab(tab)) {
                Map<String, Object> m = Json.map();
                m.put("title", r.getTitle());
                m.put("description", r.getDescription() == null ? "" : r.getDescription());
                m.put("icon", r.getIcon());
                m.put("spec", r.getSpecText() == null ? "" : r.getSpecText());
                m.put("price", r.getPrice() == null ? "" : r.getPrice());
                m.put("unit", r.getUnit());
                m.put("instance", r.getInstanceCode() == null ? "" : r.getInstanceCode());
                m.put("gpu", r.isGpu());
                cards.add(m);
            }
            recommend.put(tab, cards);
        }
        return recommend;
    }

    /** 解析首页展示的一条产品动态：指定文章 > 指定分类最新 > 全站最新。 */
    private Map<String, Object> buildDynamic() throws SQLException {
        String category = trim(configDao.getValue(KEY_CATEGORY));
        String slug = trim(configDao.getValue(KEY_SLUG));

        DynamicPost post = null;
        if (!slug.isEmpty()) {
            DynamicPost bySlug = postDao.findBySlug(slug);
            if (bySlug != null && bySlug.isPublished()) {
                post = bySlug;
            }
        }
        if (post == null) {
            List<DynamicPost> source = category.isEmpty()
                    ? postDao.findPublished()
                    : postDao.findPublishedByCategory(category);
            if (!source.isEmpty()) {
                post = source.get(0);
            }
        }
        if (post == null) {
            return null;
        }

        Map<String, Object> m = Json.map();
        m.put("slug", post.getSlug());
        m.put("title", post.getTitle());
        m.put("categoryLabel", post.getCategoryLabel());
        m.put("color", post.getCategoryColor() == null ? "blue" : post.getCategoryColor());
        m.put("badgeText", post.getEffectiveBadge());
        return m;
    }

    /** BigDecimal → 去掉多余小数的展示字符串（60.00 → 60，99.50 → 99.5）。 */
    private String money(BigDecimal v) {
        if (v == null) {
            return "0";
        }
        return v.stripTrailingZeros().toPlainString();
    }

    private String trim(String s) {
        return s == null ? "" : s.trim();
    }
}
