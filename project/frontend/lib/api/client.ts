import { AuthStore } from "@/lib/auth-store";

/**
 * Dynamically resolves the backend API base URL:
 * 1. Honors explicit NEXT_PUBLIC_API_URL environment variable if set.
 * 2. In browser environments:
 *    - If accessed over LAN/Wi-Fi (e.g. 192.168.x.x, 10.x.x.x), targets port 8080 on that same host IP.
 *    - On local machine, prioritizes 127.0.0.1 over localhost to prevent Windows WSL2 / wslrelay IPv6 [::1] connection drops.
 * 3. In server environments (SSR), defaults to 127.0.0.1:8080.
 */
export function getApiBaseUrl(): string {
  if (process.env.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  if (typeof window !== "undefined") {
    const { protocol, hostname } = window.location;
    if (hostname) {
      return `${protocol}//${hostname}:8080/api/v1`;
    }
  }
  return "http://localhost:8080/api/v1";
}

const API_BASE_URL = getApiBaseUrl();

interface FetchOptions extends RequestInit {
  requireAuth?: boolean;
}

/**
 * Structured error from the backend API.
 * Carries the error code for frontend-specific handling.
 */
export class ApiError extends Error {
  code: string;
  status: number;
  details?: Record<string, unknown>;

  constructor(message: string, code: string, status: number, details?: Record<string, unknown>) {
    super(message);
    this.name = "ApiError";
    this.code = code;
    this.status = status;
    this.details = details;
  }
}

// Single-flight deduplication so parallel requests on page reload share one token refresh
let inFlightRefresh: Promise<boolean> | null = null;

export async function tryRefreshToken(): Promise<boolean> {
  if (inFlightRefresh) {
    return inFlightRefresh;
  }

  inFlightRefresh = (async () => {
    const csrfToken = AuthStore.getCsrfToken();
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (csrfToken) {
      headers["X-CSRF-Token"] = csrfToken;
    }

    try {
      const baseUrl = getApiBaseUrl();
      const res = await fetch(`${baseUrl}/auth/refresh`, {
        method: "POST",
        credentials: "include",
        headers,
      });

      if (!res.ok) return false;

      const data = await res.json();
      if (data?.accessToken) {
        AuthStore.setAccessToken(data.accessToken, data.csrfToken);
        if (data.user) {
          AuthStore.setAuth(data);
        }
        return true;
      }
    } catch {
      // refresh attempt failed
    }
    return false;
  })();

  try {
    return await inFlightRefresh;
  } finally {
    inFlightRefresh = null;
  }
}

function buildAuthHeaders(
  baseHeaders?: HeadersInit,
  includeJsonContentType: boolean = true
): Record<string, string> {
  const merged: Record<string, string> = {};
  if (includeJsonContentType) {
    merged["Content-Type"] = "application/json";
  }

  if (baseHeaders) {
    if (baseHeaders instanceof Headers) {
      baseHeaders.forEach((value, key) => {
        merged[key] = value;
      });
    } else if (Array.isArray(baseHeaders)) {
      for (const [key, value] of baseHeaders) {
        merged[key] = value;
      }
    } else {
      Object.assign(merged, baseHeaders);
    }
  }

  const token = AuthStore.getAccessToken();
  if (token) {
    merged["Authorization"] = `Bearer ${token}`;
  }

  const activeBusinessId = AuthStore.getActiveBusinessId();
  if (activeBusinessId) {
    merged["X-Business-Id"] = activeBusinessId;
  }

  const csrfToken = AuthStore.getCsrfToken();
  if (csrfToken) {
    merged["X-CSRF-Token"] = csrfToken;
  }

  return merged;
}

let redirectingToLogin = false;

function redirectToLogin(): boolean {
  AuthStore.clearAuth();
  if (typeof window !== "undefined") {
    const path = window.location.pathname;
    if (path.endsWith("/login") || path.endsWith("/signup")) {
      return false;
    }
    if (!redirectingToLogin) {
      redirectingToLogin = true;
      const currentLang = path.split("/")[1] || "en";
      window.location.href = `/${currentLang}/login`;
    }
    return true;
  }
  return false;
}

export async function fetchRawClient(endpoint: string, options: FetchOptions = {}): Promise<Response> {
  const { requireAuth = true, headers, body, ...customConfig } = options;
  const isFormData = typeof FormData !== "undefined" && body instanceof FormData;

  // After a hard page reload, in-memory accessToken is null — silently refresh via HttpOnly cookie first.
  if (requireAuth && !AuthStore.getAccessToken() && !endpoint.includes("/auth/")) {
    const refreshed = await tryRefreshToken();
    if (!refreshed && !AuthStore.getAccessToken()) {
      if (redirectToLogin()) {
        return new Promise<Response>(() => {});
      }
      throw new ApiError("Authentication required. Please sign in again.", "UNAUTHORIZED", 401);
    }
  }

  const buildConfig = (): RequestInit => ({
    ...customConfig,
    body,
    credentials: "include",
    headers: requireAuth
      ? buildAuthHeaders(headers, !isFormData)
      : (() => {
          const h: Record<string, string> = isFormData ? {} : { "Content-Type": "application/json" };
          const csrfToken = AuthStore.getCsrfToken();
          if (csrfToken) h["X-CSRF-Token"] = csrfToken;
          if (headers && !(headers instanceof Headers) && !Array.isArray(headers)) {
            Object.assign(h, headers);
          }
          return h;
        })(),
  });

  const method = (customConfig.method || "GET").toUpperCase();

  let response: Response;
  const primaryBase = getApiBaseUrl();
  const secondaryBase = primaryBase.includes("127.0.0.1")
    ? primaryBase.replace("127.0.0.1", "localhost")
    : primaryBase.includes("localhost")
    ? primaryBase.replace("localhost", "127.0.0.1")
    : primaryBase;

  try {
    response = await fetch(`${primaryBase}${endpoint}`, buildConfig());
  } catch (err: unknown) {
    if (customConfig.signal?.aborted || (err instanceof Error && err.name === "AbortError")) {
      throw err;
    }
    // Attempt 2: quick retry after 200ms using secondary host resolution
    await new Promise((resolve) => setTimeout(resolve, 200));
    try {
      response = await fetch(`${secondaryBase}${endpoint}`, buildConfig());
    } catch (secondErr: unknown) {
      if (customConfig.signal?.aborted || (secondErr instanceof Error && secondErr.name === "AbortError")) {
        throw secondErr;
      }
      // Attempt 3: retry after 500ms using primary host resolution
      await new Promise((resolve) => setTimeout(resolve, 500));
      try {
        response = await fetch(`${primaryBase}${endpoint}`, buildConfig());
      } catch (retryErr: unknown) {
        if (customConfig.signal?.aborted || (retryErr instanceof Error && retryErr.name === "AbortError")) {
          throw retryErr;
        }
        throw new ApiError(
          "Unable to connect to the server. Please try again.",
          "NETWORK_ERROR",
          0
        );
      }
    }
  }

  if (response.status === 401 && requireAuth && !endpoint.includes("/auth/")) {
    const refreshed = await tryRefreshToken();
    if (refreshed) {
      try {
        const refreshedBase = getApiBaseUrl();
        response = await fetch(`${refreshedBase}${endpoint}`, buildConfig());
      } catch {
        throw new ApiError(
          "Unable to connect to the server. Please try again.",
          "NETWORK_ERROR",
          0
        );
      }
    }
  }

  return response;
}

export async function fetchClient(endpoint: string, options: FetchOptions = {}) {
  const { requireAuth = true } = options;
  const response = await fetchRawClient(endpoint, options);

  if (!response.ok) {
    let errorCode = "UNKNOWN_ERROR";
    let errorMsg = "Something went wrong. Please try again later.";
    let errorDetails: Record<string, unknown> | undefined = undefined;

    try {
      const errorText = await response.text();
      try {
        const parsed = JSON.parse(errorText) as Record<string, unknown>;
        errorDetails = parsed;
        if (typeof parsed.code === "string") {
          errorCode = parsed.code;
        }
        if (typeof parsed.message === "string") {
          errorMsg = parsed.message;
        } else if (typeof parsed.error === "string") {
          errorMsg = parsed.error;
        }
      } catch {
        if (errorText) {
          errorMsg = errorText;
        }
      }
    } catch {
      // keep default message
    }

    if (response.status === 403 && errorCode === "PLAN_LIMIT_REACHED") {
      if (typeof window !== "undefined") {
        window.dispatchEvent(
          new CustomEvent("afab:plan-limit-reached", {
            detail: {
              feature: errorDetails?.feature,
              limit: errorDetails?.limit,
              used: errorDetails?.used,
              upgradeTo: errorDetails?.upgradeTo,
              message: errorMsg,
            },
          })
        );
      }
      throw new ApiError(errorMsg, errorCode, response.status, errorDetails);
    }

    if (response.status === 403 && errorCode === "BUSINESS_READ_ONLY") {
      if (typeof window !== "undefined") {
        const currentBizId = AuthStore.getActiveBusinessId();
        if (currentBizId && (!errorDetails?.businessId || errorDetails.businessId === currentBizId)) {
          AuthStore.setActiveBusinessId(null);
        }
        window.dispatchEvent(
          new CustomEvent("afab:business-read-only", {
            detail: {
              businessId: errorDetails?.businessId,
              businessName: errorDetails?.businessName,
              message: errorMsg,
            },
          })
        );
      }
      throw new ApiError(errorMsg, errorCode, response.status, errorDetails);
    }

    if (response.status === 401 && requireAuth) {
      if (redirectToLogin()) {
        return new Promise(() => {});
      }
    }

    throw new ApiError(errorMsg, errorCode, response.status, errorDetails);
  }

  if (response.status === 204) {
    return null;
  }

  const responseText = await response.text();
  if (!responseText) {
    return null;
  }

  return JSON.parse(responseText);
}
