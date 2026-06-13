package com.ajou.common.security;

import org.mindrot.jbcrypt.BCrypt;

/**
 * 密码哈希工具，基于 BCrypt。
 */
public final class PasswordUtil {

    /** BCrypt 工作因子（成本）。 */
    private static final int WORK_FACTOR = 12;

    private PasswordUtil() {
    }

    /** 对明文密码生成 BCrypt 哈希。 */
    public static String hash(String plain) {
        return BCrypt.hashpw(plain, BCrypt.gensalt(WORK_FACTOR));
    }

    /** 校验明文密码与哈希是否匹配。 */
    public static boolean verify(String plain, String hash) {
        if (plain == null || hash == null || !hash.startsWith("$2")) {
            return false;
        }
        try {
            return BCrypt.checkpw(plain, hash);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
