package com.ajou.home.model;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 首页「热门产品推荐」标签定义（固定三类），统一标识与中文名，供后台下拉与校验使用。
 */
public final class HomeTab {

    /** 标识 → 中文名，保持展示顺序。 */
    private static final Map<String, String> TABS = new LinkedHashMap<>();

    static {
        TABS.put("basic", "通用服务器");
        TABS.put("business", "业务部署");
        TABS.put("gpu", "GPU 算力");
    }

    private HomeTab() {
    }

    /** 全部标签（标识 → 中文名），用于下拉渲染。 */
    public static Map<String, String> all() {
        return TABS;
    }

    /** 标识是否合法。 */
    public static boolean isValid(String tab) {
        return tab != null && TABS.containsKey(tab);
    }

    /** 标识对应中文名，未知返回标识本身。 */
    public static String label(String tab) {
        return TABS.getOrDefault(tab, tab);
    }

    /** 非法标识回落到 basic。 */
    public static String normalize(String tab) {
        return isValid(tab) ? tab : "basic";
    }
}
