const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

interface FetchOptions extends RequestInit {
  requireAuth?: boolean;
}

export async function fetchClient(endpoint: string, options: FetchOptions = {}) {
  const { requireAuth = true, headers, ...customConfig } = options;

  const config: RequestInit = {
    ...customConfig,
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
  };

  if (requireAuth) {
    const token = typeof window !== "undefined" ? localStorage.getItem("accessToken") : null;
    if (token) {
      config.headers = {
        ...config.headers,
        Authorization: `Bearer ${token}`,
      };
    } else {
      // If we require auth and there's no token, we could throw an error early
      // throw new Error("No access token found");
    }
  }

  const response = await fetch(`${API_BASE_URL}${endpoint}`, config);

  if (!response.ok) {
    if (response.status === 401) {
      // Handle unauthorized (e.g., redirect to login, clear token)
      if (typeof window !== "undefined") {
        localStorage.removeItem("accessToken");
        window.location.href = "/login"; // Or wherever your login route is
      }
    }
    
    const errorText = await response.text();
    throw new Error(errorText || "API Request Failed");
  }

  // Handle empty responses
  if (response.status === 204) {
    return null;
  }

  return response.json();
}
