package com.afab.security;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Configurable distributed rate limit settings backed by Redis.
 */
@Component
@ConfigurationProperties(prefix = "afab.rate-limit")
public class RateLimitProperties {

    private boolean enabled = true;
    /** fail_closed (recommended in production) or fail_open (local dev fallback). */
    private String failMode = "fail_closed";
    private int loginPerMinute = 10;
    private int registerPerMinute = 5;
    private int forgotPasswordPerMinute = 5;
    private int verifyEmailPerMinute = 10;
    private int otpPerMinute = 10;
    private int resetPasswordPerMinute = 5;
    private int refreshPerMinute = 30;

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }

    public String getFailMode() { return failMode; }
    public void setFailMode(String failMode) { this.failMode = failMode; }

    public int getLoginPerMinute() { return loginPerMinute; }
    public void setLoginPerMinute(int loginPerMinute) { this.loginPerMinute = loginPerMinute; }

    public int getRegisterPerMinute() { return registerPerMinute; }
    public void setRegisterPerMinute(int registerPerMinute) { this.registerPerMinute = registerPerMinute; }

    public int getForgotPasswordPerMinute() { return forgotPasswordPerMinute; }
    public void setForgotPasswordPerMinute(int forgotPasswordPerMinute) { this.forgotPasswordPerMinute = forgotPasswordPerMinute; }

    public int getVerifyEmailPerMinute() { return verifyEmailPerMinute; }
    public void setVerifyEmailPerMinute(int verifyEmailPerMinute) { this.verifyEmailPerMinute = verifyEmailPerMinute; }

    public int getOtpPerMinute() { return otpPerMinute; }
    public void setOtpPerMinute(int otpPerMinute) { this.otpPerMinute = otpPerMinute; }

    public int getResetPasswordPerMinute() { return resetPasswordPerMinute; }
    public void setResetPasswordPerMinute(int resetPasswordPerMinute) { this.resetPasswordPerMinute = resetPasswordPerMinute; }

    public int getRefreshPerMinute() { return refreshPerMinute; }
    public void setRefreshPerMinute(int refreshPerMinute) { this.refreshPerMinute = refreshPerMinute; }

    public boolean isFailClosed() {
        return !"fail_open".equalsIgnoreCase(failMode);
    }
}
