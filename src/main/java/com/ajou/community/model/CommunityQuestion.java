package com.ajou.community.model;

import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

/**
 * 开发者社区问答 JavaBean，对应 community_questions 表。
 */
public class CommunityQuestion {

    private int id;
    private String slug;
    private String tag;            // 角标，如 连接/计费
    private String category = "云服务器 ECS";
    private String type = "问题求助";
    private String title;
    private String summary;
    private String content;
    private String recommendation;
    private String contact;
    private String authorName = "社区用户";
    private String status = "published";   // pending/published/closed
    private Timestamp createdAt;
    private Timestamp updatedAt;

    /** 关联回复数（DAO 子查询填充）。 */
    private int replyCount;
    /** 详情查询时填充的回复列表。 */
    private List<CommunityReply> replies = new ArrayList<>();

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getSlug() {
        return slug;
    }

    public void setSlug(String slug) {
        this.slug = slug;
    }

    public String getTag() {
        return tag;
    }

    public void setTag(String tag) {
        this.tag = tag;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getRecommendation() {
        return recommendation;
    }

    public void setRecommendation(String recommendation) {
        this.recommendation = recommendation;
    }

    public String getContact() {
        return contact;
    }

    public void setContact(String contact) {
        this.contact = contact;
    }

    public String getAuthorName() {
        return authorName;
    }

    public void setAuthorName(String authorName) {
        this.authorName = authorName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }

    public int getReplyCount() {
        return replyCount;
    }

    public void setReplyCount(int replyCount) {
        this.replyCount = replyCount;
    }

    public List<CommunityReply> getReplies() {
        return replies;
    }

    public void setReplies(List<CommunityReply> replies) {
        this.replies = replies;
    }

    /** 状态中文名（视图便捷方法）。 */
    public String getStatusLabel() {
        switch (status == null ? "" : status) {
            case "pending":   return "待审核";
            case "published": return "已发布";
            case "closed":    return "已关闭";
            default:          return status;
        }
    }

    public boolean isPublished() {
        return "published".equals(status);
    }
}
