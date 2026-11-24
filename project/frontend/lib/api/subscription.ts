import { fetchClient, fetchCachedClient } from "./client";

export interface SubscriptionSnapshot {
  planId: string;
  planName: string;
  planSlug: "free" | "plus" | "pro";
  priceMonthly: number;
  priceYearly: number;
  currency: string;
  status: "ACTIVE" | "TRIALING" | "PAST_DUE" | "CANCELED" | "EXPIRED";
  trial?: boolean;
  isTrial?: boolean;
  trialDaysRemaining?: number;
  trialStart?: string;
  trialEnd?: string;
  trialUsed?: boolean;
  trialEligible?: boolean;
  periodStart?: string;
  periodEnd?: string;
  billingInterval?: "MONTHLY" | "YEARLY" | null;
  cancelAtPeriodEnd?: boolean;
  canceledAt?: string;
  effectiveCancelAt?: string;
  pendingPlanSlug?: "free" | "plus" | "pro" | null;
  pendingPlanName?: string | null;
  pendingBillingInterval?: "MONTHLY" | "YEARLY" | null;
  pendingChangeEffectiveAt?: string | null;
  firstPaymentFailureAt?: string | null;
  gracePeriodEndsAt?: string | null;
  gracePeriodHoursRemaining?: number | null;
  lastPaymentFailureReason?: string | null;
  allocationAttentionRequired?: boolean;
  editableBusinessLimit?: number;
  editableBusinessCount?: number;
  totalBusinessCount?: number;
  hasStripeCustomer?: boolean;
  hasActiveStripeSubscription?: boolean;
  stripeConfigured?: boolean;
  entitlements: Record<string, any>;
  usage: Record<string, number>;
}

export interface CheckoutSessionResponse {
  sessionId: string | null;
  url: string;
  mode: "CHECKOUT" | "PORTAL";
}

export interface PortalSessionResponse {
  url: string;
}

export interface UpgradeSubscriptionResponse {
  mode: "DIRECT_UPGRADE" | "CHECKOUT" | "PORTAL";
  sessionId: string | null;
  url: string | null;
  snapshot: SubscriptionSnapshot | null;
}

export interface SubscriptionHistoryItem {
  id: string;
  eventType: string;
  fromPlanSlug?: string | null;
  toPlanSlug?: string | null;
  fromStatus?: string | null;
  toStatus?: string | null;
  effectiveAt?: string | null;
  details?: string | null;
  createdAt: string;
}

export interface PaymentHistoryItem {
  id: string;
  stripeInvoiceId: string;
  amountCents: number;
  currency: string;
  status: "PAID" | "FAILED" | "OPEN" | string;
  failureReason?: string | null;
  hostedInvoiceUrl?: string | null;
  invoicePdfUrl?: string | null;
  paidAt?: string | null;
  failedAt?: string | null;
  createdAt: string;
}

export interface BillingHistoryResponse {
  subscriptionHistory: SubscriptionHistoryItem[];
  paymentHistory: PaymentHistoryItem[];
}

export class SubscriptionService {
  /**
   * Fetch current user's active plan, lifecycle state, limits, and real-time usage counters.
   */
  static async getMySubscription(force: boolean = false): Promise<SubscriptionSnapshot> {
    return fetchCachedClient("/subscription/me", { ttlMs: 15_000, force });
  }

  /**
   * Start a Stripe Checkout session (or redirect to Customer Portal if already subscribed).
   */
  static async createCheckoutSession(
    planSlug: "plus" | "pro",
    billingInterval: "monthly" | "yearly",
    locale: string = "en",
    returnPath: string = "/dashboard/settings/subscription"
  ): Promise<CheckoutSessionResponse> {
    return fetchClient("/billing/checkout", {
      method: "POST",
      body: JSON.stringify({ planSlug, billingInterval, locale, returnPath }),
    });
  }

  /**
   * Create a Stripe Customer Portal session to manage cards, invoices, or billing profile.
   */
  static async createPortalSession(
    locale: string = "en",
    returnPath: string = "/dashboard/settings/subscription"
  ): Promise<PortalSessionResponse> {
    return fetchClient("/billing/portal", {
      method: "POST",
      body: JSON.stringify({ locale, returnPath }),
    });
  }

  /**
   * Verify and immediately synchronize a completed Stripe Checkout session after redirect back to AFAB.
   */
  static async verifyCheckoutSession(sessionId: string): Promise<SubscriptionSnapshot> {
    return fetchClient("/billing/checkout/verify", {
      method: "POST",
      body: JSON.stringify({ sessionId }),
    });
  }

  /**
   * Schedule subscription cancellation at end of current billing period or 7-day trial.
   */
  static async cancelSubscription(selectedBusinessIds?: string[]): Promise<SubscriptionSnapshot> {
    return fetchClient("/billing/cancel", {
      method: "POST",
      body: JSON.stringify({ selectedBusinessIds: selectedBusinessIds ?? [] }),
    });
  }

  /**
   * Reverse a scheduled cancellation or scheduled downgrade before the effective date.
   */
  static async resumeSubscription(): Promise<SubscriptionSnapshot> {
    return fetchClient("/billing/resume", {
      method: "POST",
    });
  }

  /**
   * Schedule a downgrade at period end (Pro -> Plus, Pro -> Free, Plus -> Free)
   * with selected editable businesses saved to pending_business_allocations.
   */
  static async scheduleDowngrade(
    targetPlanSlug: "free" | "plus",
    selectedBusinessIds: string[],
    billingInterval?: "monthly" | "yearly",
    deferAllocation: boolean = false
  ): Promise<SubscriptionSnapshot> {
    return fetchClient("/billing/downgrade", {
      method: "POST",
      body: JSON.stringify({
        targetPlanSlug,
        selectedBusinessIds,
        billingInterval,
        deferAllocation,
      }),
    });
  }

  /**
   * Upgrade subscription tier (direct prorated Stripe update if already subscribed, or Checkout if Free)
   * and automatically restore read-only businesses up to the new plan limit.
   */
  static async upgradeSubscription(
    planSlug: "plus" | "pro",
    billingInterval: "monthly" | "yearly",
    locale: string = "en",
    returnPath: string = "/dashboard/settings/subscription"
  ): Promise<UpgradeSubscriptionResponse> {
    return fetchClient("/billing/upgrade", {
      method: "POST",
      body: JSON.stringify({ planSlug, billingInterval, locale, returnPath }),
    });
  }

  /**
   * Fetch persisted subscription change history & Stripe invoice payment history.
   */
  static async getBillingHistory(): Promise<BillingHistoryResponse> {
    return fetchClient("/billing/history");
  }

  /**
   * Developer/local fallback when Stripe keys are not configured.
   */
  static async activateTrial(planSlug: string): Promise<SubscriptionSnapshot> {
    return fetchClient("/subscription/trial", {
      method: "POST",
      body: JSON.stringify({ planSlug }),
    });
  }

  /**
   * Developer/local fallback switch plan when Stripe keys are not configured.
   */
  static async switchPlan(planSlug: string): Promise<SubscriptionSnapshot> {
    return fetchClient("/subscription/switch", {
      method: "POST",
      body: JSON.stringify({ planSlug }),
    });
  }
}
