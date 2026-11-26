"use client";

import * as React from "react";
import { Moon, Sun } from "lucide-react";
import { useTheme } from "next-themes";

import { Button } from "@/components/ui/button";
import { APPEARANCE_STORAGE_KEY, getStoredAppearance } from "@/lib/appearance";

export function ThemeToggle() {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => setMounted(true), []);

  if (!mounted) {
    return (
      <Button
        type="button"
        variant="outline"
        size="icon"
        data-testid="theme-toggle-btn"
        className="h-9 w-9 rounded-full border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] text-gray-600 dark:text-gray-300"
        disabled
      >
        <Sun className="h-[1.1rem] w-[1.1rem]" />
        <span className="sr-only">Toggle theme</span>
      </Button>
    );
  }

  const isDark = resolvedTheme === "dark";

  const handleToggle = () => {
    const nextTheme = isDark ? "light" : "dark";
    setTheme(nextTheme);
    try {
      const updated = { ...getStoredAppearance(), themeMode: nextTheme } as const;
      localStorage.setItem(APPEARANCE_STORAGE_KEY, JSON.stringify(updated));
      window.dispatchEvent(new CustomEvent("afab_appearance_changed", { detail: updated }));
    } catch {
      // Ignore storage write errors
    }
  };

  return (
    <Button
      type="button"
      variant="outline"
      size="icon"
      data-testid="theme-toggle-btn"
      onClick={handleToggle}
      aria-label={isDark ? "Switch to light mode" : "Switch to dark mode"}
      title={isDark ? "Switch to light mode" : "Switch to dark mode"}
      className="h-9 w-9 rounded-full border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-white/[0.06] hover:text-gray-900 dark:hover:text-white transition-colors"
    >
      {isDark ? (
        <Sun className="h-[1.1rem] w-[1.1rem] transition-transform" />
      ) : (
        <Moon className="h-[1.1rem] w-[1.1rem] transition-transform" />
      )}
      <span className="sr-only">Toggle theme</span>
    </Button>
  );
}
