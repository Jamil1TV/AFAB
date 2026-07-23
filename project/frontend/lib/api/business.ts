import { fetchClient } from "./client";
import { AuthStore } from "@/lib/auth-store";

export interface UpdateBusinessPayload {
  country: string;
  currency: string;
  timezone: string;
  fiscalYearStartMonth?: number;
  industry?: string;
  businessType?: string;
}

export interface BusinessData {
  id: string;
  name: string;
  country?: string;
  currency: string;
  timezone?: string;
  fiscalYearStartMonth: number;
  industry?: string;
  businessType?: string;
  status: string;
  onboardingComplete: boolean;
}

export class BusinessService {
  static async get(businessId: string): Promise<BusinessData> {
    return fetchClient(`/business/${businessId}`);
  }

  static async update(businessId: string, payload: UpdateBusinessPayload): Promise<BusinessData> {
    const updated = await fetchClient(`/business/${businessId}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
    if (updated.onboardingComplete) {
      AuthStore.updateUser({ onboardingComplete: true });
    }
    return updated;
  }
}
