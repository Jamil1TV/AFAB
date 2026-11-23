import { AuthStore } from "@/lib/auth-store";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

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
      const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
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

function redirectToLogin() {
  AuthStore.clearAuth();
  if (typeof window !== "undefined") {
    const currentLang = window.location.pathname.split("/")[1] || "en";
    window.location.href = `/${currentLang}/login`;
  }
}

export async function fetchRawClient(endpoint: string, options: FetchOptions = {}): Promise<Response> {
  const { requireAuth = true, headers, body, ...customConfig } = options;
  const isFormData = typeof FormData !== "undefined" && body instanceof FormData;

  // After a hard page reload, in-memory accessToken is null — silently refresh via HttpOnly cookie first.
  if (requireAuth && !AuthStore.getAccessToken() && !endpoint.includes("/auth/")) {
    await tryRefreshToken();
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

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${endpoint}`, buildConfig());
  } catch {
    throw new ApiError(
      "Unable to connect to the server. Please try again.",
      "NETWORK_ERROR",
      0
    );
  }

  if (response.status === 401 && requireAuth && !endpoint.includes("/auth/")) {
    const refreshed = await tryRefreshToken();
    if (refreshed) {
      try {
        response = await fetch(`${API_BASE_URL}${endpoint}`, buildConfig());
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
      redirectToLogin();
      return new Promise(() => {});
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
