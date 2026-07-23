import { fetchClient } from "./client";
import { AuthResponseData, AuthStore } from "@/lib/auth-store";

export interface RegisterPayload {
  firstName: string;
  lastName: string;
  email: string;
  password: String;
  businessName: string;
}

export interface LoginPayload {
  email: string;
  password: String;
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
}
