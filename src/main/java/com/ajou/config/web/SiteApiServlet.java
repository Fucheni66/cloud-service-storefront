package com.ajou.config.web;

import com.ajou.common.web.Json;
import com.ajou.config.dao.AppConfigDao;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

/**
 * 前台站点信息 API（公开访问，路径在 /admin/* 之外）。
 * 输出站点名称与联系方式，供公共页脚（layout.js）渲染。
 *
 * <pre>
 * GET /api/site  ->  { name, phone, email, icp, support:{ ticketHours, fault, reply } }
 * </pre>
 */
@WebServlet("/api/site")
public class SiteApiServlet extends HttpServlet {

    private final AppConfigDao dao = new AppConfigDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            Map<String, Object> data = Json.map();
            data.put("name", nv(dao.getValue("site.name")));
            data.put("phone", nv(dao.getValue("site.contact_phone")));
            data.put("email", nv(dao.getValue("site.contact_email")));
            data.put("icp", nv(dao.getValue("site.icp")));

            Map<String, Object> support = Json.map();
            support.put("ticketHours", nv(dao.getValue("site.support_ticket_hours")));
            support.put("fault", nv(dao.getValue("site.support_fault")));
            support.put("reply", nv(dao.getValue("site.support_reply")));
            data.put("support", support);

            Json.ok(resp, data);
        } catch (SQLException e) {
            throw new ServletException("读取站点信息失败", e);
        }
    }

    private String nv(String s) {
        return s == null ? "" : s;
    }
}
