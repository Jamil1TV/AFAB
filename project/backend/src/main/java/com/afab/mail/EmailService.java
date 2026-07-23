package com.afab.mail;

/**
 * Email Service Interface — abstracts the email sending mechanism.
 *
 * ┌──────────────────────────────────────────────────────────────────┐
 * │  PRODUCTION SWAP GUIDE                                          │
 * │                                                                  │
 * │  In development, we use SmtpEmailServiceImpl (Gmail SMTP).       │
 * │  For production, create a new implementation of this interface:   │
 * │                                                                  │
 * │  • AWS SES:    AwsSesEmailServiceImpl                            │
 * │  • SendGrid:   SendGridEmailServiceImpl                          │
 * │  • Resend:     ResendEmailServiceImpl                            │
 * │  • Twilio:     TwilioEmailServiceImpl                            │
 * │                                                                  │
 * │  Then use @Profile("prod") on the production impl and            │
 * │  @Profile("!prod") on SmtpEmailServiceImpl. Spring will          │
 * │  automatically pick the right one based on the active profile.   │
 * └──────────────────────────────────────────────────────────────────┘
 */
public interface EmailService {

    /**
     * Send an email verification OTP code to the user.
     *
     * @param to        Recipient email address
     * @param firstName User's first name for personalized greeting
     * @param otpCode   The 6-digit OTP code
     */
    void sendVerificationOtp(String to, String firstName, String otpCode);

    /**
     * Send an email verification magic link to the user.
     *
     * @param to        Recipient email address
     * @param firstName User's first name for personalized greeting
     * @param link      The full verification URL with the token
     */
    void sendVerificationLink(String to, String firstName, String link);

    /**
     * Send a password reset OTP code to the user.
     *
     * @param to        Recipient email address
     * @param firstName User's first name for personalized greeting
     * @param otpCode   The 6-digit OTP code
     */
    void sendPasswordResetOtp(String to, String firstName, String otpCode);

    /**
     * Send a password reset link to the user.
     *
     * @param to        Recipient email address
     * @param firstName User's first name for personalized greeting
     * @param link      The full password reset URL with the token
     */
    void sendPasswordResetLink(String to, String firstName, String link);

    /**
     * Send a security alert email (e.g., password changed, suspicious login).
     *
     * @param to        Recipient email address
     * @param firstName User's first name
     * @param subject   Alert subject
     * @param message   Alert message body
     */
    void sendSecurityAlert(String to, String firstName, String subject, String message);
}
