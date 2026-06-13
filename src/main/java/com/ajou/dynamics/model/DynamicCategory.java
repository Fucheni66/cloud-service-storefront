package com.ajou.dynamics.model;

import java.sql.Timestamp;

/**
 * 产品动态分类 JavaBean，对应 dynamic_categories 表。
 */
public class DynamicCategory {

    private int id;
    private String code;
    private String name;
    private String color = "blue";
    private int sortOrder;
    private boolean active = true;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    /** 该分类下的文章数（DAO 子查询填充，用于删除前提示）。 */
    private int postCount;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
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

    public int getPostCount() {
        return postCount;
    }

    public void setPostCount(int postCount) {
        this.postCount = postCount;
    }

    /** 角标 class（视图便捷方法）。 */
    public String getBadgeClass() {
        return CategoryColor.badgeClass(color);
    }
}
