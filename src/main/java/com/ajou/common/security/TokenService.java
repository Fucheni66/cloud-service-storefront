package com.ajou.common.security;

import java.security.SecureRandom;

/**
 * 本地登录 token 生成（48 位十六进制，等价 PHP 的 bin2hex(random_bytes(24))）。
 */
public final class TokenService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private TokenService() {
    }

    public static String generate() {
        byte[] bytes = new byte[24];
        RANDOM.nextBytes(bytes);
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(Character.forDigit((b >> 4) & 0xF, 16));
            sb.append(Character.forDigit(b & 0xF, 16));
        }
        return sb.toString();
    }
}
