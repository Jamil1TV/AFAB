import { AuthStore } from "@/lib/auth-store";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

interface FetchOptions extends RequestInit {
  requireAuth?: boolean;
}

async function tryRefreshToken(): Promise<boolean> {
  const refreshToken = AuthStore.getRefreshToken();
  if (!refreshToken) return false;

  try {
    const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken }),
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
    credentials: "omit",
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
  }

  let response = await fetch(`${API_BASE_URL}${endpoint}`, config);

  if (!response.ok) {
    // Attempt transparent token refresh on 401/403 for authenticated endpoints
    if ((response.status === 401 || response.status === 403) && requireAuth && !endpoint.includes("/auth/")) {
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
        response = await fetch(`${API_BASE_URL}${endpoint}`, retryConfig);
      }
    }

    if (!response.ok) {
      if ((response.status === 401 || response.status === 403) && requireAuth) {
        AuthStore.clearAuth();
        if (typeof window !== "undefined") {
          // Automatically redirect to login when token expires
          const currentLang = window.location.pathname.split('/')[1] || 'en';
          window.location.href = `/${currentLang}/login`;
          
          // Return a promise that never resolves so the app doesn't crash while navigating
          return new Promise(() => {});
        }
      }

      let errorMsg = "API Request Failed";
      try {
        const errorText = await response.text();
        // Parse JSON if possible
        try {
          const parsed = JSON.parse(errorText);
          errorMsg = parsed.message || parsed.error || errorText;
        } catch {
          errorMsg = errorText || errorMsg;
        }
      } catch {
        // fallback
      }

      throw new Error(errorMsg);
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
