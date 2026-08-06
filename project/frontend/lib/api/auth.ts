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
    AuthStore.setAuth(res);
    return res;
  }

  static async login(payload: LoginPayload): Promise<AuthResponseData> {
    const res = await fetchClient("/auth/login", {
      method: "POST",
      body: JSON.stringify(payload),
      requireAuth: false,
    });
    AuthStore.setAuth(res);
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

  static async resendVerification(email: string): Promise<void> {
    await fetchClient("/auth/resend-verification", {
      method: "POST",
      body: JSON.stringify({ email }),
      requireAuth: false,
    });
  }

  static async logout(): Promise<void> {
    const refreshToken = AuthStore.getRefreshToken();
    if (refreshToken) {
      try {
        await fetchClient("/auth/logout", {
          method: "POST",
          body: JSON.stringify({ refreshToken }),
        });
      } catch (err) {
        console.error("Logout request failed:", err);
      }
    }
    AuthStore.clearAuth();
  }

  /**
   * Request a password reset link be sent to the given email.
   * Uses the new link-based flow.
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
   * Returns { success: true } if valid, or throws ApiError with code TOKEN_EXPIRED or INVALID_TOKEN.
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
}
