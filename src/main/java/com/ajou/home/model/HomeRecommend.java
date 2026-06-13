package com.ajou.home.model;

import java.sql.Timestamp;

/**
 * 首页「热门产品推荐」卡片 JavaBean，对应 home_recommends 表。
 * 三个标签：basic 通用服务器 / business 业务部署 / gpu GPU 算力。
 */
public class HomeRecommend {

    private int id;
    private String tab = "basic";
    private String title;
    private String description;
    private String icon = "fa-solid fa-server";
    private String specText;
    private String price;
    private String unit = "/月起";
    private String instanceCode;
    private boolean active = true;
    private int sortOrder;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getTab() {
        return tab;
    }

    public void setTab(String tab) {
        this.tab = tab;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public String getSpecText() {
        return specText;
    }

    public void setSpecText(String specText) {
        this.specText = specText;
    }

    public String getPrice() {
        return price;
    }

    public void setPrice(String price) {
        this.price = price;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public String getInstanceCode() {
        return instanceCode;
    }

    public void setInstanceCode(String instanceCode) {
        this.instanceCode = instanceCode;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
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

    /** 标签中文名（视图便捷方法）。 */
    public String getTabLabel() {
        return HomeTab.label(tab);
    }

    /** 是否 GPU 标签（前台决定卡片配色用）。 */
    public boolean isGpu() {
        return "gpu".equals(tab);
    }
}
