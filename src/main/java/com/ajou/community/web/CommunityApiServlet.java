package com.ajou.community.web;

import com.ajou.common.web.Json;
import com.ajou.community.dao.CommunityQuestionDao;
import com.ajou.community.dao.CommunityReplyDao;
import com.ajou.community.model.CommunityQuestion;
import com.ajou.community.model.CommunityReply;

import com.fasterxml.jackson.databind.JsonNode;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Date;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 前台开发者社区 API（公开访问）。按 pathInfo 分发：
 *
 * <pre>
 * GET  /api/community/questions          已发布问答列表
 * GET  /api/community/question?slug=xxx  问答详情 + 回复
 * POST /api/community/publish            发表问答（落待审核 pending）
 * POST /api/community/reply              发表回复（直接发布）
 * </pre>
 */
@WebServlet("/api/community/*")
public class CommunityApiServlet extends HttpServlet {

    private final CommunityQuestionDao questionDao = new CommunityQuestionDao();
    private final CommunityReplyDao replyDao = new CommunityReplyDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = pathOf(req);
        try {
            if ("/questions".equals(path)) {
                writeQuestionList(resp);
            } else if ("/question".equals(path)) {
                writeQuestionDetail(resp, req.getParameter("slug"));
            } else {
                Json.fail(resp, HttpServletResponse.SC_NOT_FOUND, "接口不存在");
            }
        } catch (SQLException e) {
            throw new ServletException("读取社区数据失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String path = pathOf(req);
        try {
            if ("/publish".equals(path)) {
                publishQuestion(req, resp);
            } else if ("/reply".equals(path)) {
                publishReply(req, resp);
            } else {
                Json.fail(resp, HttpServletResponse.SC_NOT_FOUND, "接口不存在");
            }
        } catch (SQLException e) {
            throw new ServletException("提交社区数据失败", e);
        }
    }

    // ---------------- 读 ----------------

    private void writeQuestionList(HttpServletResponse resp) throws SQLException, IOException {
        List<Map<String, Object>> items = new ArrayList<>();
        for (CommunityQuestion q : questionDao.findPublished()) {
            items.add(toListItem(q));
        }
        Map<String, Object> data = Json.map();
        data.put("questions", items);
        Json.ok(resp, data);
    }

    private void writeQuestionDetail(HttpServletResponse resp, String slug)
            throws SQLException, IOException {
        if (slug == null || slug.isBlank()) {
            Json.fail(resp, HttpServletResponse.SC_BAD_REQUEST, "缺少 slug 参数");
            return;
        }
        CommunityQuestion q = questionDao.findBySlug(slug.trim());
        if (q == null || !q.isPublished()) {
            Json.fail(resp, HttpServletResponse.SC_NOT_FOUND, "问答不存在或未发布");
            return;
        }

        Map<String, Object> item = toListItem(q);
        item.put("content", q.getContent() == null ? "" : q.getContent());
        item.put("recommendation", q.getRecommendation() == null ? "" : q.getRecommendation());

        List<Map<String, Object>> replies = new ArrayList<>();
        for (CommunityReply r : replyDao.findPublishedByQuestion(q.getId())) {
            replies.add(toReplyItem(r));
        }
        item.put("replies", replies);

        Map<String, Object> data = Json.map();
        data.put("question", item);
        Json.ok(resp, data);
    }

    // ---------------- 写 ----------------

    private void publishQuestion(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {
        JsonNode body = Json.readBody(req);
        String title = Json.str(body, "title").trim();
        String content = Json.str(body, "content").trim();
        if (title.isEmpty() || content.isEmpty()) {
            Json.fail(resp, HttpServletResponse.SC_BAD_REQUEST, "标题和正文不能为空");
            return;
        }

        String type = orDefault(Json.str(body, "type").trim(), "问题求助");
        String category = orDefault(Json.str(body, "category").trim(), "云服务器 ECS");
        String contact = Json.str(body, "contact").trim();

        CommunityQuestion q = new CommunityQuestion();
        q.setSlug(generateSlug());
        q.setType(type);
        q.setTag(tagOfType(type));
        q.setCategory(category);
        q.setTitle(title);
        q.setSummary(summarize(content));
        q.setContent(normalizeNewlines(content));
        q.setContact(contact.isEmpty() ? null : contact);
        q.setAuthorName("社区用户");
        q.setStatus("pending");   // 待后台审核发布
        questionDao.insert(q);

        Map<String, Object> data = Json.map();
        data.put("message", "内容已提交，待审核通过后将在社区问答中展示。");
        Json.ok(resp, data);
    }

    private void publishReply(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {
        JsonNode body = Json.readBody(req);
        String slug = Json.str(body, "slug").trim();
        String content = Json.str(body, "content").trim();
        if (slug.isEmpty() || content.isEmpty()) {
            Json.fail(resp, HttpServletResponse.SC_BAD_REQUEST, "缺少问题标识或评论内容");
            return;
        }
        CommunityQuestion q = questionDao.findBySlug(slug);
        if (q == null || !q.isPublished()) {
            Json.fail(resp, HttpServletResponse.SC_NOT_FOUND, "问答不存在或未发布");
            return;
        }

        String authorName = orDefault(Json.str(body, "authorName").trim(), "我");
        CommunityReply r = new CommunityReply();
        r.setQuestionId(q.getId());
        r.setAuthorName(authorName);
        r.setOfficial(false);
        r.setContent(content);
        r.setStatus("published");
        int id = replyDao.insert(r);

        // 回查取得 created_at，返回给前台直接渲染
        int newCount = 0;
        Map<String, Object> reply = Json.map();
        reply.put("authorName", authorName);
        reply.put("official", false);
        reply.put("content", content);
        reply.put("likeCount", 0);
        for (CommunityReply x : replyDao.findPublishedByQuestion(q.getId())) {
            newCount++;
            if (x.getId() == id) {
                reply.put("createdAt", formatTime(x.getCreatedAt()));
            }
        }

        Map<String, Object> data = Json.map();
        data.put("reply", reply);
        data.put("replyCount", newCount);
        Json.ok(resp, data);
    }

    // ---------------- 辅助 ----------------

    private Map<String, Object> toListItem(CommunityQuestion q) {
        Map<String, Object> m = Json.map();
        m.put("slug", q.getSlug());
        m.put("tag", q.getTag() == null ? "" : q.getTag());
        m.put("category", q.getCategory());
        m.put("type", q.getType());
        m.put("title", q.getTitle());
        m.put("summary", q.getSummary() == null ? "" : q.getSummary());
        m.put("replyCount", q.getReplyCount());
        m.put("createdAt", formatDate(timeToDate(q.getCreatedAt())));
        return m;
    }

    private Map<String, Object> toReplyItem(CommunityReply r) {
        Map<String, Object> m = Json.map();
        m.put("authorName", r.getAuthorName());
        m.put("official", r.isOfficial());
        m.put("content", r.getContent());
        m.put("likeCount", r.getLikeCount());
        m.put("createdAt", formatTime(r.getCreatedAt()));
        return m;
    }

    private String tagOfType(String type) {
        switch (type) {
            case "经验分享": return "分享";
            case "教程文章": return "教程";
            default:        return "求助";
        }
    }

    private String summarize(String content) {
        String oneLine = content.replaceAll("\\s+", " ").trim();
        return oneLine.length() <= 80 ? oneLine : oneLine.substring(0, 80) + "…";
    }

    private String normalizeNewlines(String s) {
        return s == null ? null : s.replace("\r\n", "\n").replace("\r", "\n").trim();
    }

    private String orDefault(String s, String def) {
        return s == null || s.isEmpty() ? def : s;
    }

    /** 生成全站唯一 slug：u + 毫秒(base36) + 2 位随机。 */
    private String generateSlug() {
        String base = Long.toString(System.currentTimeMillis(), 36);
        int rand = ThreadLocalRandom.current().nextInt(36 * 36);
        return "u" + base + Integer.toString(rand, 36);
    }

    private Date timeToDate(Timestamp t) {
        return t == null ? null : new Date(t.getTime());
    }

    private String formatDate(Date d) {
        return d == null ? "" : new SimpleDateFormat("yyyy-MM-dd").format(d);
    }

    private String formatTime(Timestamp t) {
        return t == null ? "" : new SimpleDateFormat("yyyy-MM-dd HH:mm").format(t);
    }

    private String pathOf(HttpServletRequest req) {
        String p = req.getPathInfo();
        return p == null ? "/" : p;
    }
}
