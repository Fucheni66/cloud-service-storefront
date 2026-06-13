package com.ajou.ai.web;

import com.ajou.common.web.Json;
import com.ajou.community.dao.CommunityQuestionDao;
import com.ajou.community.model.CommunityQuestion;
import com.ajou.config.dao.AppConfigDao;
import com.ajou.dynamics.dao.DynamicPostDao;
import com.ajou.dynamics.model.DynamicPost;
import com.ajou.product.dao.ProductSpecDao;
import com.ajou.product.model.ProductSpec;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * AI 导购对话代理（公开访问）。前台悬浮球把对话发到这里，由后端携带密钥调用
 * DeepSeek（OpenAI 兼容 /chat/completions），密钥不暴露给浏览器。
 *
 * <pre>
 * POST /api/ai/chat   body: { messages: [ {role:'user'|'assistant', content:'...'}... ] }
 * 返回: { success, reply, action? }
 *   action 为模型按协议输出的选购指令（type/instance/region/os/billing/duration），
 *   由回复文本中的 &lt;&lt;ACTION&gt;&gt;{json}&lt;&lt;END&gt;&gt; 标记解析得到，正文已剥离该标记。
 * </pre>
 *
 * 大模型参数在后台「系统设置 · AI 大模型」（app_configs 的 ai 分组）维护。
 */
@WebServlet("/api/ai/chat")
public class AiChatServlet extends HttpServlet {

    private static final int MAX_HISTORY = 12;
    private static final int MAX_CONTENT_LEN = 2000;
    private static final String ACTION_BEGIN = "<<ACTION>>";
    private static final String ACTION_END = "<<END>>";
    private static final String LINK_BEGIN = "<<LINK>>";
    private static final String LINK_END = "<<END>>";

    /** 购买页可选项，与 purchase.jsp 的 data-value 一一对应（写入系统提示词约束模型输出）。 */
    private static final String OPTIONS_SPEC =
            "地域(region)：beijing=华北2(北京)、shanghai=华东2(上海)、guangzhou=华南1(广州)、singapore=亚太(新加坡)\n"
            + "操作系统(os)：ubuntu=Ubuntu 22.04、centos=CentOS 7.9、windows=Windows Server 2022\n"
            + "计费(billing)：monthly=包年包月、hourly=按量计费\n"
            + "购买时长(duration，月，仅包年包月)：1、3、6、12";

    private final AppConfigDao configDao = new AppConfigDao();
    private final ProductSpecDao productDao = new ProductSpecDao();
    private final DynamicPostDao postDao = new DynamicPostDao();
    private final CommunityQuestionDao questionDao = new CommunityQuestionDao();

    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String enabled;
        String baseUrl;
        String apiKey;
        String model;
        String extraPrompt;
        String catalog;
        List<KbItem> kb;
        try {
            enabled = nv(configDao.getValue("ai.enabled"));
            baseUrl = nv(configDao.getValue("ai.api_base_url"));
            apiKey = nv(configDao.getValue("ai.api_key"));
            model = nv(configDao.getValue("ai.model"));
            extraPrompt = nv(configDao.getValue("ai.system_prompt"));
            catalog = buildCatalog();
            kb = kbItems();
        } catch (SQLException e) {
            Json.fail(resp, 500, "读取 AI 配置失败");
            return;
        }
        String knowledge = renderKnowledge(kb);

        if (!"1".equals(enabled.trim())) {
            Json.fail(resp, 503, "AI 导购未启用，请联系管理员在后台开启");
            return;
        }
        if (apiKey.isBlank() || baseUrl.isBlank() || model.isBlank()) {
            Json.fail(resp, 503, "AI 大模型未配置，请在后台「系统设置 · AI 大模型」中完成配置");
            return;
        }

        JsonNode body = Json.readBody(req);
        JsonNode messages = body.get("messages");
        if (messages == null || !messages.isArray() || messages.isEmpty()) {
            Json.fail(resp, 422, "messages 不能为空");
            return;
        }

        ObjectNode payload = Json.MAPPER.createObjectNode();
        payload.put("model", model.trim());
        payload.put("stream", false);
        payload.put("temperature", 0.7);
        payload.put("max_tokens", 800);
        ArrayNode arr = payload.putArray("messages");

        ObjectNode sys = arr.addObject();
        sys.put("role", "system");
        sys.put("content", buildSystemPrompt(catalog, knowledge, extraPrompt));

        appendHistory(arr, messages);

        String replyRaw;
        try {
            replyRaw = callModel(baseUrl.trim(), apiKey.trim(), payload);
        } catch (Exception e) {
            Json.fail(resp, 502, "AI 服务调用失败：" + shortMessage(e));
            return;
        }

