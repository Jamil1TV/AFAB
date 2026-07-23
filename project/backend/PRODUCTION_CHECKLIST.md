# AFAB Production Deployment Checklist
## Security & Authentication

Before deploying AFAB to a production environment, complete this checklist to ensure enterprise-grade security and reliability.

### 1. Swap Email Provider
Currently, the system uses `SmtpEmailServiceImpl` which is designed for Gmail/Mailtrap. For production, you MUST swap this out.
- [ ] Create accounts with a transactional email provider (AWS SES, Resend, or SendGrid).
- [ ] Implement a new `EmailService` class (e.g. `AwsSesEmailServiceImpl`) using their official SDK (which is faster and more reliable than raw SMTP).
- [ ] Update `application-prod.yml` to inject the new email service instead of SMTP.

### 2. Implement Phone / SMS Verification (Optional but Recommended)
The database already has `phone_verified_at` and the Token architecture is built.
- [ ] Create a Twilio account.
- [ ] Create a `SmsService` interface and `TwilioSmsServiceImpl`.
- [ ] In `AuthService`, add `sendPhoneVerificationOtp(User user)`. Generate an OTP, save it to `verification_tokens` with `TokenType.PHONE_VERIFICATION`.
- [ ] Add `POST /api/v1/auth/verify-phone` to the controller.

### 3. Hash OTP Tokens in the Database
Currently, the 6-digit OTPs are saved in plain text in the `verification_tokens` table. In a secure production environment, they should be hashed (just like passwords).
- [ ] Update `AuthService` to hash the OTP using `passwordEncoder.encode(otp)` BEFORE saving it to `verificationTokenRepository`.
- [ ] Update `verifyEmail` and `resetPassword` to use `passwordEncoder.matches(code, token.getToken())` instead of a direct SQL lookup by the exact token string.

### 4. Enable Two-Factor Authentication (2FA)
The database has `two_factor_enabled` and `two_factor_secret` columns ready.
- [ ] Add an endpoint `POST /api/v1/auth/setup-2fa` to generate a TOTP secret and return a QR code URI for Google Authenticator.
- [ ] Update the `login()` method in `AuthService`. If `user.getTwoFactorEnabled()` is true, return a temporary token instead of the full tokens.
- [ ] Create `POST /api/v1/auth/verify-2fa` to accept the temporary token + 6-digit authenticator code to issue the real access/refresh tokens.

### 5. Rotate Secrets
- [ ] Generate a completely random, massive `JWT_SECRET` for production and ensure it is injected via environment variables (never hardcoded).
- [ ] Update all MinIO/S3 and PostgreSQL passwords.
