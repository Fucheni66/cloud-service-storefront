package com.ajou.product.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * 云产品规格（SKU）JavaBean，对应 product_specs 表。
 */
public class ProductSpec {

    private int id;
    private String instanceCode;
    private String title;
    private String description;
    private String category;      // cpu / gpu
    private int vcpu;
    private int memoryGb;
    private String featureSpec;   // CPU:带宽 / GPU:算力
    private String gpuInfo;       // GPU 卡型/显存，CPU 型为空
    private BigDecimal priceMonthly = new BigDecimal("0.00");
    private String unit = "/月起";
    private String badgeText;
    private boolean active = true;
    private int sortOrder;
    private int homeWeight;       // 首页热门权重，>0 进首页「热门产品」区，按权重降序
    private Timestamp createdAt;
    private Timestamp updatedAt;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getInstanceCode() {
        return instanceCode;
    }

    public void setInstanceCode(String instanceCode) {
        this.instanceCode = instanceCode;
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

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public int getVcpu() {
        return vcpu;
    }

    public void setVcpu(int vcpu) {
        this.vcpu = vcpu;
    }

    public int getMemoryGb() {
        return memoryGb;
    }

    public void setMemoryGb(int memoryGb) {
        this.memoryGb = memoryGb;
    }

    public String getFeatureSpec() {
        return featureSpec;
    }

    public void setFeatureSpec(String featureSpec) {
        this.featureSpec = featureSpec;
    }

    public String getGpuInfo() {
        return gpuInfo;
    }

    public void setGpuInfo(String gpuInfo) {
        this.gpuInfo = gpuInfo;
    }

    public BigDecimal getPriceMonthly() {
        return priceMonthly;
    }

    public void setPriceMonthly(BigDecimal priceMonthly) {
        this.priceMonthly = priceMonthly;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public String getBadgeText() {
        return badgeText;
    }

    public void setBadgeText(String badgeText) {
        this.badgeText = badgeText;
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

    public int getHomeWeight() {
        return homeWeight;
    }

    public void setHomeWeight(int homeWeight) {
        this.homeWeight = homeWeight;
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

    /** 是否为 GPU 规格（视图便捷方法）。 */
    public boolean isGpu() {
        return "gpu".equals(category);
    }
}