        // 依次剥离两类指令标记：选购指令(action) 与 问题解决跳转(link)
        Map<String, Object> data = Json.map();
        String visible = replyRaw;
        visible = extractMarker(visible, ACTION_BEGIN, "action", data);
        visible = extractMarker(visible, LINK_BEGIN, "link", data);
        data.put("reply", visible.trim());

        // 校验模型给出的 link slug 是否真实存在；无效或缺失时，用服务端关键词检索兜底，
        // 这样即使模型忘了输出跳转指令，只要命中知识库也会自动补上跳转链接。
        resolveLink(data, kb, lastUserMessage(messages));

        Json.ok(resp, data);
    }

    /** 校验/兜底问题解决跳转链接。 */
    private void resolveLink(Map<String, Object> data, List<KbItem> kb, String userMsg) {
        Object linkObj = data.get("link");
        String slug = (linkObj instanceof JsonNode) ? ((JsonNode) linkObj).path("slug").asText("") : "";
        boolean valid = !slug.isBlank() && kb.stream().anyMatch(k -> k.slug.equals(slug));
        if (valid) {
            return;
        }
        data.remove("link");
        // 已是选购意图(action)就不再附加问题跳转
        if (data.containsKey("action")) {
            return;
        }
        KbItem best = bestMatch(kb, userMsg);
        if (best != null) {
            Map<String, Object> link = Json.map();
            link.put("type", best.type);
            link.put("slug", best.slug);
            link.put("title", best.title);
            data.put("link", link);
        }
    }

    /** 取最近一条用户消息内容。 */
    private String lastUserMessage(JsonNode messages) {
        for (int i = messages.size() - 1; i >= 0; i--) {
            JsonNode m = messages.get(i);
            if ("user".equals(m.path("role").asText(""))) {
                return m.path("content").asText("");
            }
        }
        return "";
    }

    /**
     * 从标记 begin 之后抓取第一个完整的 JSON 对象（按花括号配对，不依赖结束标记），
     * 解析后作为 key 放入 data，并返回剥离「标记 + JSON + 紧随的结束标记」后的可见文本。
     * 这样模型用 &lt;&lt;END&gt;&gt; / &lt;&lt;LINKEND&gt;&gt; 甚至漏写结束标记都能正确解析。
     */
    private String extractMarker(String text, String begin, String key, Map<String, Object> data) {
        int b = text.indexOf(begin);
        if (b < 0) {
            return text;
        }
        int braceStart = text.indexOf('{', b + begin.length());
        if (braceStart < 0) {
            return text.substring(0, b) + text.substring(b + begin.length());
        }
        int braceEnd = matchBrace(text, braceStart);
        if (braceEnd < 0) {
            return text.substring(0, b); // JSON 不完整，丢弃标记及其后内容
        }
        try {
            JsonNode node = Json.MAPPER.readTree(text.substring(braceStart, braceEnd + 1));
            if (node.isObject()) {
                data.put(key, node);
            }
        } catch (Exception ignore) {
            // 非法 JSON 时当普通文本处理
        }
        // 剥离标记后紧跟的结束标记（<<END>> / <<LINKEND>> 等）
        String tail = text.substring(braceEnd + 1).replaceFirst("^\\s*<<[A-Za-z]*END>>", "");
        return text.substring(0, b) + tail;
    }

    /** 返回与 open 处 '{' 匹配的 '}' 下标（识别字符串与转义），无匹配返回 -1。 */
    private int matchBrace(String s, int open) {
        int depth = 0;
        boolean inStr = false;
        boolean esc = false;
        for (int i = open; i < s.length(); i++) {
            char c = s.charAt(i);
            if (inStr) {
                if (esc) {
                    esc = false;
                } else if (c == '\\') {
                    esc = true;
                } else if (c == '"') {
                    inStr = false;
                }
            } else if (c == '"') {
                inStr = true;
            } else if (c == '{') {
                depth++;
            } else if (c == '}') {
                depth--;
                if (depth == 0) {
                    return i;
                }
            }
        }
        return -1;
    }

    /** 把前端会话历史追加进请求（仅 user/assistant，限条数与长度）。 */
    private void appendHistory(ArrayNode arr, JsonNode messages) {
        int start = Math.max(0, messages.size() - MAX_HISTORY);
        for (int i = start; i < messages.size(); i++) {
            JsonNode m = messages.get(i);
            String role = m.path("role").asText("");
            String content = m.path("content").asText("");
            if (content.isBlank() || !("user".equals(role) || "assistant".equals(role))) {
                continue;
            }
            if (content.length() > MAX_CONTENT_LEN) {
                content = content.substring(0, MAX_CONTENT_LEN);
            }
            ObjectNode node = arr.addObject();
            node.put("role", role);
            node.put("content", content);
        }
    }

    /** 调 OpenAI 兼容 chat/completions，返回首条回复文本。 */
    private String callModel(String baseUrl, String apiKey, ObjectNode payload)
            throws IOException, InterruptedException {
        String url = baseUrl.replaceAll("/+$", "") + "/chat/completions";
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(Duration.ofSeconds(60))
                .header("Content-Type", "application/json")
                .header("Authorization", "Bearer " + apiKey)
                .POST(HttpRequest.BodyPublishers.ofString(
                        Json.MAPPER.writeValueAsString(payload), StandardCharsets.UTF_8))
                .build();

        HttpResponse<String> response = http.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IOException("HTTP " + response.statusCode());
        }
        JsonNode root = Json.MAPPER.readTree(response.body());
        String content = root.path("choices").path(0).path("message").path("content").asText("");
        if (content.isBlank()) {
            throw new IOException("空回复");
        }
        return content;
    }

    /** 在售产品目录（注入系统提示词，模型只能从中推荐）。 */
    private String buildCatalog() throws SQLException {
        StringBuilder sb = new StringBuilder();
        List<ProductSpec> specs = productDao.findAll();
        for (ProductSpec p : specs) {
            if (!p.isActive()) {
                continue;
            }
            sb.append("- instance=").append(p.getInstanceCode())
              .append("｜").append(p.getTitle())
              .append("｜").append(p.getVcpu()).append("核 ").append(p.getMemoryGb()).append("G");
            if (p.getGpuInfo() != null && !p.getGpuInfo().isBlank()) {
                sb.append("｜GPU: ").append(p.getGpuInfo());
            }
            if (p.getFeatureSpec() != null && !p.getFeatureSpec().isBlank()) {
                sb.append("｜").append(p.getFeatureSpec());
            }
            sb.append("｜¥").append(p.getPriceMonthly()).append("/月");
            if (p.getDescription() != null && !p.getDescription().isBlank()) {
                sb.append("｜").append(p.getDescription());
            }
            sb.append("\n");
        }
        return sb.toString();
    }

    /** 知识库一条：用于注入提示词、校验模型 slug、服务端关键词检索兜底。 */
    private static final class KbItem {
        final String type;
        final String slug;
        final String title;
        final String summary;
        final String norm; // 标题归一化（仅字母数字+CJK），用于关键词匹配
        KbItem(String type, String slug, String title, String summary) {
            this.type = type;
            this.slug = slug;
            this.title = title == null ? "" : title;
            this.summary = summary == null ? "" : summary;
            this.norm = normalizeText(this.title);
        }
    }

    /** 问题解决知识库：解决方案文章 + 社区问答（含官方回复）。 */
    private List<KbItem> kbItems() throws SQLException {
        List<KbItem> list = new ArrayList<>();
        for (DynamicPost p : postDao.findPublishedByCategory("solution")) {
            list.add(new KbItem("solution", p.getSlug(), p.getTitle(), p.getSummary()));
        }
        for (CommunityQuestion q : questionDao.findPublished()) {
            String hint = q.getSummary() != null && !q.getSummary().isBlank()
                    ? q.getSummary() : q.getRecommendation();
            list.add(new KbItem("question", q.getSlug(), q.getTitle(), hint));
        }
        return list;
    }

    /** 把知识库渲染成提示词文本，供模型匹配并返回跳转 slug。 */
    private String renderKnowledge(List<KbItem> kb) {
        StringBuilder sb = new StringBuilder();
        sb.append("解决方案文章（type=solution，跳转 slug 用于 product-dynamics-detail）：\n");
        for (KbItem it : kb) {
            if (!"solution".equals(it.type)) {
                continue;
            }
            appendKb(sb, it);
        }
        sb.append("社区问答（type=question，含官方回复，跳转 slug 用于 community-question-detail）：\n");
        for (KbItem it : kb) {
            if (!"question".equals(it.type)) {
                continue;
            }
            appendKb(sb, it);
        }
        return sb.toString();
    }

    private void appendKb(StringBuilder sb, KbItem it) {
        sb.append("- slug=").append(it.slug).append("｜").append(it.title);
        if (!it.summary.isBlank()) {
            sb.append("｜").append(it.summary.length() > 60 ? it.summary.substring(0, 60) : it.summary);
        }
        sb.append("\n");
    }

    /** 过于通用、不具区分度的标题二元组，不计入匹配分。 */
    private static final Set<String> STOP_BIGRAMS = Set.of(
            "服务", "务器", "云服", "怎么", "如何", "什么", "可以", "问题", "实例");

    /** 服务端关键词检索：按标题二元组与用户消息的重合度，返回最匹配的一条（分数不足返回 null）。 */
    private KbItem bestMatch(List<KbItem> kb, String userMsg) {
        String u = normalizeText(userMsg);
        if (u.length() < 2) {
            return null;
        }
        KbItem best = null;
        int bestScore = 0;
        for (KbItem it : kb) {
            int score = 0;
            Set<String> seen = new HashSet<>();
            String t = it.norm;
            for (int i = 0; i + 2 <= t.length(); i++) {
                String bg = t.substring(i, i + 2);
                if (STOP_BIGRAMS.contains(bg) || !seen.add(bg)) {
                    continue;
                }
                if (u.contains(bg)) {
                    score++;
                }
            }
            if (score > bestScore) {
                bestScore = score;
                best = it;
            }
        }
        return bestScore >= 2 ? best : null;
    }

    /** 仅保留字母数字与中日韩文字并小写，去除空格标点，便于二元组匹配。 */
    private static String normalizeText(String s) {
        if (s == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (char c : s.toLowerCase().toCharArray()) {
            if (Character.isLetterOrDigit(c)) {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    private String buildSystemPrompt(String catalog, String knowledge, String extraPrompt) {
        StringBuilder sb = new StringBuilder();
        sb.append("你是 AJOU 云服务商城的 AI 助手，既能帮用户挑选云服务器并代客自动下单，也能解答使用问题并指引到解决方案页面。\n")
          .append("回答要求：简体中文，热情简洁，不超过 180 字。\n")
          .append("不要向用户追问地域、用途等问题，也不要让用户做选择题；只要用户有选购/推荐意图，就直接用合理默认值给出唯一、明确的推荐。\n")
          .append("只推荐下方产品目录中真实存在的规格。\n")
          .append("排版：可用 **加粗** 标注关键词、用 - 开头列要点；不要使用代码块围栏。\n\n")
          .append("【在售产品目录】\n").append(catalog).append("\n")
          .append("【购买页可选项】\n").append(OPTIONS_SPEC).append("\n\n")
          .append("【自动下单协议】只要你在回复中给出了具体规格推荐，就必须在回复的最后单独一行输出以下指令")
          .append("（用于在该条消息下方显示「自动下单」按钮，不要用代码块包裹）：\n")
          .append(ACTION_BEGIN)
          .append("{\"type\":\"purchase\",\"instance\":\"<规格code>\",\"region\":\"<地域code>\",")
          .append("\"os\":\"<系统code>\",\"billing\":\"<计费code>\",\"duration\":<月数>,\"summary\":\"<一句话配置概述>\"}")
          .append(ACTION_END).append("\n")
          .append("字段必须取自上方可选项的 code；用户未指定的字段一律用默认值：")
          .append("region 按用户提到的地区映射、未提到则=beijing，os=ubuntu，billing=monthly，duration=1。\n")
          .append("只有纯知识咨询或与选购无关的闲聊时才不输出该指令。\n\n")
          .append("【问题解决知识库】\n").append(knowledge).append("\n")
          .append("【问题解决协议】当用户描述的是使用问题、故障排查、配置或方案咨询（而非购买新服务器）时，")
          .append("先从上面知识库里找最匹配的一条，用文字简要解答，然后在回复最后单独一行输出以下指令")
          .append("（用于在该条消息下方显示跳转按钮，不要用代码块包裹）：\n")
          .append(LINK_BEGIN)
          .append("{\"type\":\"solution|question\",\"slug\":\"<对应slug>\",\"title\":\"<对应标题>\"}")
          .append(LINK_END).append("\n")
          .append("结束标记固定用 ").append(LINK_END).append("。slug 与 type 必须严格取自上方知识库；")
          .append("正文里不要写「详见下方 / 见链接 / 看这篇」之类的话，跳转按钮会自动显示在消息下方。")
          .append("知识库里没有合适匹配时，不要编造、不要输出该指令。");
        if (extraPrompt != null && !extraPrompt.isBlank()) {
            sb.append("\n\n【管理员补充要求】\n").append(extraPrompt.trim());
        }
        return sb.toString();
    }

    private String shortMessage(Exception e) {
        String m = e.getMessage();
        return m == null || m.isBlank() ? e.getClass().getSimpleName() : m;
    }

    private String nv(String s) {
        return s == null ? "" : s;
    }
}
