package com.ajou.order.model;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;

/**
 * 云实例订单 JavaBean，对应 cloud_orders 表。
 * 同时承载“订单”和“云实例”两种视角。
 */
public class CloudOrder {

    private int id;
    private String orderNo;
    private Integer userId;
    private String userEmail;
    private String instanceCode;
    private String instanceName;
    private String region;
    private String os;
    private String disk;
    private String publicIp;
    private String billing;
    private BigDecimal amount = new BigDecimal("0.00");
    private String status;       // running / expired / pending / released
    private Timestamp createdAt;
    private Timestamp paidAt;
    private Date expireAt;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getOrderNo() {
        return orderNo;
    }

    public void setOrderNo(String orderNo) {
        this.orderNo = orderNo;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public String getInstanceCode() {
        return instanceCode;
    }

    public void setInstanceCode(String instanceCode) {
        this.instanceCode = instanceCode;
    }

    public String getInstanceName() {
        return instanceName;
    }

    public void setInstanceName(String instanceName) {
        this.instanceName = instanceName;
    }

    public String getRegion() {
        return region;
    }

    public void setRegion(String region) {
        this.region = region;
    }

    public String getOs() {
        return os;
    }

    public void setOs(String os) {
        this.os = os;
    }

    public String getDisk() {
        return disk;
    }

    public void setDisk(String disk) {
        this.disk = disk;
    }

    public String getPublicIp() {
        return publicIp;
    }

    public void setPublicIp(String publicIp) {
        this.publicIp = publicIp;
    }

    public String getBilling() {
        return billing;
    }

    public void setBilling(String billing) {
        this.billing = billing;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
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

    public Timestamp getPaidAt() {
        return paidAt;
    }

    public void setPaidAt(Timestamp paidAt) {
        this.paidAt = paidAt;
    }

    public Date getExpireAt() {
        return expireAt;
    }

    public void setExpireAt(Date expireAt) {
        this.expireAt = expireAt;
    }

    // ---- 视图便捷方法：code → 中文 ----

    public String getRegionLabel() {
        if (region == null) {
            return "";
        }
        switch (region) {
            case "beijing":   return "华北2(北京)";
            case "shanghai":  return "华东2(上海)";
            case "guangzhou": return "华南1(广州)";
            case "singapore": return "亚太(新加坡)";
            default:          return region;
        }
    }

    public String getBillingLabel() {
        return "hourly".equals(billing) ? "按量计费" : "包年包月";
    }

    public String getStatusLabel() {
        if (status == null) {
            return "";
        }
        switch (status) {
            case "running":  return "运行中";
            case "expired":  return "已到期";
            case "pending":  return "待支付";
            case "released": return "已释放";
            default:         return status;
        }
    }

    public boolean isRunning() {
        return "running".equals(status);
    }

    public boolean isPending() {
        return "pending".equals(status);
    }

    /** 运行中且 7 天内到期（续费提醒高亮用）。 */
    public boolean isExpiringSoon() {
        if (!isRunning() || expireAt == null) {
            return false;
        }
        java.time.LocalDate exp = expireAt.toLocalDate();
        java.time.LocalDate today = java.time.LocalDate.now();
        return !exp.isBefore(today) && !exp.isAfter(today.plusDays(7));
    }
}
