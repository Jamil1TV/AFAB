import { AuthStore } from "@/lib/auth-store";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

interface FetchOptions extends RequestInit {
  requireAuth?: boolean;
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

  const response = await fetch(`${API_BASE_URL}${endpoint}`, config);

  if (!response.ok) {
    if (response.status === 401 && requireAuth) {
      AuthStore.clearAuth();
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

  if (response.status === 204) {
    return null;
  }

  const responseText = await response.text();
  if (!responseText) {
    return null;
  }

  return JSON.parse(responseText);
}
