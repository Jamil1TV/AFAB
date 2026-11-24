/**
 * AFAB Enterprise — Wet Signature Management & Multi-Signature Registry
 * Supports storing multiple wet signatures, choosing an active signature,
 * editing signatory details, deleting, live canvas drawing, and automatic paper background removal.
 */

export interface WetSignatureData {
  dataUrl: string | null;
  signatoryName: string;
  signatoryTitle: string;
  updatedAt?: string;
  enabled: boolean;
}

export interface StoredSignatureItem {
  id: string;
  label: string;
  dataUrl: string;
  signatoryName: string;
  signatoryTitle: string;
  isDefault: boolean;
  createdAt: string;
  updatedAt?: string;
}

export interface SignatureRegistry {
  activeId: string | null;
  signatures: StoredSignatureItem[];
  autoApply: boolean;
}

const STORAGE_KEY_PREFIX = "afab_wet_signature";
const REGISTRY_KEY_SUFFIX = "_registry";

/**
 * Retrieves the full multi-signature registry with backward-compatible migration.
 */
export function getSignatureRegistry(businessId?: string): SignatureRegistry {
  if (typeof window === "undefined") {
    return { activeId: null, signatures: [], autoApply: true };
  }

  try {
    const regKey = businessId
      ? `${STORAGE_KEY_PREFIX}${REGISTRY_KEY_SUFFIX}_${businessId}`
      : `${STORAGE_KEY_PREFIX}${REGISTRY_KEY_SUFFIX}`;
    const raw = localStorage.getItem(regKey) || localStorage.getItem(`${STORAGE_KEY_PREFIX}${REGISTRY_KEY_SUFFIX}`);

    if (raw) {
      const parsed: SignatureRegistry = JSON.parse(raw);
      if (parsed && Array.isArray(parsed.signatures)) {
        return parsed;
      }
    }

    // Auto-migrate single legacy signature if present
    const legacyKey = businessId ? `${STORAGE_KEY_PREFIX}_${businessId}` : STORAGE_KEY_PREFIX;
    const legacyRaw = localStorage.getItem(legacyKey) || localStorage.getItem(STORAGE_KEY_PREFIX);
    if (legacyRaw) {
      const legacy: WetSignatureData = JSON.parse(legacyRaw);
      if (legacy && legacy.dataUrl) {
        const migratedItem: StoredSignatureItem = {
          id: `sig_${Date.now()}`,
          label: "Primary Signature",
          dataUrl: legacy.dataUrl,
          signatoryName: legacy.signatoryName || "Authorized Signatory",
          signatoryTitle: legacy.signatoryTitle || "Executive Management",
          isDefault: true,
          createdAt: legacy.updatedAt || new Date().toISOString(),
          updatedAt: legacy.updatedAt || new Date().toISOString(),
        };
        const migratedRegistry: SignatureRegistry = {
          activeId: migratedItem.id,
          signatures: [migratedItem],
          autoApply: legacy.enabled !== false,
        };
        saveSignatureRegistry(migratedRegistry, businessId);
        return migratedRegistry;
      }
    }

    return { activeId: null, signatures: [], autoApply: true };
  } catch (e) {
    console.warn("Could not retrieve signature registry:", e);
    return { activeId: null, signatures: [], autoApply: true };
  }
}

/**
 * Persists the signature registry and synchronizes the active signature for legacy readers.
 */
export function saveSignatureRegistry(registry: SignatureRegistry, businessId?: string): void {
  if (typeof window === "undefined") return;

  try {
    const regKey = businessId
      ? `${STORAGE_KEY_PREFIX}${REGISTRY_KEY_SUFFIX}_${businessId}`
      : `${STORAGE_KEY_PREFIX}${REGISTRY_KEY_SUFFIX}`;
    const serialized = JSON.stringify(registry);

    if (businessId) {
      localStorage.setItem(regKey, serialized);
    }
    localStorage.setItem(`${STORAGE_KEY_PREFIX}${REGISTRY_KEY_SUFFIX}`, serialized);

    // Sync active signature into legacy key for instant cross-compatibility
    const active = registry.signatures.find(
      (s) => s.id === registry.activeId || s.isDefault
    ) || registry.signatures[0];

    if (active) {
      const legacyPayload: WetSignatureData = {
        dataUrl: active.dataUrl,
        signatoryName: active.signatoryName,
        signatoryTitle: active.signatoryTitle,
        updatedAt: active.updatedAt || new Date().toISOString(),
        enabled: registry.autoApply,
      };
      const legacySerialized = JSON.stringify(legacyPayload);
      if (businessId) {
        localStorage.setItem(`${STORAGE_KEY_PREFIX}_${businessId}`, legacySerialized);
      }
      localStorage.setItem(STORAGE_KEY_PREFIX, legacySerialized);
      window.dispatchEvent(new CustomEvent("afab-signature-updated", { detail: legacyPayload }));
    } else {
      if (businessId) {
        localStorage.removeItem(`${STORAGE_KEY_PREFIX}_${businessId}`);
      }
      localStorage.removeItem(STORAGE_KEY_PREFIX);
      window.dispatchEvent(new CustomEvent("afab-signature-updated", { detail: null }));
    }
  } catch (e) {
    console.error("Failed to save signature registry:", e);
    throw e;
  }
}

