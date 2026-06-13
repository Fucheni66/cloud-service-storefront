package com.ajou.common.mail;

/**
 * 邮件发送相关异常（配置缺失或 SMTP 发送失败）。
 * 携带可直接展示给用户的中文 message。
 */
public class MailException extends Exception {

    public MailException(String message) {
        super(message);
    }

    public MailException(String message, Throwable cause) {
        super(message, cause);
    }
}
