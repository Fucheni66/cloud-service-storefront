package com.ajou.dynamics.model;

import java.sql.Date;
import java.sql.Timestamp;

/**
 * 产品动态文章 JavaBean，对应 dynamic_posts 表。
 */
public class DynamicPost {

    private int id;
    private String slug;
    private String category = "release";   // release/price/maintenance/solution/about/support
    private String title;
    private String summary;
    private String content;
    private String productScope;
    private String badgeText;
    private boolean published = true;
    private int sortOrder;
    private int viewCount;
    private Date publishedAt;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    /** 关联分类显示名（DAO 联表填充，可空）。 */
    private String categoryName;
    /** 关联分类配色键（DAO 联表填充，可空）。 */
    private String categoryColor;

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

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
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

    public String getProductScope() {
        return productScope;
    }

    public void setProductScope(String productScope) {
        this.productScope = productScope;
    }

    public String getBadgeText() {
        return badgeText;
    }

    public void setBadgeText(String badgeText) {
        this.badgeText = badgeText;
    }

    public boolean isPublished() {
        return published;
    }

    public void setPublished(boolean published) {
        this.published = published;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }

    public int getViewCount() {
        return viewCount;
    }

    public void setViewCount(int viewCount) {
        this.viewCount = viewCount;
    }

    public Date getPublishedAt() {
        return publishedAt;
    }

    public void setPublishedAt(Date publishedAt) {
        this.publishedAt = publishedAt;
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

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public String getCategoryColor() {
        return categoryColor;
    }

    public void setCategoryColor(String categoryColor) {
        this.categoryColor = categoryColor;
    }

    /** 分类中文名：优先取关联分类名，缺失时回退分类标识。 */
    public String getCategoryLabel() {
        return categoryName != null && !categoryName.isBlank() ? categoryName : category;
    }

    /** 角标配色 class（视图便捷方法）。 */
    public String getBadgeClass() {
        return CategoryColor.badgeClass(categoryColor);
    }

    /** 角标文案：badgeText 留空时回退到分类名。 */
    public String getEffectiveBadge() {
        return badgeText == null || badgeText.isBlank() ? getCategoryLabel() : badgeText;
    }
}