/**
 * Returns all saved signatures for the current business.
 */
export function getAllSignatures(businessId?: string): StoredSignatureItem[] {
  return getSignatureRegistry(businessId).signatures;
}

/**
 * Returns the currently active signature.
 */
export function getActiveSignature(businessId?: string): StoredSignatureItem | null {
  const reg = getSignatureRegistry(businessId);
  if (!reg.signatures.length) return null;
  return reg.signatures.find((s) => s.id === reg.activeId || s.isDefault) || reg.signatures[0];
}

/**
 * Sets one signature as the active default signature.
 */
export function setActiveSignature(id: string, businessId?: string): void {
  const reg = getSignatureRegistry(businessId);
  reg.activeId = id;
  reg.signatures = reg.signatures.map((s) => ({
    ...s,
    isDefault: s.id === id,
  }));
  saveSignatureRegistry(reg, businessId);
}

/**
 * Creates or updates a signature item.
 */
export function saveSignatureItem(
  item: {
    id?: string;
    label?: string;
    dataUrl: string;
    signatoryName: string;
    signatoryTitle: string;
    isDefault?: boolean;
  },
  businessId?: string
): StoredSignatureItem {
  const reg = getSignatureRegistry(businessId);
  const now = new Date().toISOString();

  let savedItem: StoredSignatureItem;

  if (item.id) {
    // Edit existing signature
    const existingIndex = reg.signatures.findIndex((s) => s.id === item.id);
    if (existingIndex >= 0) {
      savedItem = {
        ...reg.signatures[existingIndex],
        label: item.label?.trim() || reg.signatures[existingIndex].label,
        dataUrl: item.dataUrl || reg.signatures[existingIndex].dataUrl,
        signatoryName: item.signatoryName.trim() || reg.signatures[existingIndex].signatoryName,
        signatoryTitle: item.signatoryTitle.trim() || reg.signatures[existingIndex].signatoryTitle,
        updatedAt: now,
      };
      reg.signatures[existingIndex] = savedItem;
    } else {
      savedItem = {
        id: item.id,
        label: item.label?.trim() || `Signature ${reg.signatures.length + 1}`,
        dataUrl: item.dataUrl,
        signatoryName: item.signatoryName.trim() || "Authorized Signatory",
        signatoryTitle: item.signatoryTitle.trim() || "Executive Management",
        isDefault: reg.signatures.length === 0 || !!item.isDefault,
        createdAt: now,
        updatedAt: now,
      };
      reg.signatures.push(savedItem);
    }
  } else {
    // Create new signature
    const isFirst = reg.signatures.length === 0;
    savedItem = {
      id: `sig_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      label: item.label?.trim() || `Signature ${reg.signatures.length + 1}`,
      dataUrl: item.dataUrl,
      signatoryName: item.signatoryName.trim() || "Authorized Signatory",
      signatoryTitle: item.signatoryTitle.trim() || "Executive Management",
      isDefault: isFirst || !!item.isDefault,
      createdAt: now,
      updatedAt: now,
    };
    reg.signatures.push(savedItem);
  }

  if (savedItem.isDefault || !reg.activeId) {
    reg.activeId = savedItem.id;
    reg.signatures = reg.signatures.map((s) => ({
      ...s,
      isDefault: s.id === savedItem.id,
    }));
  }

  saveSignatureRegistry(reg, businessId);
  return savedItem;
}

/**
 * Deletes a signature item. If it was active, sets another signature as active.
 */
export function deleteSignatureItem(id: string, businessId?: string): void {
  const reg = getSignatureRegistry(businessId);
  const updatedList = reg.signatures.filter((s) => s.id !== id);
  reg.signatures = updatedList;

  if (reg.activeId === id) {
    if (updatedList.length > 0) {
      reg.activeId = updatedList[0].id;
      updatedList[0].isDefault = true;
    } else {
      reg.activeId = null;
    }
  }

  saveSignatureRegistry(reg, businessId);
}

/**
 * Updates the global auto-apply preference.
 */
export function setSignatureAutoApply(enabled: boolean, businessId?: string): void {
  const reg = getSignatureRegistry(businessId);
  reg.autoApply = enabled;
  saveSignatureRegistry(reg, businessId);
}

/**
 * Backward-compatible accessor: returns the currently active wet signature data.
 */
export function getWetSignature(businessId?: string): WetSignatureData | null {
  const active = getActiveSignature(businessId);
  if (!active || !active.dataUrl) return null;
  const reg = getSignatureRegistry(businessId);

  return {
    dataUrl: active.dataUrl,
    signatoryName: active.signatoryName || "Authorized Signatory",
    signatoryTitle: active.signatoryTitle || "Executive Management",
    updatedAt: active.updatedAt || active.createdAt,
    enabled: reg.autoApply,
  };
}

/**
 * Backward-compatible setter: saves the signature into the registry as the active signature.
 */
export function saveWetSignature(data: WetSignatureData, businessId?: string): void {
  if (!data.dataUrl) return;
  saveSignatureItem(
    {
      dataUrl: data.dataUrl,
      signatoryName: data.signatoryName,
      signatoryTitle: data.signatoryTitle,
      isDefault: true,
      label: "Primary Signature",
    },
    businessId
  );
  if (data.enabled !== undefined) {
    setSignatureAutoApply(data.enabled, businessId);
  }
}

/**
 * Backward-compatible remover: deletes all signatures or the active one.
 */
export function removeWetSignature(businessId?: string): void {
  const active = getActiveSignature(businessId);
  if (active) {
    deleteSignatureItem(active.id, businessId);
  }
}

/**
 * Processes an uploaded image (PNG or JPEG) and converts white/light paper background
 * into transparent alpha so the ink looks authentic on any invoice or document.
 */
export function processSignatureFile(
  file: File,
  makeTransparent: boolean = true
): Promise<string> {
  return new Promise((resolve, reject) => {
    if (!file.type.startsWith("image/")) {
      reject(new Error("Please upload a valid PNG or JPEG image file."));
      return;
    }

    const reader = new FileReader();
    reader.onerror = () => reject(new Error("Failed to read file."));
    reader.onload = (e) => {
      const result = e.target?.result as string;
      if (!result) {
        reject(new Error("Empty image file."));
        return;
      }

      if (!makeTransparent) {
        resolve(result);
        return;
      }

      // Convert white paper background to transparent
      const img = new Image();
      img.onload = () => {
        try {
          const maxDim = 800;
          let { width, height } = img;
          if (width > maxDim || height > maxDim) {
            if (width > height) {
              height = Math.round((height * maxDim) / width);
              width = maxDim;
            } else {
              width = Math.round((width * maxDim) / height);
              height = maxDim;
            }
          }

          const canvas = document.createElement("canvas");
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext("2d", { willReadFrequently: true });
          if (!ctx) {
            resolve(result);
            return;
          }

          ctx.drawImage(img, 0, 0, width, height);
          const imgData = ctx.getImageData(0, 0, width, height);
          const data = imgData.data;

          // Replace near-white pixels (> 215 in RGB) with transparent alpha
          for (let i = 0; i < data.length; i += 4) {
            const r = data[i];
            const g = data[i + 1];
            const b = data[i + 2];
            const brightness = (r + g + b) / 3;

            if (brightness > 215) {
              const alpha = Math.max(0, 255 - (brightness - 215) * 8);
              data[i + 3] = alpha;
            } else {
              // Deepen dark ink slightly for rich clarity
              data[i] = Math.max(0, r - 20);
              data[i + 1] = Math.max(0, g - 20);
              data[i + 2] = Math.max(0, b - 15);
            }
          }

          ctx.putImageData(imgData, 0, 0);
          resolve(canvas.toDataURL("image/png"));
        } catch {
          resolve(result);
        }
      };
      img.onerror = () => resolve(result);
      img.src = result;
    };
    reader.readAsDataURL(file);
  });
}
