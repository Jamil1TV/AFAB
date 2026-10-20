import { fetchClient } from "./client";
import { AuthResponseData, AuthStore } from "@/lib/auth-store";

export interface RegisterPayload {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  businessName: string;
}

export interface LoginPayload {
  email: string;
  password: string;
  rememberMe?: boolean;
}

export interface VerifyTwoFactorLoginPayload {
  twoFactorToken: string;
  code: string;
  rememberMe?: boolean;
}

export interface ForgotPasswordPayload {
  email: string;
}

export interface ValidateTokenPayload {
  token: string;
}

export interface ResetPasswordByTokenPayload {
  token: string;
  password: string;
}

export interface TwoFactorSetupData {
  secret: string;
  qrCodeUri: string;
  backupCodes: string[];
}

export interface TwoFactorEnablePayload {
  secret: string;
  code: string;
  backupCodes: string[];
}

export interface TwoFactorDisablePayload {
  password?: string;
  code?: string;
}

export interface SessionDto {
  id: string;
  deviceInfo: string;
  ipAddress: string;
  createdAt: string;
  expiresAt: string;
  currentSession: boolean;
}

export interface ApiSuccessResponse {
  success: boolean;
  message: string;
}

export class AuthService {
  static async register(payload: RegisterPayload): Promise<AuthResponseData> {
    const res = await fetchClient("/auth/register", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: false,
    });
    AuthStore.setAuth(res, false);
    return res;
  }

  static async login(payload: LoginPayload): Promise<AuthResponseData> {
    const res = await fetchClient("/auth/login", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: false,
    });
    if (!res.requiresTwoFactor) {
      AuthStore.setAuth(res, !!payload.rememberMe);
    }
    return res;
  }

  static async verifyTwoFactorLogin(payload: VerifyTwoFactorLoginPayload): Promise<AuthResponseData> {
    const res = await fetchClient("/auth/2fa/verify-login", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: false,
    });
    AuthStore.setAuth(res, !!payload.rememberMe);
    return res;
  }

  static async verifyEmail(email: string, code: string): Promise<void> {
    await fetchClient("/auth/verify-email", {
      method: "POST",
      body: JSON.stringify({ email, code }),
      requireAuth: false,
    });
    AuthStore.updateUser({ emailVerified: true });
  }

  static async resendVerification(email: string): Promise<{ success: boolean; message: string; devOtp?: string }> {
    return await fetchClient("/auth/resend-verification", {
      method: "POST",
      body: JSON.stringify({ email }),
      requireAuth: false,
    });
  }

  static async logout(): Promise<void> {
    const refreshToken = AuthStore.getRefreshToken();
    try {
      await fetchClient("/auth/logout", {
        method: "POST",
        body: refreshToken ? JSON.stringify({ refreshToken }) : JSON.stringify({}),
        requireAuth: false,
      });
    } catch (err) {
      console.error("Logout request failed:", err);
    } finally {
      AuthStore.clearAuth();
    }
  }

  /**
   * Request a password reset link be sent to the given email.
   * Uses the link-based flow.
   */
  static async forgotPassword(payload: ForgotPasswordPayload): Promise<ApiSuccessResponse> {
    return await fetchClient("/auth/forgot-password-link", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: false,
    });
  }

  /**
   * Validate a password reset token (from URL query param).
   */
  static async validateResetToken(payload: ValidateTokenPayload): Promise<ApiSuccessResponse> {
    return await fetchClient("/auth/validate-reset-token", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: false,
    });
  }

  /**
   * Reset password using a token from the reset link.
   */
  static async resetPasswordByToken(payload: ResetPasswordByTokenPayload): Promise<ApiSuccessResponse> {
    return await fetchClient("/auth/reset-password-token", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: false,
    });
  }

  // ── Two-Factor Authentication (Authenticated) ─────────────────

  static async setup2FA(): Promise<TwoFactorSetupData> {
    return await fetchClient("/user/2fa/setup", {
      method: "GET",
      requireAuth: true,
    });
  }

  static async enable2FA(payload: TwoFactorEnablePayload): Promise<void> {
    await fetchClient("/user/2fa/enable", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: true,
    });
    AuthStore.updateUser({ twoFactorEnabled: true });
  }

  static async disable2FA(payload: TwoFactorDisablePayload): Promise<void> {
    await fetchClient("/user/2fa/disable", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: true,
    });
    AuthStore.updateUser({ twoFactorEnabled: false });
  }

  static async regenerateBackupCodes(): Promise<string[]> {
    return await fetchClient("/user/2fa/backup-codes", {
      method: "POST",
      requireAuth: true,
    });
  }

  // ── Active Sessions Management (Authenticated) ────────────────

  static async getActiveSessions(): Promise<SessionDto[]> {
    return await fetchClient("/user/me/sessions", {
      method: "GET",
      requireAuth: true,
    });
  }

  static async revokeSession(sessionId: string): Promise<void> {
    await fetchClient(`/user/me/sessions/${sessionId}`, {
      method: "DELETE",
      requireAuth: true,
    });
  }

  static async revokeAllOtherSessions(): Promise<void> {
    await fetchClient("/user/me/sessions", {
      method: "DELETE",
      requireAuth: true,
    });
  }
}
