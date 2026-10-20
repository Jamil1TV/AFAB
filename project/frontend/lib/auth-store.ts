export interface UserDto {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  businessId: string;
  avatarUrl?: string;
  emailVerified: boolean;
  onboardingComplete: boolean;
  twoFactorEnabled?: boolean;
}

export interface AuthResponseData {
  accessToken: string;
  refreshToken: string;
  user: UserDto;
  requiresTwoFactor?: boolean;
  twoFactorToken?: string;
  devOtp?: string;
}

const ACCESS_TOKEN_KEY = "accessToken";
const REFRESH_TOKEN_KEY = "refreshToken";
const USER_KEY = "user";
const REMEMBER_ME_KEY = "rememberMe";

export class AuthStore {
  static setAuth(data: AuthResponseData, rememberMe: boolean = false) {
    if (typeof window === "undefined") return;

    if (data.accessToken) {
      localStorage.setItem(ACCESS_TOKEN_KEY, data.accessToken);
    }
    if (data.refreshToken) {
      localStorage.setItem(REFRESH_TOKEN_KEY, data.refreshToken);
    }
    if (data.user) {
      localStorage.setItem(USER_KEY, JSON.stringify(data.user));
    }

    const maxAge = rememberMe ? 30 * 24 * 60 * 60 : 24 * 60 * 60;
    if (rememberMe) {
      localStorage.setItem(REMEMBER_ME_KEY, "true");
    } else {
      localStorage.removeItem(REMEMBER_ME_KEY);
    }

    // Set accessToken cookie for middleware / server routing
    if (data.accessToken) {
      document.cookie = `accessToken=${data.accessToken}; path=/; max-age=${maxAge}; SameSite=Lax`;
    }
  }

  static setAccessToken(newToken: string) {
    if (typeof window === "undefined") return;
    localStorage.setItem(ACCESS_TOKEN_KEY, newToken);
    const isRemembered = localStorage.getItem(REMEMBER_ME_KEY) === "true";
    const maxAge = isRemembered ? 30 * 24 * 60 * 60 : 1800;
    document.cookie = `accessToken=${newToken}; path=/; max-age=${maxAge}; SameSite=Lax`;
  }

  static setRefreshToken(newRefreshToken: string) {
    if (typeof window === "undefined") return;
    localStorage.setItem(REFRESH_TOKEN_KEY, newRefreshToken);
  }

  static clearAuth() {
    if (typeof window === "undefined") return;

    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    localStorage.removeItem(REMEMBER_ME_KEY);
    localStorage.removeItem("afab_token");

    // Clear accessToken cookie for all paths and domains
    document.cookie = "accessToken=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; SameSite=Lax";
    document.cookie = "accessToken=; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; SameSite=Lax";
  }

  static getAccessToken(): string | null {
    if (typeof window === "undefined") return null;
    return localStorage.getItem(ACCESS_TOKEN_KEY);
  }

  static getRefreshToken(): string | null {
    if (typeof window === "undefined") return null;
    return localStorage.getItem(REFRESH_TOKEN_KEY);
  }

  static getUser(): UserDto | null {
    if (typeof window === "undefined") return null;
    const raw = localStorage.getItem(USER_KEY);
    if (!raw) return null;
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  }

  static updateUser(updates: Partial<UserDto>) {
    const user = this.getUser();
    if (!user) return;
    const updated = { ...user, ...updates };
    localStorage.setItem(USER_KEY, JSON.stringify(updated));
  }

  static isAuthenticated(): boolean {
    return !!this.getAccessToken();
  }
}
