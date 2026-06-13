package com.ajou.product.web;

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

/**
 * 云产品规格（SKU）管理。单 Servlet 按 action 分发（Model 2）。
 *
 * <pre>
 * GET  /admin/products                列表
 * GET  /admin/products?action=new     新增表单
 * GET  /admin/products?action=edit&id 编辑表单
 * POST /admin/products (action=save)  保存（新增/更新）
 * POST /admin/products (action=delete)删除
 * POST /admin/products (action=toggle)上/下架
 * </pre>
 */
@WebServlet("/admin/products")
public class ProductSpecServlet extends HttpServlet {

    private static final String LIST_VIEW = "/WEB-INF/views/admin/products/list.jsp";
    private static final String FORM_VIEW = "/WEB-INF/views/admin/products/form.jsp";
    private final ProductSpecDao dao = new ProductSpecDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("new".equals(action)) {
                req.setAttribute("spec", new ProductSpec());
                req.setAttribute("formMode", "new");
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else if ("edit".equals(action)) {
                ProductSpec spec = dao.findById(parseInt(req.getParameter("id"), 0));
                if (spec == null) {
                    resp.sendRedirect(req.getContextPath() + "/admin/products");
                    return;
                }
                req.setAttribute("spec", spec);
                req.setAttribute("formMode", "edit");
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else {
                req.setAttribute("specs", dao.findAll());
                req.getRequestDispatcher(LIST_VIEW).forward(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("查询产品规格失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("delete".equals(action)) {
                dao.delete(parseInt(req.getParameter("id"), 0));
                resp.sendRedirect(req.getContextPath() + "/admin/products");
            } else if ("toggle".equals(action)) {
                int id = parseInt(req.getParameter("id"), 0);
                boolean active = "1".equals(req.getParameter("active"));
                dao.setActive(id, active);
                resp.sendRedirect(req.getContextPath() + "/admin/products");
            } else {
                save(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("保存产品规格失败", e);
        }
    }

    private void save(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {
        int id = parseInt(req.getParameter("id"), 0);
        ProductSpec spec = bindForm(req, id);

        String error = validate(spec);
        if (error == null && dao.existsByCode(spec.getInstanceCode(), id)) {
            error = "规格标识「" + spec.getInstanceCode() + "」已存在";
        }
        if (error != null) {
            req.setAttribute("spec", spec);
            req.setAttribute("formMode", id > 0 ? "edit" : "new");
            req.setAttribute("error", error);
            req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            return;
        }

        if (id > 0) {
            dao.update(spec);
        } else {
            dao.insert(spec);
        }
        resp.sendRedirect(req.getContextPath() + "/admin/products");
    }

    /** 把表单参数绑定到 ProductSpec。 */
    private ProductSpec bindForm(HttpServletRequest req, int id) {
        ProductSpec spec = new ProductSpec();
        spec.setId(id);
        spec.setInstanceCode(trim(req.getParameter("instanceCode")));
        spec.setTitle(trim(req.getParameter("title")));
        spec.setDescription(trim(req.getParameter("description")));
        String category = req.getParameter("category");
        spec.setCategory("gpu".equals(category) ? "gpu" : "cpu");
        spec.setVcpu(parseInt(req.getParameter("vcpu"), 0));
        spec.setMemoryGb(parseInt(req.getParameter("memoryGb"), 0));
        spec.setFeatureSpec(trim(req.getParameter("featureSpec")));
        spec.setGpuInfo(trim(req.getParameter("gpuInfo")));
        spec.setPriceMonthly(parseMoney(req.getParameter("priceMonthly")));
        String unit = trim(req.getParameter("unit"));
        spec.setUnit(unit == null || unit.isEmpty() ? "/月起" : unit);
        spec.setBadgeText(trim(req.getParameter("badgeText")));
        spec.setActive(req.getParameter("active") != null);
        spec.setSortOrder(parseInt(req.getParameter("sortOrder"), 0));
        spec.setHomeWeight(parseInt(req.getParameter("homeWeight"), 0));
        return spec;
    }

    private String validate(ProductSpec s) {
        if (s.getInstanceCode() == null || s.getInstanceCode().isEmpty()) {
            return "规格标识不能为空";
        }
        if (!s.getInstanceCode().matches("[A-Za-z0-9_]{2,32}")) {
            return "规格标识只能含字母、数字、下划线，长度 2-32";
        }
        if (s.getTitle() == null || s.getTitle().isEmpty()) {
            return "展示名称不能为空";
        }
        if (s.getVcpu() < 0 || s.getMemoryGb() < 0) {
            return "vCPU / 内存不能为负数";
        }
        if (s.getPriceMonthly() == null || s.getPriceMonthly().signum() < 0) {
            return "月付价不能为负数";
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

    private BigDecimal parseMoney(String s) {
        try {
            return s == null || s.isBlank() ? BigDecimal.ZERO : new BigDecimal(s.trim());
        } catch (NumberFormatException e) {
            return BigDecimal.ZERO;
        }
    }
}
