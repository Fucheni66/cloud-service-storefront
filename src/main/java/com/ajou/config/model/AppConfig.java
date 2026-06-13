package com.ajou.config.model;

import java.sql.Timestamp;

/**
 * 系统配置项 JavaBean，对应 app_configs 表（key-value + 分组）。
 */
public class AppConfig {

    private String configKey;
    private String configGroup;
    private String configValue;
    private String label;
    private boolean secret;
    private int sortOrder;
    private Timestamp updatedAt;

    public String getConfigKey() {
        return configKey;
    }

    public void setConfigKey(String configKey) {
        this.configKey = configKey;
    }

    public String getConfigGroup() {
        return configGroup;
    }

    public void setConfigGroup(String configGroup) {
        this.configGroup = configGroup;
    }

    public String getConfigValue() {
        return configValue;
    }

    public void setConfigValue(String configValue) {
        this.configValue = configValue;
    }

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public boolean isSecret() {
        return secret;
    }

    public void setSecret(boolean secret) {
        this.secret = secret;
    }

    public int getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }

    /** 敏感项是否已配置（用于不回显时展示状态）。 */
    public boolean isConfigured() {
        return configValue != null && !configValue.isBlank();
    }
}
