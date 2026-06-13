package com.ajou.api;

import com.ajou.common.web.Json;
import com.ajou.config.dao.AppConfigDao;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.sql.SQLException;
import java.time.Duration;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.Map;
import java.util.TreeMap;

/**
 * 支付宝「当面付」最小客户端（不依赖支付宝 SDK，使用 JDK 自带 RSA2 签名 + HttpClient）。
 * 商户参数从后台「系统设置·支付宝当面付」（app_configs 的 alipay 分组）读取：
 * app_id / merchant_private_key(PKCS8) / gateway_url / sign_type。
 *
 * <pre>
 * precreate()  -> alipay.trade.precreate  当面付下单，返回被扫的 qr_code 支付链接
 * queryTradeStatus() -> alipay.trade.query 查询真实交易状态，只有 TRADE_SUCCESS 才算已付
 * </pre>
 *
 * 说明：传输走 HTTPS 直连支付宝网关；如需更严格的安全可补充对响应 sign 的验签。
 */
public final class AlipayClient {

    private static final HttpClient HTTP = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    private final String appId;
    private final String privateKey;
    private final String gateway;
    private final String signType;

    public AlipayClient(String appId, String privateKey, String gateway, String signType) {
        this.appId = nv(appId).trim();
        this.privateKey = nv(privateKey).trim();
        String g = nv(gateway).trim();
        this.gateway = g.isEmpty() ? "https://openapi.alipay.com/gateway.do" : g;
        String s = nv(signType).trim();
        this.signType = s.isEmpty() ? "RSA2" : s;
    }

    /** 从后台配置构建客户端。 */
    public static AlipayClient fromConfig(AppConfigDao dao) throws SQLException {
        return new AlipayClient(
                dao.getValue("alipay.app_id"),
                dao.getValue("alipay.merchant_private_key"),
                dao.getValue("alipay.gateway_url"),
                dao.getValue("alipay.sign_type"));
    }

    /** 是否已配置（缺 app_id 或商户私钥即视为未配置）。 */
    public boolean isConfigured() {
        return !appId.isEmpty() && !privateKey.isEmpty();
    }

    /** 当面付下单，返回 qr_code（用户扫码的支付链接）。 */
    public String precreate(String outTradeNo, String amount, String subject) throws Exception {
        ObjectNode biz = Json.MAPPER.createObjectNode();
        biz.put("out_trade_no", outTradeNo);
        biz.put("total_amount", normalizeAmount(amount));
        biz.put("subject", subject == null || subject.isBlank() ? "AJOU 云服务" : subject);

        JsonNode r = execute("alipay.trade.precreate", biz.toString()).path("alipay_trade_precreate_response");
        if (!"10000".equals(r.path("code").asText(""))) {
            throw new RuntimeException(r.path("sub_msg").asText(r.path("msg").asText("下单失败")));
        }
        return r.path("qr_code").asText("");
    }

    /** 查询交易状态：WAIT_BUYER_PAY / TRADE_SUCCESS / TRADE_FINISHED / TRADE_CLOSED。 */
    public String queryTradeStatus(String outTradeNo) throws Exception {
        ObjectNode biz = Json.MAPPER.createObjectNode();
        biz.put("out_trade_no", outTradeNo);

        JsonNode r = execute("alipay.trade.query", biz.toString()).path("alipay_trade_query_response");
        if ("10000".equals(r.path("code").asText(""))) {
            return r.path("trade_status").asText("WAIT_BUYER_PAY");
        }
        // 交易不存在(ACQ.TRADE_NOT_EXIST，即尚未支付)等一律视为未支付
        return "WAIT_BUYER_PAY";
    }

    /** 组装公共参数 + 签名，POST 到网关，返回响应 JSON。 */
    private JsonNode execute(String method, String bizContent) throws Exception {
        Map<String, String> params = new TreeMap<>();
        params.put("app_id", appId);
        params.put("method", method);
        params.put("format", "JSON");
        params.put("charset", "utf-8");
        params.put("sign_type", signType);
        params.put("timestamp", ZonedDateTime.now(ZoneId.of("Asia/Shanghai"))
                .format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        params.put("version", "1.0");
        params.put("biz_content", bizContent);

        params.put("sign", sign(buildSignString(params)));

        StringBuilder form = new StringBuilder();
        for (Map.Entry<String, String> e : params.entrySet()) {
            if (form.length() > 0) {
                form.append('&');
            }
            form.append(URLEncoder.encode(e.getKey(), StandardCharsets.UTF_8))
                .append('=')
                .append(URLEncoder.encode(e.getValue(), StandardCharsets.UTF_8));
        }

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(gateway))
                .timeout(Duration.ofSeconds(20))
                .header("Content-Type", "application/x-www-form-urlencoded;charset=utf-8")
                .POST(HttpRequest.BodyPublishers.ofString(form.toString(), StandardCharsets.UTF_8))
                .build();
        HttpResponse<String> response = HTTP.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new RuntimeException("支付宝网关返回 HTTP " + response.statusCode());
        }
        return Json.MAPPER.readTree(response.body());
    }

    /** 待签名串：除 sign 外的非空参数按 key 升序拼成 k=v&k=v（原值，不做 URL 编码）。 */
    private String buildSignString(Map<String, String> params) {
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, String> e : params.entrySet()) {
            if ("sign".equals(e.getKey())) {
                continue;
            }
            String v = e.getValue();
            if (v == null || v.isEmpty()) {
                continue;
            }
            if (sb.length() > 0) {
                sb.append('&');
            }
            sb.append(e.getKey()).append('=').append(v);
        }
        return sb.toString();
    }

    /** RSA2(SHA256withRSA) / RSA(SHA1withRSA) 签名，私钥为 PKCS8 Base64。 */
    private String sign(String content) throws Exception {
        byte[] keyBytes = Base64.getDecoder().decode(privateKey.replaceAll("\\s", ""));
        PrivateKey pk = KeyFactory.getInstance("RSA").generatePrivate(new PKCS8EncodedKeySpec(keyBytes));
        String algorithm = "RSA".equalsIgnoreCase(signType) ? "SHA1withRSA" : "SHA256withRSA";
        Signature sig = Signature.getInstance(algorithm);
        sig.initSign(pk);
        sig.update(content.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(sig.sign());
    }

    private String normalizeAmount(String amount) {
        try {
            String a = amount == null || amount.isBlank() ? "0.01" : amount.trim();
            return new BigDecimal(a).setScale(2, RoundingMode.HALF_UP).toPlainString();
        } catch (Exception e) {
            return "0.01";
        }
    }

    private static String nv(String s) {
        return s == null ? "" : s;
    }
}
