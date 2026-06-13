package com.ajou.api;

import com.ajou.common.web.Json;
import com.ajou.config.dao.AppConfigDao;

import com.fasterxml.jackson.databind.JsonNode;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

/**
 * 创建支付（前台路径兼容 PHP /alipay_create.php）。
 * 调真实支付宝当面付 alipay.trade.precreate 生成被扫的 qr_code。
 * 未配置商户参数时直接返回错误（不再生成假链接、不再模拟到账）。
 */
@WebServlet("/alipay_create.php")
public class AlipayCreateServlet extends HttpServlet {

    private final AppConfigDao configDao = new AppConfigDao();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        JsonNode body = Json.readBody(req);
        String orderId = firstNonEmpty(Json.str(body, "order_id"), Json.str(body, "out_trade_no"));
        if (orderId.isEmpty()) {
            Json.fail(resp, 422, "缺少订单号");
            return;
        }
        String amount = firstNonEmpty(Json.str(body, "amount"), Json.str(body, "total_amount"));
        String subject = Json.str(body, "subject");

        AlipayClient client;
        try {
            client = AlipayClient.fromConfig(configDao);
        } catch (SQLException e) {
            Json.fail(resp, 500, "读取支付配置失败");
            return;
        }

        if (!client.isConfigured()) {
            Json.fail(resp, 503, "支付宝当面付未配置，请在后台「系统设置 · 支付宝当面付」填写 App ID 与商户私钥后再试");
            return;
        }

        try {
            String qrCode = client.precreate(orderId, amount, subject);
            if (qrCode == null || qrCode.isBlank()) {
                Json.fail(resp, 502, "未获取到支付二维码");
                return;
            }
            Map<String, Object> data = Json.map();
            data.put("order_id", orderId);
            data.put("amount", amount);
            data.put("pay_url", qrCode);
            data.put("qr_code", qrCode);
            Json.ok(resp, data);
        } catch (Exception e) {
            Json.fail(resp, 502, "创建支付失败：" + shortMessage(e));
        }
    }

    private String firstNonEmpty(String a, String b) {
        return a != null && !a.isEmpty() ? a : (b == null ? "" : b);
    }

    private String shortMessage(Exception e) {
        String m = e.getMessage();
        return m == null || m.isBlank() ? e.getClass().getSimpleName() : m;
    }
}
