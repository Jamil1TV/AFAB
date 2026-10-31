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
  details?: Record<string, any>;

  constructor(message: string, code: string, status: number, details?: Record<string, any>) {
    super(message);
    this.name = "ApiError";
    this.code = code;
    this.status = status;
    this.details = details;
  }
}

async function tryRefreshToken(): Promise<boolean> {
  const refreshToken = AuthStore.getRefreshToken();

  try {
    const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: refreshToken ? JSON.stringify({ refreshToken }) : undefined,
    });

    if (!res.ok) return false;

    const data = await res.json();
    if (data?.accessToken) {
      AuthStore.setAccessToken(data.accessToken);
      if (data.refreshToken) {
        AuthStore.setRefreshToken(data.refreshToken);
      }
      return true;
    }
  } catch {
    // refresh attempt failed
  }
  return false;
}

export async function fetchClient(endpoint: string, options: FetchOptions = {}) {
  const { requireAuth = true, headers, ...customConfig } = options;

  const config: RequestInit = {
    ...customConfig,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
  };

  if (requireAuth) {
    const token = AuthStore.getAccessToken();
    if (token) {
      config.headers = {
        ...config.headers,
        Authorization: `Bearer ${token}`,
      };
    }

    const activeBusinessId = AuthStore.getActiveBusinessId();
    if (activeBusinessId) {
      config.headers = {
        ...config.headers,
        "X-Business-Id": activeBusinessId,
      };
    }
  }

  let response: Response;

  try {
    response = await fetch(`${API_BASE_URL}${endpoint}`, config);
  } catch {
    // Network failure — server unreachable, DNS error, CORS, etc.
    throw new ApiError(
      "Unable to connect to the server. Please try again.",
      "NETWORK_ERROR",
      0
    );
  }

  if (!response.ok) {
    // Attempt transparent token refresh on 401 for authenticated endpoints (excluding auth routes)
    if (response.status === 401 && requireAuth && !endpoint.includes("/auth/")) {
      const refreshed = await tryRefreshToken();
      if (refreshed) {
        const newToken = AuthStore.getAccessToken();
        const retryConfig: RequestInit = {
          ...config,
          headers: {
            ...config.headers,
            Authorization: `Bearer ${newToken}`,
          },
        };
        try {
          response = await fetch(`${API_BASE_URL}${endpoint}`, retryConfig);
        } catch {
          throw new ApiError(
            "Unable to connect to the server. Please try again.",
            "NETWORK_ERROR",
            0
          );
        }
      }
    }

    if (!response.ok) {
      // Parse structured error response from backend first
      let errorCode = "UNKNOWN_ERROR";
      let errorMsg = "Something went wrong. Please try again later.";
      let errorDetails: Record<string, any> | undefined = undefined;

      try {
        const errorText = await response.text();
        try {
          const parsed = JSON.parse(errorText);
          errorDetails = parsed;
          if (parsed.code) {
            errorCode = parsed.code;
          }
          if (parsed.message) {
            errorMsg = parsed.message;
          } else if (parsed.error) {
            errorMsg = parsed.error;
          }
        } catch {
          if (errorText) {
            errorMsg = errorText;
          }
        }
      } catch {
        // fallback — keep default message
      }

      // Handle plan limit reached (403 Forbidden with PLAN_LIMIT_REACHED)
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

      // 401 Unauthorized: token expired or invalid, clear auth and redirect to login
      if (response.status === 401 && requireAuth) {
        AuthStore.clearAuth();
        if (typeof window !== "undefined") {
          const currentLang = window.location.pathname.split("/")[1] || "en";
          window.location.href = `/${currentLang}/login`;
          return new Promise(() => {});
        }
      }

      throw new ApiError(errorMsg, errorCode, response.status, errorDetails);
    }
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
