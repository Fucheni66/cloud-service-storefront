package com.ajou.common.mail;

import com.ajou.config.dao.AppConfigDao;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

/**
 * SMTP 邮件发送服务。配置来源：系统设置中的 {@code smtp.*}（app_configs 表）。
 *
 * <p>支持两种安全方式：smtp.ssl=1 走 SSL（QQ 邮箱 465 端口），否则走 STARTTLS（587 端口）。
 * 配置缺失时 {@link #isConfigured()} 返回 false，调用方应提示「请先在后台配置 SMTP」。</p>
 */
public class SmtpMailService {

    private final AppConfigDao configDao = new AppConfigDao();

    /** SMTP 是否已配置完整（host/username/password/from 均非空）。 */
    public boolean isConfigured() {
        try {
            return notBlank(configDao.getValue("smtp.host"))
                    && notBlank(configDao.getValue("smtp.username"))
                    && notBlank(configDao.getValue("smtp.password"))
                    && notBlank(configDao.getValue("smtp.from"));
        } catch (Exception e) {
            return false;
        }
    }

    /** 发送验证码邮件（注册/登录/找回密码场景统一模板）。 */
    public void sendVerificationCode(String to, String code, String scene) throws MailException {
        String action;
        switch (scene == null ? "" : scene) {
            case "login": action = "登录验证"; break;
            case "reset": action = "找回密码"; break;
            default:      action = "注册验证"; break;
        }
        String subject = "【AJOU 云服务】" + action + "验证码：" + code;
        String html = "<div style=\"max-width:480px;margin:0 auto;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;\">"
                + "<h2 style=\"color:#0052d9;margin:0 0 16px;\">AJOU 云服务</h2>"
                + "<p style=\"color:#374151;font-size:14px;\">您正在进行<strong>" + escape(action) + "</strong>，验证码为：</p>"
                + "<p style=\"font-size:30px;font-weight:700;letter-spacing:6px;color:#111827;margin:16px 0;\">" + escape(code) + "</p>"
                + "<p style=\"color:#6b7280;font-size:13px;\">验证码 10 分钟内有效，请勿向他人泄露。若非本人操作，请忽略本邮件。</p>"
                + "</div>";
        send(to, subject, html);
    }

    /** 发送一封自定义 HTML 邮件。 */
    public void send(String to, String subject, String htmlBody) throws MailException {
        try {
            String host = configDao.getValue("smtp.host");
            String portStr = configDao.getValue("smtp.port");
            String ssl = configDao.getValue("smtp.ssl");
            final String username = configDao.getValue("smtp.username");
            final String password = configDao.getValue("smtp.password");
            String from = configDao.getValue("smtp.from");
            String fromName = configDao.getValue("smtp.from_name");

            if (!notBlank(host) || !notBlank(username) || !notBlank(password) || !notBlank(from)) {
                throw new MailException("SMTP 未配置完整，请先在「后台 > 系统设置 > SMTP 邮件」中填写");
            }
            int port = parsePort(portStr, "1".equals(ssl) ? 465 : 587);
            boolean useSsl = !"0".equals(ssl);

            Properties props = new Properties();
            props.put("mail.smtp.host", host);
            props.put("mail.smtp.port", String.valueOf(port));
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.connectiontimeout", "10000");
            props.put("mail.smtp.timeout", "10000");
            props.put("mail.smtp.writetimeout", "10000");
            if (useSsl) {
                props.put("mail.smtp.ssl.enable", "true");
                props.put("mail.smtp.ssl.protocols", "TLSv1.2 TLSv1.3");
            } else {
                props.put("mail.smtp.starttls.enable", "true");
            }
            props.put("mail.smtp.ssl.trust", host);

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });

            MimeMessage message = new MimeMessage(session);
            message.setFrom(buildFrom(from, fromName));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to));
            message.setSubject(subject, "UTF-8");
            message.setContent(htmlBody, "text/html; charset=UTF-8");
            Transport.send(message);
        } catch (MailException e) {
            throw e;
        } catch (Exception e) {
            throw new MailException("邮件发送失败：" + e.getMessage(), e);
        }
    }

    private InternetAddress buildFrom(String from, String fromName) throws UnsupportedEncodingException, jakarta.mail.internet.AddressException {
        if (notBlank(fromName)) {
            return new InternetAddress(from, fromName, StandardCharsets.UTF_8.name());
        }
        return new InternetAddress(from);
    }

    private int parsePort(String s, int fallback) {
        try {
            return s == null || s.isBlank() ? fallback : Integer.parseInt(s.trim());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private String escape(String s) {
        if (s == null) {
            return "";
        }
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
