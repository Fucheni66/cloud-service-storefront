package com.ajou.api;

import com.ajou.common.web.Json;
import com.ajou.config.dao.AppConfigDao;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Map;

/**
 * 查询支付状态（前台路径兼容 PHP /alipay_query.php）。
 * 调真实支付宝 alipay.trade.query，只有交易真实成功(TRADE_SUCCESS/TRADE_FINISHED)才返回 paid=true。
 * 未配置或查询失败时一律返回 paid=false（等待支付），绝不在未支付时跳转。
 */
@WebServlet("/alipay_query.php")
public class AlipayQueryServlet extends HttpServlet {

    private final AppConfigDao configDao = new AppConfigDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String orderId = req.getParameter("order_id");
        if (orderId == null || orderId.isBlank()) {
            orderId = req.getParameter("out_trade_no");
        }

        String tradeStatus = "WAIT_BUYER_PAY";
        boolean paid = false;

        if (orderId != null && !orderId.isBlank()) {
            try {
                AlipayClient client = AlipayClient.fromConfig(configDao);
                if (client.isConfigured()) {
                    tradeStatus = client.queryTradeStatus(orderId);
                    paid = "TRADE_SUCCESS".equals(tradeStatus) || "TRADE_FINISHED".equals(tradeStatus);
                }
            } catch (SQLException e) {
                // 读配置失败：按未支付处理
                paid = false;
            } catch (Exception e) {
                // 网关/网络异常：按未支付处理，避免误判已付
                paid = false;
            }
        }

        Map<String, Object> data = Json.map();
        data.put("order_id", orderId);
        data.put("paid", paid);
        data.put("trade_status", tradeStatus);
        Json.ok(resp, data);
    }
}
