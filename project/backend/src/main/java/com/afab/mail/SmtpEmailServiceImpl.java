package com.afab.mail;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

/**
 * SMTP Email Service Implementation — uses Spring's JavaMailSender.
 *
 * This implementation works with any standard SMTP server:
 * - Gmail (development)
 * - Mailtrap (testing)
 * - Mailpit (local Docker)
 *
 * ┌──────────────────────────────────────────────────────────────────┐
 * │  TODO [PRODUCTION]: Replace this with a production-grade         │
 * │  transactional email provider (AWS SES, SendGrid, Resend).       │
 * │  See EmailService.java interface for the swap guide.             │
 * └──────────────────────────────────────────────────────────────────┘
 */
@Service
public class SmtpEmailServiceImpl implements EmailService {

    private static final Logger log = LoggerFactory.getLogger(SmtpEmailServiceImpl.class);

    private final JavaMailSender mailSender;

    @Value("${afab.mail.from:noreply@afab.com}")
    private String fromAddress;

    @Value("${afab.mail.from-name:AFAB}")
    private String fromName;

    @Value("${afab.app.frontend-url:http://localhost:3000}")
    private String frontendUrl;

    public SmtpEmailServiceImpl(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    @Override
    public void sendVerificationOtp(String to, String firstName, String otpCode) {
        String subject = "Verify your AFAB account";
        String html = buildOtpEmailTemplate(
                firstName,
                "Verify Your Email Address",
                "Welcome to AFAB! Use the code below to verify your email address and activate your account.",
                otpCode,
                "This code expires in 15 minutes. If you didn't create an AFAB account, please ignore this email.",
                "#6C3AED" // Purple accent
        );
        sendHtmlEmail(to, subject, html);
        log.info("📧 Verification OTP sent to {} | Code: {}", to, otpCode);
    }

    @Override
    public void sendVerificationLink(String to, String firstName, String link) {
        String subject = "Verify your AFAB account";
        String html = buildLinkEmailTemplate(
                firstName,
                "Verify Your Email Address",
                "Welcome to AFAB! Click the button below to verify your email address and activate your account.",
                "Verify Email",
                link,
                "This link expires in 15 minutes. If you didn't create an AFAB account, please ignore this email.",
                "#6C3AED"
        );
        sendHtmlEmail(to, subject, html);
        log.info("📧 Verification link sent to {}", to);
    }

    @Override
    public void sendPasswordResetOtp(String to, String firstName, String otpCode) {
        String subject = "Reset your AFAB password";
        String html = buildOtpEmailTemplate(
                firstName,
                "Password Reset Request",
                "We received a request to reset your AFAB account password. Use the code below to proceed.",
                otpCode,
                "This code expires in 15 minutes. If you didn't request a password reset, your account is safe — just ignore this email.",
                "#DC2626" // Red accent for urgency
        );
        sendHtmlEmail(to, subject, html);
        log.info("📧 Password reset OTP sent to {} | Code: {}", to, otpCode);
    }

    @Override
    public void sendPasswordResetLink(String to, String firstName, String link) {
        String subject = "Reset your AFAB password";
        String html = buildLinkEmailTemplate(
                firstName,
                "Password Reset Request",
                "We received a request to reset your AFAB account password. Click the button below to set a new password.",
                "Reset Password",
                link,
                "This link expires in 15 minutes. If you didn't request a password reset, your account is safe — just ignore this email.",
                "#DC2626"
        );
        sendHtmlEmail(to, subject, html);
        log.info("📧 Password reset link sent to {}", to);
    }

    @Override
    public void sendSecurityAlert(String to, String firstName, String subject, String message) {
        String html = buildLinkEmailTemplate(
                firstName,
                "Security Alert",
                message,
                "Review Account",
                frontendUrl + "/dashboard/settings",
                "If this wasn't you, please change your password immediately and contact support.",
                "#F59E0B" // Amber for warning
        );
        sendHtmlEmail(to, "⚠️ " + subject, html);
        log.info("📧 Security alert sent to {}: {}", to, subject);
    }

    // ═══════════════════════════════════════════════════════════════
    // Private Helpers
    // ═══════════════════════════════════════════════════════════════

    private void sendHtmlEmail(String to, String subject, String htmlContent) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(fromAddress, fromName);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);
            mailSender.send(message);
        } catch (MessagingException | java.io.UnsupportedEncodingException e) {
            log.error("❌ Failed to send email to {}: {}", to, e.getMessage(), e);
            throw new RuntimeException("Failed to send email. Please try again later.", e);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // Beautiful, Responsive HTML Email Templates
    // ═══════════════════════════════════════════════════════════════

    private String buildOtpEmailTemplate(String firstName, String title, String description, String otpCode, String footer, String accentColor) {
        return """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>%s</title>
                </head>
                <body style="margin:0;padding:0;background-color:#f4f4f7;font-family:'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
                    <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f7;padding:40px 20px;">
                        <tr>
                            <td align="center">
                                <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
                                    <!-- Header -->
                                    <tr>
                                        <td style="background:linear-gradient(135deg,%s,#1e1b4b);padding:40px 40px 30px;text-align:center;">
                                            <h1 style="color:#ffffff;font-size:28px;font-weight:700;margin:0;letter-spacing:-0.5px;">AFAB</h1>
                                            <p style="color:rgba(255,255,255,0.8);font-size:13px;margin:8px 0 0;letter-spacing:1px;">AI Finance Assistant for Business</p>
                                        </td>
                                    </tr>
                                    <!-- Body -->
                                    <tr>
                                        <td style="padding:40px;">
                                            <h2 style="color:#1a1a2e;font-size:22px;font-weight:600;margin:0 0 12px;">%s</h2>
                                            <p style="color:#4a4a68;font-size:15px;line-height:1.6;margin:0 0 32px;">Hi %s,<br><br>%s</p>
                
                                            <!-- OTP Code Box -->
                                            <table role="presentation" width="100%%" cellpadding="0" cellspacing="0">
                                                <tr>
                                                    <td align="center">
                                                        <div style="background-color:#f8f7ff;border:2px dashed %s;border-radius:12px;padding:24px 40px;display:inline-block;">
                                                            <span style="font-size:36px;font-weight:700;letter-spacing:12px;color:#1a1a2e;font-family:'Courier New',monospace;">%s</span>
                                                        </div>
                                                    </td>
                                                </tr>
                                            </table>
                
                                            <p style="color:#8c8ca1;font-size:13px;line-height:1.5;margin:32px 0 0;text-align:center;">%s</p>
                                        </td>
                                    </tr>
                                    <!-- Footer -->
                                    <tr>
                                        <td style="background-color:#f8f7ff;padding:24px 40px;text-align:center;border-top:1px solid #eeeef2;">
                                            <p style="color:#8c8ca1;font-size:12px;margin:0;">© 2026 AFAB. All rights reserved.</p>
                                            <p style="color:#8c8ca1;font-size:11px;margin:8px 0 0;">This is an automated message. Please do not reply.</p>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </table>
                </body>
                </html>
                """.formatted(title, accentColor, title, firstName, description, accentColor, otpCode, footer);
    }

    private String buildLinkEmailTemplate(String firstName, String title, String description, String buttonText, String buttonUrl, String footer, String accentColor) {
        return """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>%s</title>
                </head>
                <body style="margin:0;padding:0;background-color:#f4f4f7;font-family:'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
                    <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f7;padding:40px 20px;">
                        <tr>
                            <td align="center">
                                <table role="presentation" width="600" cellpadding="0" cellspacing="0" style="background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
                                    <!-- Header -->
                                    <tr>
                                        <td style="background:linear-gradient(135deg,%s,#1e1b4b);padding:40px 40px 30px;text-align:center;">
                                            <h1 style="color:#ffffff;font-size:28px;font-weight:700;margin:0;letter-spacing:-0.5px;">AFAB</h1>
                                            <p style="color:rgba(255,255,255,0.8);font-size:13px;margin:8px 0 0;letter-spacing:1px;">AI Finance Assistant for Business</p>
                                        </td>
                                    </tr>
                                    <!-- Body -->
                                    <tr>
                                        <td style="padding:40px;">
                                            <h2 style="color:#1a1a2e;font-size:22px;font-weight:600;margin:0 0 12px;">%s</h2>
                                            <p style="color:#4a4a68;font-size:15px;line-height:1.6;margin:0 0 32px;">Hi %s,<br><br>%s</p>
                
                                            <!-- CTA Button -->
                                            <table role="presentation" width="100%%" cellpadding="0" cellspacing="0">
                                                <tr>
                                                    <td align="center">
                                                        <a href="%s" target="_blank" style="display:inline-block;background-color:%s;color:#ffffff;font-size:16px;font-weight:600;padding:14px 40px;border-radius:8px;text-decoration:none;letter-spacing:0.3px;">%s</a>
                                                    </td>
                                                </tr>
                                            </table>
                
                                            <p style="color:#8c8ca1;font-size:13px;line-height:1.5;margin:32px 0 0;text-align:center;">%s</p>
                                            <p style="color:#b0b0c0;font-size:11px;line-height:1.5;margin:16px 0 0;text-align:center;word-break:break-all;">If the button doesn't work, copy this link:<br>%s</p>
                                        </td>
                                    </tr>
                                    <!-- Footer -->
                                    <tr>
                                        <td style="background-color:#f8f7ff;padding:24px 40px;text-align:center;border-top:1px solid #eeeef2;">
                                            <p style="color:#8c8ca1;font-size:12px;margin:0;">© 2026 AFAB. All rights reserved.</p>
                                            <p style="color:#8c8ca1;font-size:11px;margin:8px 0 0;">This is an automated message. Please do not reply.</p>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>
                    </table>
                </body>
                </html>
                """.formatted(title, accentColor, title, firstName, description, buttonUrl, accentColor, buttonText, footer, buttonUrl);
    }
}
