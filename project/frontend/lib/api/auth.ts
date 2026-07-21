const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1/auth";

export class AuthService {
  static async register(data: any) {
    const response = await fetch(`${API_URL}/register`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(errorText || "Registration failed");
    }

    const dataResp = await response.json();
    if (typeof window !== "undefined" && dataResp.accessToken) {
      localStorage.setItem("accessToken", dataResp.accessToken);
      document.cookie = `accessToken=${dataResp.accessToken}; path=/; max-age=86400; SameSite=Lax`;
      
      // Optional: store refresh token if present
      if (dataResp.refreshToken) {
        localStorage.setItem("refreshToken", dataResp.refreshToken);
        document.cookie = `refreshToken=${dataResp.refreshToken}; path=/; max-age=604800; SameSite=Lax`;
      }
    }

    return dataResp;
  }

  static async login(data: any) {
    const response = await fetch(`${API_URL}/login`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(errorText || "Login failed");
    }

    const dataResp = await response.json();
    if (typeof window !== "undefined" && dataResp.accessToken) {
      localStorage.setItem("accessToken", dataResp.accessToken);
      document.cookie = `accessToken=${dataResp.accessToken}; path=/; max-age=86400; SameSite=Lax`;
      
      // Optional: store refresh token if present
      if (dataResp.refreshToken) {
        localStorage.setItem("refreshToken", dataResp.refreshToken);
        document.cookie = `refreshToken=${dataResp.refreshToken}; path=/; max-age=604800; SameSite=Lax`;
      }
    }

    return dataResp;
  }
}
