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
    // 1. Synchronously apply appearance on initial client hydration
    const initialSettings = getStoredAppearance();
    applyAppearance(initialSettings, setTheme);

    // 2. React to in-app appearance mutations
    const handleAppearanceChanged = (e: Event) => {
      const customEvent = e as CustomEvent;
      if (customEvent.detail) {
        applyAppearance(customEvent.detail, setTheme);
      } else {
        applyAppearance(getStoredAppearance(), setTheme);
      }
    };

    // 3. React to multi-tab storage updates
    const handleStorage = (e: StorageEvent) => {
      if (e.key === "afab_appearance_settings" && e.newValue) {
        try {
          const parsed = JSON.parse(e.newValue);
          applyAppearance(parsed, setTheme);
        } catch {
          // ignore parsing error
        }
      }
    };

    window.addEventListener("afab_appearance_changed", handleAppearanceChanged);
    window.addEventListener("storage", handleStorage);

    return () => {
      window.removeEventListener("afab_appearance_changed", handleAppearanceChanged);
      window.removeEventListener("storage", handleStorage);
    };
  }, [setTheme]);

  return null;
}
