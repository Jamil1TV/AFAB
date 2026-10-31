import { fetchClient } from "./client";

export interface SubscriptionSnapshot {
  planId: string;
  planName: string;
  planSlug: "free" | "plus" | "pro";
  priceMonthly: number;
  priceYearly: number;
  currency: string;
  status: "ACTIVE" | "TRIALING" | "PAST_DUE" | "CANCELED" | "EXPIRED";
  isTrial: boolean;
  trialDaysRemaining?: number;
  periodStart?: string;
  periodEnd?: string;
  trialEnd?: string;
  entitlements: Record<string, any>;
  usage: Record<string, number>;
}

export class SubscriptionService {
  /**
   * Fetch current user's active plan, limits, and real-time usage counters.
   */
  static async getMySubscription(): Promise<SubscriptionSnapshot> {
    return fetchClient("/subscription/me");
  }

  /**
   * Activate a 7-day free trial on Plus or Pro plan.
   */
  static async activateTrial(planSlug: string): Promise<SubscriptionSnapshot> {
    return fetchClient("/subscription/trial", {
      method: "POST",
      body: JSON.stringify({ planSlug }),
    });
  }

  /**
   * Switch plan (Free, Plus, Pro) for developer/testing environments.
   */
  static async switchPlan(planSlug: string): Promise<SubscriptionSnapshot> {
    return fetchClient("/subscription/switch", {
      method: "POST",
      body: JSON.stringify({ planSlug }),
    });
  }
}
