package com.ajou.admin.model;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;

/**
 * 仪表盘统计数据 DTO（云服务商视角）。
 *
 * <p>{@code adminCount} 与 {@code recentAdmins} 来自真实数据；
 * 其余云服务商 KPI（用户数 / 本月营收 / 运行中实例 / 即将到期）在雏形阶段为 0，
 * 待接入 users / cloud_instances 表后填充。</p>
 */
public class DashboardStats {

    /** 管理员总数（真实）。 */
    private long adminCount;
    /** 最近注册的管理员（真实）。 */
    private List<Admin> recentAdmins = Collections.emptyList();

    /** 注册用户数（待接入 users 表）。 */
    private long userCount;
    /** 本月营收（待接入订单数据），保留 2 位小数。 */
    private BigDecimal monthlyRevenue = new BigDecimal("0.00");
    /** 运行中云实例数（待接入 cloud_instances 表）。 */
    private long runningInstances;
    /** 7 天内即将到期的实例数（续费提醒，待接入）。 */
    private long expiringSoon;

    public long getAdminCount() {
        return adminCount;
    }

    public void setAdminCount(long adminCount) {
        this.adminCount = adminCount;
    }

    public List<Admin> getRecentAdmins() {
        return recentAdmins;
    }

    public void setRecentAdmins(List<Admin> recentAdmins) {
        this.recentAdmins = recentAdmins;
    }

    public long getUserCount() {
        return userCount;
    }

    public void setUserCount(long userCount) {
        this.userCount = userCount;
    }

    public BigDecimal getMonthlyRevenue() {
        return monthlyRevenue;
    }

    public void setMonthlyRevenue(BigDecimal monthlyRevenue) {
        this.monthlyRevenue = monthlyRevenue;
    }

    public long getRunningInstances() {
        return runningInstances;
    }

    public void setRunningInstances(long runningInstances) {
        this.runningInstances = runningInstances;
    }

    public long getExpiringSoon() {
        return expiringSoon;
    }

    public void setExpiringSoon(long expiringSoon) {
        this.expiringSoon = expiringSoon;
    }
}
