"use client";

import { useEffect } from "react";
import { useTheme } from "next-themes";
import { applyAppearance, getStoredAppearance } from "@/lib/appearance";

/**
 * Initializes and dynamically synchronizes appearance settings
 * (accent colors, font family, typography scale, border radius, and dark surface tones)
 * across every page and component in the application.
 */
export function AppearanceInitializer() {
  const { setTheme } = useTheme();

  useEffect(() => {
    // Synchronously apply appearance on initial client hydration without rebroadcasting
    applyAppearance(getStoredAppearance(), setTheme, { persist: false, broadcast: false });

    // React only to cross-tab storage updates
    const handleStorage = (e: StorageEvent) => {
      if (e.key === "afab_appearance_settings" && e.newValue) {
        try {
          const parsed = JSON.parse(e.newValue);
          applyAppearance(parsed, setTheme, { persist: false, broadcast: false });
        } catch {
          // ignore parsing error
        }
      }
    };

    window.addEventListener("storage", handleStorage);

    return () => {
      window.removeEventListener("storage", handleStorage);
    };
  }, [setTheme]);

  return null;
}
