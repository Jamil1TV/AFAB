package com.afab.auth.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public class TwoFactorEnableRequest {
    @NotBlank(message = "Secret is required")
    private String secret;

    @NotBlank(message = "Verification code is required")
    private String code;

    private List<String> backupCodes;

    public String getSecret() { return secret; }
    public void setSecret(String secret) { this.secret = secret; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public List<String> getBackupCodes() { return backupCodes; }
    public void setBackupCodes(List<String> backupCodes) { this.backupCodes = backupCodes; }
}
