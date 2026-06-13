package com.ajou.dynamics.model;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 产品动态分类的配色调色板。
 *
 * <p>每个配色键对应一组「角标」Tailwind class（这些 class 均已存在于预编译 CSS 中，
 * 新增配色键时务必使用已编译的 class，否则前台无样式）。前台 dynamics.js 中维护一份
 * 同名映射，两端需保持一致。</p>
 */
public final class CategoryColor {

    /** 配色键 → 角标 class。 */
    private static final Map<String, String> BADGE = new LinkedHashMap<>();
    /** 配色键 → 中文名（后台下拉展示）。 */
    private static final Map<String, String> LABEL = new LinkedHashMap<>();

    static {
        put("blue",    "蓝",   "bg-blue-50 text-primary border border-blue-100");
        put("green",   "绿",   "bg-green-50 text-green-600 border border-green-200");
        put("orange",  "橙",   "bg-orange-50 text-orange-600 border border-orange-100");
        put("red",     "红",   "bg-red-50 text-red-500 border border-red-200");
        put("indigo",  "靛蓝", "bg-indigo-50 text-indigo-600 border border-indigo-100");
        put("slate",   "灰蓝", "bg-slate-50 text-slate-600 border border-slate-200");
        put("emerald", "翠绿", "bg-emerald-50 text-emerald-600 border border-emerald-100");
        put("gray",    "灰",   "bg-gray-50 text-gray-600 border border-gray-200");
    }

    private static void put(String key, String label, String badge) {
        LABEL.put(key, label);
        BADGE.put(key, badge);
    }

    private CategoryColor() {
    }

    /** 全部配色键（按定义顺序），供后台下拉。 */
    public static List<String> keys() {
        return List.copyOf(BADGE.keySet());
    }

    /** 配色选项（key/label/badge），供后台表单渲染带预览的下拉。 */
    public static List<Map<String, String>> options() {
        List<Map<String, String>> list = new ArrayList<>();
        for (String key : BADGE.keySet()) {
            Map<String, String> m = new LinkedHashMap<>();
            m.put("key", key);
            m.put("label", LABEL.get(key));
            m.put("badge", BADGE.get(key));
            list.add(m);
        }
        return list;
    }

    /** 配色键是否合法。 */
    public static boolean isValid(String key) {
        return key != null && BADGE.containsKey(key);
    }

    /** 角标 class，未知键回退 blue。 */
    public static String badgeClass(String key) {
        return BADGE.getOrDefault(key, BADGE.get("blue"));
    }

    /** 配色中文名，未知键回退原值。 */
    public static String label(String key) {
        return LABEL.getOrDefault(key, key);
    }
}
