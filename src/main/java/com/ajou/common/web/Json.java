package com.ajou.common.web;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 前台 API 的 JSON 读写辅助（基于 Jackson）。
 */
public final class Json {

    public static final ObjectMapper MAPPER = new ObjectMapper();

    private Json() {
    }

    /** 读取请求 JSON body，空体返回空对象节点。 */
    public static JsonNode readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (var reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        }
        String body = sb.toString();
        if (body.isBlank()) {
            return MAPPER.createObjectNode();
        }
        try {
            return MAPPER.readTree(body);
        } catch (Exception e) {
            return MAPPER.createObjectNode();
        }
    }

    /** 取字符串字段，缺省返回 ""。 */
    public static String str(JsonNode node, String field) {
        JsonNode v = node.get(field);
        return v == null || v.isNull() ? "" : v.asText();
    }

    public static Map<String, Object> map() {
        return new LinkedHashMap<>();
    }

    /** 写出任意对象为 JSON。 */
    public static void write(HttpServletResponse resp, Object data) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        MAPPER.writeValue(resp.getWriter(), data);
    }

    /** 成功响应：自动补 success=true。 */
    public static void ok(HttpServletResponse resp, Map<String, Object> data) throws IOException {
        data.put("success", true);
        write(resp, data);
    }

    /** 失败响应：设置 HTTP 状态 + success=false + message。 */
    public static void fail(HttpServletResponse resp, int status, String message) throws IOException {
        resp.setStatus(status);
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("success", false);
        m.put("message", message);
        write(resp, m);
    }
}
