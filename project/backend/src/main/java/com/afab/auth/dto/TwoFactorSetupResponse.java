package com.afab.auth.dto;

import java.util.List;

public class TwoFactorSetupResponse {
    private String secret;
    private String qrCodeUri;
    private List<String> backupCodes;

    public TwoFactorSetupResponse(String secret, String qrCodeUri, List<String> backupCodes) {
        this.secret = secret;
        this.qrCodeUri = qrCodeUri;
        this.backupCodes = backupCodes;
    }

    public String getSecret() { return secret; }
    public String getQrCodeUri() { return qrCodeUri; }
    public List<String> getBackupCodes() { return backupCodes; }
}
