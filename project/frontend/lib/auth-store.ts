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
  planTier?: "FREE" | "PLUS" | "PRO" | string;
}

export interface AuthResponseData {
  accessToken: string;
  csrfToken?: string;
  user: UserDto;
  requiresTwoFactor?: boolean;
  twoFactorToken?: string;
  devOtp?: string;
  verificationEmailSent?: boolean;
}

const USER_SESSION_KEY = "afab_user";
const ACTIVE_BUSINESS_KEY = "afab_active_business_id";
const CSRF_COOKIE_NAME = "afab_csrf";
const SESSION_COOKIE_NAME = "afab_session";

// Short-lived access token & CSRF token live ONLY in JS memory — NEVER in localStorage.
// The long-lived refresh token lives EXCLUSIVELY in an HttpOnly cookie set by the backend.
let inMemoryAccessToken: string | null = null;
let inMemoryCsrfToken: string | null = null;
let legacyPurged = false;

function purgeLegacyLocalStorageTokens() {
  if (typeof window === "undefined" || legacyPurged) return;
  legacyPurged = true;
  try {
    localStorage.removeItem("accessToken");
    localStorage.removeItem("refreshToken");
    localStorage.removeItem("afab_token");
    localStorage.removeItem("rememberMe");
    localStorage.removeItem("user");
    // Expire any legacy JS-accessible accessToken cookie from earlier builds
    document.cookie =
      "accessToken=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; SameSite=Lax";
  } catch {
    // ignore storage access errors
  }
}

function readCookie(name: string): string | null {
  if (typeof document === "undefined") return null;
  const cookies = document.cookie ? document.cookie.split(";") : [];
  const prefix = `${name}=`;
  for (const raw of cookies) {
    const trimmed = raw.trim();
    if (trimmed.startsWith(prefix)) {
      return decodeURIComponent(trimmed.substring(prefix.length));
    }
  }
  return null;
}

export class AuthStore {
  static setAuth(data: AuthResponseData, _rememberMe: boolean = false) {
    if (typeof window === "undefined") return;
    purgeLegacyLocalStorageTokens();

    if (data.accessToken) {
      inMemoryAccessToken = data.accessToken;
    }
    if (data.csrfToken) {
      inMemoryCsrfToken = data.csrfToken;
    }

    // Set non-sensitive session presence cookie for Next.js proxy / middleware
    const maxAge = _rememberMe ? "; max-age=2592000" : "";
    document.cookie = `${SESSION_COOKIE_NAME}=1; path=/; SameSite=Lax${maxAge}`;

    // ONLY set afab_csrf cookie if backend returned an explicit CSRF token
    if (data.csrfToken) {
      document.cookie = `${CSRF_COOKIE_NAME}=${encodeURIComponent(data.csrfToken)}; path=/; SameSite=Lax${maxAge}`;
    }

    if (data.user) {
      try {
        sessionStorage.setItem(USER_SESSION_KEY, JSON.stringify(data.user));
        if (data.user.businessId) {
          sessionStorage.setItem(ACTIVE_BUSINESS_KEY, data.user.businessId);
        }
      } catch {
        // ignore quota/private mode errors
      }
      window.dispatchEvent(new CustomEvent("afab_profile_updated", { detail: data.user }));
    }
  }

  static setAccessToken(newToken: string, csrfToken?: string) {
    if (typeof window === "undefined") return;
    purgeLegacyLocalStorageTokens();
    inMemoryAccessToken = newToken;
    document.cookie = `${SESSION_COOKIE_NAME}=1; path=/; SameSite=Lax`;
    if (csrfToken) {
      inMemoryCsrfToken = csrfToken;
      document.cookie = `${CSRF_COOKIE_NAME}=${encodeURIComponent(csrfToken)}; path=/; SameSite=Lax`;
    }
  }

  static clearAuth() {
    if (typeof window === "undefined") return;
    inMemoryAccessToken = null;
    inMemoryCsrfToken = null;

    try {
      sessionStorage.removeItem(USER_SESSION_KEY);
      sessionStorage.removeItem(ACTIVE_BUSINESS_KEY);
      localStorage.removeItem("accessToken");
      localStorage.removeItem("refreshToken");
      localStorage.removeItem("user");
      localStorage.removeItem("rememberMe");
      localStorage.removeItem("afab_token");
      localStorage.removeItem("afab_active_business_id");
    } catch {
      // ignore storage errors
    }

    document.cookie =
      "accessToken=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; SameSite=Lax";
    document.cookie =
      `${SESSION_COOKIE_NAME}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; SameSite=Lax`;
    document.cookie =
      `${CSRF_COOKIE_NAME}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; SameSite=Lax`;
  }

  static getActiveBusinessId(): string | null {
    if (typeof window === "undefined") return null;
    try {
      return sessionStorage.getItem(ACTIVE_BUSINESS_KEY);
    } catch {
      return null;
    }
  }

  static setActiveBusinessId(id: string | null) {
    if (typeof window === "undefined") return;
    try {
      if (id) {
        sessionStorage.setItem(ACTIVE_BUSINESS_KEY, id);
      } else {
        sessionStorage.removeItem(ACTIVE_BUSINESS_KEY);
      }
    } catch {
      // ignore storage errors
    }
  }

  static getAccessToken(): string | null {
    if (typeof window === "undefined") return null;
    purgeLegacyLocalStorageTokens();
    return inMemoryAccessToken;
  }

  static getCsrfToken(): string | null {
    if (typeof window === "undefined") return null;
    return readCookie(CSRF_COOKIE_NAME) || inMemoryCsrfToken;
  }

  static hasSessionHint(): boolean {
    if (typeof window === "undefined") return false;
    return Boolean(inMemoryAccessToken || readCookie(CSRF_COOKIE_NAME));
  }

  static getUser(): UserDto | null {
    if (typeof window === "undefined") return null;
    purgeLegacyLocalStorageTokens();
    try {
      const raw = sessionStorage.getItem(USER_SESSION_KEY);
      if (!raw) return null;
      return JSON.parse(raw) as UserDto;
    } catch {
      return null;
    }
  }

  static updateUser(updates: Partial<UserDto>) {
    if (typeof window === "undefined") return;
    const user = this.getUser();
    if (!user) return;
    const updated = { ...user, ...updates };
    try {
      sessionStorage.setItem(USER_SESSION_KEY, JSON.stringify(updated));
    } catch {
      // ignore
    }
    window.dispatchEvent(new CustomEvent("afab_profile_updated", { detail: updated }));
  }

  static isAuthenticated(): boolean {
    return Boolean(this.getAccessToken() || this.hasSessionHint());
  }
}
