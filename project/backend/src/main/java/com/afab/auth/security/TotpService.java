package com.afab.auth.security;

import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.List;

/**
 * Enterprise RFC 6238 Time-based One-Time Password (TOTP) Service.
 * Compatible with Google Authenticator, Microsoft Authenticator, 1Password, and Authy.
 */
@Service
public class TotpService {

    private static final String BASE32_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    private static final int TIME_STEP_SECONDS = 30;
    private static final int DIGITS = 6;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    /**
     * Generates a cryptographically secure Base32 secret key (160-bit / 20 bytes).
     */
    public String generateSecret() {
        byte[] buffer = new byte[20];
        SECURE_RANDOM.nextBytes(buffer);
        return encodeBase32(buffer);
    }

    /**
     * Generates 8 one-time alphanumeric emergency backup recovery codes.
     */
    public List<String> generateBackupCodes() {
        List<String> codes = new ArrayList<>(8);
        for (int i = 0; i < 8; i++) {
            StringBuilder sb = new StringBuilder();
            for (int j = 0; j < 8; j++) {
                int index = SECURE_RANDOM.nextInt(BASE32_ALPHABET.length());
                sb.append(BASE32_ALPHABET.charAt(index));
                if (j == 3) sb.append("-");
            }
            codes.add(sb.toString());
        }
        return codes;
    }

    /**
     * Verifies a 6-digit TOTP code against the secret key.
     * Checks previous, current, and next time windows (+/- 30s) to account for clock skew.
     */
    public boolean verifyCode(String secret, String code) {
        if (secret == null || code == null || code.trim().length() != DIGITS) {
            return false;
        }

        try {
            int targetCode = Integer.parseInt(code.trim());
            long currentStep = System.currentTimeMillis() / 1000L / TIME_STEP_SECONDS;
            byte[] keyBytes = decodeBase32(secret.trim().toUpperCase());

            // Window: -1 (past 30s), 0 (current), +1 (next 30s)
            for (int window = -1; window <= 1; window++) {
                int generated = generateTotpForStep(keyBytes, currentStep + window);
                if (generated == targetCode) {
                    return true;
                }
            }
        } catch (Exception e) {
            return false;
        }
        return false;
    }

    /**
     * Generates the standard key URI format accepted by Authenticator apps.
     */
    public String getQrCodeUri(String email, String secret, String issuer) {
        try {
            String encodedIssuer = URLEncoder.encode(issuer, StandardCharsets.UTF_8);
            String encodedAccount = URLEncoder.encode(email, StandardCharsets.UTF_8);
            return String.format(
                    "otpauth://totp/%s:%s?secret=%s&issuer=%s&algorithm=SHA1&digits=6&period=30",
                    encodedIssuer, encodedAccount, secret, encodedIssuer
            );
        } catch (Exception e) {
            return String.format("otpauth://totp/AFAB:%s?secret=%s&issuer=AFAB", email, secret);
        }
    }

    private int generateTotpForStep(byte[] key, long step) throws Exception {
        byte[] data = new byte[8];
        for (int i = 7; i >= 0; i--) {
            data[i] = (byte) (step & 0xFF);
            step >>= 8;
        }

        Mac mac = Mac.getInstance("HmacSHA1");
        mac.init(new SecretKeySpec(key, "RAW"));
        byte[] hash = mac.doFinal(data);

        int offset = hash[hash.length - 1] & 0x0F;
        int binary = ((hash[offset] & 0x7F) << 24)
                | ((hash[offset + 1] & 0xFF) << 16)
                | ((hash[offset + 2] & 0xFF) << 8)
                | (hash[offset + 3] & 0xFF);

        return binary % 1_000_000;
    }

    private String encodeBase32(byte[] data) {
        StringBuilder out = new StringBuilder();
        int buffer = 0;
        int next = 0;
        int bitsLeft = 0;
        while (next < data.length) {
            buffer <<= 8;
            buffer |= (data[next++] & 0xFF);
            bitsLeft += 8;
            while (bitsLeft >= 5) {
                out.append(BASE32_ALPHABET.charAt((buffer >> (bitsLeft - 5)) & 0x1F));
                bitsLeft -= 5;
            }
        }
        if (bitsLeft > 0) {
            buffer <<= (5 - bitsLeft);
            out.append(BASE32_ALPHABET.charAt(buffer & 0x1F));
        }
        return out.toString();
    }

    private byte[] decodeBase32(String base32) {
        List<Byte> bytes = new ArrayList<>();
        int buffer = 0;
        int bitsLeft = 0;
        for (char c : base32.toCharArray()) {
            int val = BASE32_ALPHABET.indexOf(c);
            if (val < 0) continue; // Skip padding or invalid
            buffer <<= 5;
            buffer |= (val & 0x1F);
            bitsLeft += 5;
            while (bitsLeft >= 8) {
                bytes.add((byte) ((buffer >> (bitsLeft - 8)) & 0xFF));
                bitsLeft -= 8;
            }
        }
        byte[] result = new byte[bytes.size()];
        for (int i = 0; i < bytes.size(); i++) {
            result[i] = bytes.get(i);
        }
        return result;
    }
}
