package com.ajou.community.web;

import com.ajou.community.dao.CommunityQuestionDao;
import com.ajou.community.dao.CommunityReplyDao;
import com.ajou.community.model.CommunityQuestion;
import com.ajou.community.model.CommunityReply;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.SQLException;
import java.util.Set;

/**
 * 开发者社区问答管理。单 Servlet 按 action 分发（Model 2）。
 *
 * <pre>
 * GET  /admin/community                  列表（可按 status 过滤）
 * GET  /admin/community?action=new        新增问答
 * GET  /admin/community?action=edit&id    编辑问答 + 回复管理
 * POST /admin/community (action=save)     保存问答
 * POST /admin/community (action=delete)   删除问答（连同回复）
 * POST /admin/community (action=status)   审核状态变更（pending/published/closed）
 * POST /admin/community (action=addReply) 后台追加回复（可标官方）
 * POST /admin/community (action=delReply) 删除回复
 * </pre>
 */
@WebServlet("/admin/community")
public class CommunityAdminServlet extends HttpServlet {

    private static final String LIST_VIEW = "/WEB-INF/views/admin/community/list.jsp";
    private static final String FORM_VIEW = "/WEB-INF/views/admin/community/form.jsp";

    private static final Set<String> STATUSES = Set.of("pending", "published", "closed");

    private final CommunityQuestionDao questionDao = new CommunityQuestionDao();
    private final CommunityReplyDao replyDao = new CommunityReplyDao();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            if ("new".equals(action)) {
                CommunityQuestion q = new CommunityQuestion();
                req.setAttribute("question", q);
                req.setAttribute("formMode", "new");
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else if ("edit".equals(action)) {
                CommunityQuestion q = questionDao.findById(parseInt(req.getParameter("id"), 0));
                if (q == null) {
                    resp.sendRedirect(req.getContextPath() + "/admin/community");
                    return;
                }
                q.setReplies(replyDao.findAllByQuestion(q.getId()));
                req.setAttribute("question", q);
                req.setAttribute("formMode", "edit");
                req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            } else {
                String status = req.getParameter("status");
                req.setAttribute("questions", questionDao.findByStatus(status));
                req.setAttribute("statusFilter", status == null ? "" : status);
                req.setAttribute("pendingCount", questionDao.countPending());
                req.getRequestDispatcher(LIST_VIEW).forward(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("查询社区问答失败", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        try {
            switch (action == null ? "" : action) {
                case "delete":
                    questionDao.delete(parseInt(req.getParameter("id"), 0));
                    resp.sendRedirect(req.getContextPath() + "/admin/community");
                    break;
                case "status":
                    String status = req.getParameter("status");
                    if (STATUSES.contains(status)) {
                        questionDao.setStatus(parseInt(req.getParameter("id"), 0), status);
                    }
                    resp.sendRedirect(req.getContextPath() + "/admin/community");
                    break;
                case "addReply":
                    addReply(req, resp);
                    break;
                case "delReply":
                    delReply(req, resp);
                    break;
                default:
                    save(req, resp);
            }
        } catch (SQLException e) {
            throw new ServletException("保存社区问答失败", e);
        }
    }

    private void save(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, ServletException, IOException {
        int id = parseInt(req.getParameter("id"), 0);
        CommunityQuestion q = bindForm(req, id);

        String error = validate(q);
        if (error == null && questionDao.existsBySlug(q.getSlug(), id)) {
            error = "URL 标识「" + q.getSlug() + "」已存在";
        }
        if (error != null) {
            if (id > 0) {
                q.setReplies(replyDao.findAllByQuestion(id));
            }
            req.setAttribute("question", q);
            req.setAttribute("formMode", id > 0 ? "edit" : "new");
            req.setAttribute("error", error);
            req.getRequestDispatcher(FORM_VIEW).forward(req, resp);
            return;
        }

        if (id > 0) {
            questionDao.update(q);
        } else {
            questionDao.insert(q);
        }
        resp.sendRedirect(req.getContextPath() + "/admin/community");
    }

    private void addReply(HttpServletRequest req, HttpServletResponse resp)
            throws SQLException, IOException {
        int questionId = parseInt(req.getParameter("id"), 0);
        String content = trim(req.getParameter("content"));
        if (content != null && !content.isEmpty() && questionId > 0) {
            CommunityReply r = new CommunityReply();
            r.setQuestionId(questionId);
            r.setAuthorName(orDefault(trim(req.getParameter("authorName")), "云极技术支持"));
            r.setOfficial(req.getParameter("official") != null);
            r.setContent(content);
            r.setStatus("published");
            replyDao.insert(r);
        }
        resp.sendRedirect(req.getContextPath() + "/admin/community?action=edit&id=" + questionId);
    }

    private void delReply(HttpServletRequest req, HttpServletResponse resp) throws SQLException, IOException {
        int questionId = parseInt(req.getParameter("id"), 0);
        int replyId = parseInt(req.getParameter("replyId"), 0);
        replyDao.delete(replyId);
        resp.sendRedirect(req.getContextPath() + "/admin/community?action=edit&id=" + questionId);
    }

    private CommunityQuestion bindForm(HttpServletRequest req, int id) {
        CommunityQuestion q = new CommunityQuestion();
        q.setId(id);
        q.setSlug(trim(req.getParameter("slug")));
        q.setTag(trim(req.getParameter("tag")));
        q.setCategory(orDefault(trim(req.getParameter("category")), "云服务器 ECS"));
        q.setType(orDefault(trim(req.getParameter("type")), "问题求助"));
        q.setTitle(trim(req.getParameter("title")));
        q.setSummary(trim(req.getParameter("summary")));
        q.setContent(normalizeNewlines(req.getParameter("content")));
        q.setRecommendation(normalizeNewlines(req.getParameter("recommendation")));
        q.setContact(trim(req.getParameter("contact")));
        q.setAuthorName(orDefault(trim(req.getParameter("authorName")), "社区用户"));
        String status = req.getParameter("status");
        q.setStatus(STATUSES.contains(status) ? status : "published");
        return q;
    }

    private String validate(CommunityQuestion q) {
        if (q.getSlug() == null || q.getSlug().isEmpty()) {
            return "URL 标识不能为空";
        }
        if (!q.getSlug().matches("[A-Za-z0-9_-]{2,64}")) {
            return "URL 标识只能含字母、数字、下划线、连字符，长度 2-64";
        }
        if (q.getTitle() == null || q.getTitle().isEmpty()) {
            return "标题不能为空";
        }
        return null;
    }

    private String trim(String s) {
        return s == null ? null : s.trim();
    }

    private String normalizeNewlines(String s) {
        if (s == null) {
            return null;
        }
        return s.replace("\r\n", "\n").replace("\r", "\n").trim();
    }

    private String orDefault(String s, String def) {
        return s == null || s.isEmpty() ? def : s;
    }

    private int parseInt(String s, int defVal) {
        try {
            return s == null || s.isBlank() ? defVal : Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return defVal;
        }
    }
}
