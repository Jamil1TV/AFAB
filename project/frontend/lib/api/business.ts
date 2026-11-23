import { fetchClient } from "./client";
import { AuthStore } from "@/lib/auth-store";

export interface UpdateBusinessPayload {
  name?: string;
  country?: string;
  currency?: string;
  timezone?: string;
  fiscalYearStartMonth?: number;
  industry?: string;
  businessType?: string;
  businessEmail?: string;
  phoneNumber?: string;
  website?: string;
  taxId?: string;
  addressLine?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  description?: string;
  logoUrl?: string;
  dateFormat?: string;
  numberFormat?: string;
}

export interface CreateBusinessPayload {
  name: string;
  currency: string;
  country?: string;
  timezone?: string;
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
  logoUrl?: string;
  status: string;
  userRole?: string;
  active?: boolean;
  accessMode?: "EDITABLE" | "READ_ONLY";
  editable?: boolean;
  primary?: boolean;
  onboardingComplete: boolean;
  createdAt?: string;
}

export interface BusinessAllocationItem {
  id: string;
  name: string;
  currency: string;
  industry?: string;
  country?: string;
  logoUrl?: string;
  accessMode: "EDITABLE" | "READ_ONLY";
  editable: boolean;
  primary: boolean;
  active: boolean;
  selectedForPending: boolean;
  createdAt?: string;
}

export interface BusinessAllocationSummary {
  currentPlanSlug: "free" | "plus" | "pro";
  currentPlanName: string;
  editableLimit: number;
  editableCount: number;
  readOnlyCount: number;
  totalOwnedCount: number;
  allocationAttentionRequired: boolean;
  pendingPlanSlug?: "free" | "plus" | "pro" | null;
  pendingPlanName?: string | null;
  pendingEditableLimit?: number | null;
  pendingChangeEffectiveAt?: string | null;
  pendingBusinessIds: string[];
  businesses: BusinessAllocationItem[];
}

export class BusinessService {
  /**
   * List all businesses the current user belongs to
   */
  static async list(): Promise<BusinessData[]> {
    return fetchClient("/business");
  }

  /**
   * Get the active business in current context
   */
  static async getMine(): Promise<BusinessData> {
    return fetchClient("/business/mine");
  }

  /**
   * Create a new business / workspace
   */
  static async create(payload: CreateBusinessPayload): Promise<BusinessData> {
    const created = await fetchClient("/business", {
      method: "POST",
      body: JSON.stringify(payload),
    });
    if (created?.id) {
      AuthStore.setActiveBusinessId(created.id);
    }
    return created;
  }

  /**
   * Switch the active business context
   */
  static async switchActive(businessId: string): Promise<BusinessData> {
    const switched = await fetchClient(`/business/${businessId}/switch`, {
      method: "PUT",
    });
    AuthStore.setActiveBusinessId(businessId);
    return switched;
  }

  /**
   * Get a specific business by ID
   */
  static async get(businessId: string): Promise<BusinessData> {
    return fetchClient(`/business/${businessId}`);
  }

  /**
   * Update business details
   */
  static async update(businessId: string, payload: UpdateBusinessPayload): Promise<BusinessData> {
    const updated = await fetchClient(`/business/${businessId}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
    if (updated?.onboardingComplete) {
      AuthStore.updateUser({ onboardingComplete: true });
    }
    return updated;
  }

  /**
   * Archive / soft-delete a business
   */
  static async archive(businessId: string): Promise<void> {
    await fetchClient(`/business/${businessId}`, {
      method: "DELETE",
    });
    if (AuthStore.getActiveBusinessId() === businessId) {
      AuthStore.setActiveBusinessId(null);
    }
  }

  /**
   * Get editable vs read-only business allocation summary & pending downgrade selection
   */
  static async getAllocations(): Promise<BusinessAllocationSummary> {
    return fetchClient("/business/allocations");
  }

  /**
   * Change which owned businesses are EDITABLE vs READ_ONLY under the active plan limit
   */
  static async updateAllocations(
    selectedBusinessIds: string[],
    primaryBusinessId?: string
  ): Promise<BusinessAllocationSummary> {
    return fetchClient("/business/allocations", {
      method: "PUT",
      body: JSON.stringify({ selectedBusinessIds, primaryBusinessId }),
    });
  }

  /**
   * Save or update pending editable business selection for a scheduled downgrade
   */
  static async savePendingAllocations(
    targetPlanSlug: "free" | "plus",
    selectedBusinessIds: string[]
  ): Promise<BusinessAllocationSummary> {
    return fetchClient("/business/allocations/pending", {
      method: "PUT",
      body: JSON.stringify({ targetPlanSlug, selectedBusinessIds }),
    });
  }
}
