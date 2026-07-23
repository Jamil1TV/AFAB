export interface UserDto {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  businessId: string;
  avatarUrl?: string;
  emailVerified: boolean;
  onboardingComplete: boolean;
}

export interface AuthResponseData {
  accessToken: string;
  refreshToken: string;
  user: UserDto;
}

const ACCESS_TOKEN_KEY = "accessToken";
const REFRESH_TOKEN_KEY = "refreshToken";
const USER_KEY = "user";

export class AuthStore {
  static setAuth(data: AuthResponseData) {
    if (typeof window === "undefined") return;

    localStorage.setItem(ACCESS_TOKEN_KEY, data.accessToken);
    localStorage.setItem(REFRESH_TOKEN_KEY, data.refreshToken);
    localStorage.setItem(USER_KEY, JSON.stringify(data.user));

    // Also set accessToken in cookie for middleware / proxy.ts
    document.cookie = `accessToken=${data.accessToken}; path=/; max-age=604800; SameSite=Lax`;
  }

  static clearAuth() {
    if (typeof window === "undefined") return;

    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(USER_KEY);

    document.cookie = `accessToken=; path=/; max-age=0; SameSite=Lax`;
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
