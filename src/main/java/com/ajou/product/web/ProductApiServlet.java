package com.ajou.product.web;

import com.ajou.product.dao.ProductSpecDao;
import com.ajou.product.model.ProductSpec;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;

/**
 * 前台产品 API：输出在售（is_active）云产品规格的 JSON，供前台页面 fetch 渲染。
 * 路径在 /admin/* 之外，前台公开可访问。
 */
@WebServlet("/api/products")
public class ProductApiServlet extends HttpServlet {

    private final ProductSpecDao dao = new ProductSpecDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json; charset=UTF-8");
        List<ProductSpec> all;
        try {
            all = dao.findAll();
        } catch (SQLException e) {
            throw new ServletException("读取产品失败", e);
        }
        StringBuilder sb = new StringBuilder("[");
        boolean first = true;
        for (ProductSpec p : all) {
            if (!p.isActive()) {
                continue;
            }
            if (!first) {
                sb.append(",");
            }
            first = false;
            sb.append("{")
              .append("\"instanceCode\":").append(js(p.getInstanceCode())).append(",")
              .append("\"title\":").append(js(p.getTitle())).append(",")
              .append("\"description\":").append(js(p.getDescription())).append(",")
              .append("\"category\":").append(js(p.getCategory())).append(",")
              .append("\"vcpu\":").append(p.getVcpu()).append(",")
              .append("\"memoryGb\":").append(p.getMemoryGb()).append(",")
              .append("\"featureSpec\":").append(js(p.getFeatureSpec())).append(",")
              .append("\"gpuInfo\":").append(js(p.getGpuInfo())).append(",")
              .append("\"priceMonthly\":").append(p.getPriceMonthly()).append(",")
              .append("\"unit\":").append(js(p.getUnit())).append(",")
              .append("\"badgeText\":").append(js(p.getBadgeText()))
              .append("}");
        }
        sb.append("]");
        try (PrintWriter out = resp.getWriter()) {
            out.write(sb.toString());
        }
    }

    /** 输出 JSON 字符串字面量（含转义），null → JSON null。 */
    private static String js(String s) {
        if (s == null) {
            return "null";
        }
        StringBuilder b = new StringBuilder("\"");
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"':  b.append("\\\""); break;
                case '\\': b.append("\\\\"); break;
                case '\n': b.append("\\n"); break;
                case '\r': b.append("\\r"); break;
                case '\t': b.append("\\t"); break;
                default:   b.append(c);
            }
        }
        return b.append("\"").toString();
    }
}
