import { AuthStore } from "@/lib/auth-store";

/**
 * Dynamically resolves the backend API base URL:
 * 1. Honors explicit NEXT_PUBLIC_API_URL environment variable if set.
 * 2. In browser environments:
 *    - Always uses the same-origin relative path `/api/v1`.
 *    - Next.js server proxies `/api/v1/:path*` directly to `http://127.0.0.1:8080/api/v1/:path*` via rewrites.
 *    - Completely eliminates cross-origin preflight overhead (OPTIONS), CORS rejections,
 *      cookie domain isolation issues, and Windows WSL2/Docker IPv6 [::1] connection drops.
 * 3. In server environments (SSR), defaults to direct IPv4 `http://127.0.0.1:8080/api/v1`.
 */
export function getApiBaseUrl(): string {
  if (process.env.NEXT_PUBLIC_API_URL) {
    return process.env.NEXT_PUBLIC_API_URL;
  }
  if (typeof window !== "undefined") {
    return "/api/v1";
  }
  return "http://127.0.0.1:8080/api/v1";
}

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

// Single-flight deduplication so parallel requests share one token refresh or shared metadata GET
let inFlightRefresh: Promise<boolean> | null = null;
let redirectingToLogin = false;

const inFlightGets = new Map<string, Promise<unknown>>();
const responseCache = new Map<string, { data: unknown; expiresAt: number }>();

function buildCacheKey(endpoint: string): string {
  const userId = AuthStore.getUser()?.id || "anon";
  const businessId = AuthStore.getActiveBusinessId() || "default";
  return `${userId}::${businessId}::${endpoint}`;
}

/**
 * Clears cached responses and in-flight shared GET deduplication entries.
 * When `endpointPrefix` is omitted, wipes all cached API entries.
 */
export function invalidateApiCache(endpointPrefix?: string): void {
  if (!endpointPrefix) {
    responseCache.clear();
    inFlightGets.clear();
    return;
  }
  const needle = `::${endpointPrefix}`;
  for (const key of Array.from(responseCache.keys())) {
    if (key.includes(needle)) {
      responseCache.delete(key);
    }
  }
  for (const key of Array.from(inFlightGets.keys())) {
    if (key.includes(needle)) {
      inFlightGets.delete(key);
    }
  }
}

// Register cache invalidation listeners once across HMR in browser environments
if (typeof window !== "undefined") {
  const w = window as unknown as { __afabApiCacheListenersBound?: boolean };
  if (!w.__afabApiCacheListenersBound) {
    w.__afabApiCacheListenersBound = true;
    window.addEventListener("afab:auth-cleared", () => {
      invalidateApiCache();
    });
    window.addEventListener("afab:business-context-changed", () => {
      invalidateApiCache();
    });
    window.addEventListener("afab:subscription-updated", () => {
      invalidateApiCache("/subscription");
      invalidateApiCache("/business");
    });
    window.addEventListener("afab:business-read-only", () => {
      invalidateApiCache("/subscription");
      invalidateApiCache("/business");
    });
  }
}

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

    const baseUrl = getApiBaseUrl();
    let res: Response | null = null;

    for (let attempt = 0; attempt <= 1; attempt++) {
      try {
        res = await fetch(`${baseUrl}/auth/refresh`, {
          method: "POST",
          credentials: "include",
          headers,
        });
        break;
      } catch (refreshErr: unknown) {
        if (refreshErr instanceof Error && refreshErr.name === "AbortError") {
          return false;
        }
        if (attempt === 0) {
          await new Promise((resolve) => setTimeout(resolve, 300));
        } else {
          console.warn("[AFAB API] Silent token refresh network failure");
          return false;
        }
      }
    }

    if (!res) return false;

    if (!res.ok) {
      if (res.status === 401 || res.status === 403) {
        AuthStore.clearAuth();
      }
      return false;
    }

    try {
      const data = await res.json();
      if (data?.accessToken) {
        AuthStore.setAccessToken(data.accessToken, data.csrfToken);
        redirectingToLogin = false;
        if (data.user) {
          AuthStore.setAuth(data);
        }
        return true;
      }
    } catch {
      // malformed JSON from refresh endpoint
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

  if (AuthStore.getAccessToken()) {
    redirectingToLogin = false;
  }

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
  const baseUrl = getApiBaseUrl();

  const isSafeRetry = method === "GET" || method === "HEAD" || method === "OPTIONS";
  const maxRetries = isSafeRetry
    ? 2
    : typeof ReadableStream !== "undefined" && body instanceof ReadableStream
    ? 0
    : 1;

  let response: Response | null = null;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      response = await fetch(`${baseUrl}${endpoint}`, buildConfig());
      break;
    } catch (err: unknown) {
      if (customConfig.signal?.aborted || (err instanceof Error && err.name === "AbortError")) {
        throw err;
      }
      if (attempt < maxRetries) {
        const delayMs = attempt === 0 ? 250 : 600;
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      } else {
        console.warn(`[AFAB API] Network unreachable for ${method} ${endpoint}`);
        throw new ApiError(
          "Unable to connect to the server. Please try again.",
          "NETWORK_ERROR",
          0
        );
      }
    }
  }

  if (!response) {
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
        response = await fetch(`${baseUrl}${endpoint}`, buildConfig());
      } catch (err: unknown) {
        if (customConfig.signal?.aborted || (err instanceof Error && err.name === "AbortError")) {
          throw err;
        }
        console.warn(`[AFAB API] Retry after refresh failed for ${method} ${endpoint}`);
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
  const method = (options.method || "GET").toUpperCase();
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

  // Automatically invalidate related cached GET endpoints on successful mutations
  if (method !== "GET" && method !== "HEAD") {
    if (endpoint.startsWith("/user/me")) {
      invalidateApiCache("/user/me");
    } else if (endpoint.startsWith("/business")) {
      invalidateApiCache("/business");
      invalidateApiCache("/subscription");
    } else if (endpoint.startsWith("/billing") || endpoint.startsWith("/subscription")) {
      invalidateApiCache("/subscription");
      invalidateApiCache("/business");
    } else if (endpoint.startsWith("/notifications")) {
      invalidateApiCache("/notifications");
    } else if (endpoint.startsWith("/auth/logout") || endpoint.startsWith("/auth/login")) {
      invalidateApiCache();
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

/**
 * Single-flight deduplicated + short-TTL cached GET helper for shared metadata endpoints
 * (`/user/me`, `/subscription/me`, `/business`, `/business/mine`, `/notifications`).
 * Prevents simultaneous component mounts from hammering identical backend endpoints.
 */
export async function fetchCachedClient<T = any>(
  endpoint: string,
  options: FetchOptions & { ttlMs?: number; force?: boolean } = {}
): Promise<T> {
  const { ttlMs = 15_000, force = false, ...fetchOptions } = options;
  const key = buildCacheKey(endpoint);

  if (!force) {
    const cached = responseCache.get(key);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.data as T;
    }

    const existingFlight = inFlightGets.get(key);
    if (existingFlight) {
      return existingFlight as Promise<T>;
    }
  }

  const promise = (async () => {
    const data = await fetchClient(endpoint, fetchOptions);
    responseCache.set(key, {
      data,
      expiresAt: Date.now() + ttlMs,
    });
    return data as T;
  })();

  inFlightGets.set(key, promise);

  try {
    return await promise;
  } finally {
    if (inFlightGets.get(key) === promise) {
      inFlightGets.delete(key);
    }
  }
}
