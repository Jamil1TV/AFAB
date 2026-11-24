"use client";

import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";

// Suppress the React 19 script tag warning in development (guarded once across HMR)
// next-themes uses a script tag to prevent FOUC, which React 19 warns against.
if (
  typeof window !== "undefined" &&
  process.env.NODE_ENV === "development" &&
  !(window as unknown as { __afabConsoleErrorGuarded?: boolean }).__afabConsoleErrorGuarded
) {
  (window as unknown as { __afabConsoleErrorGuarded?: boolean }).__afabConsoleErrorGuarded = true;
  const orig = console.error;
  console.error = (...args: unknown[]) => {
    if (typeof args[0] === "string" && args[0].includes("Encountered a script tag")) {
      return;
    }
    orig.apply(console, args);
  };
}

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>;
}
