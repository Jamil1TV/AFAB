"use client";

import { useEffect } from "react";

const RELOAD_COOLDOWN_MS = 15_000;
const STORAGE_KEY = "afab_chunk_recovery_ts";

export function isChunkLoadFailure(err: unknown): boolean {
  if (!err) return false;
  const name =
    typeof err === "object" && "name" in err ? String((err as { name?: unknown }).name ?? "") : "";
  const message =
    typeof err === "string"
      ? err
      : typeof err === "object" && "message" in err
      ? String((err as { message?: unknown }).message ?? "")
      : "";

  const combined = `${name} ${message}`;
  return (
    combined.includes("ChunkLoadError") ||
    combined.includes("Failed to load chunk") ||
    combined.includes("Loading chunk") ||
    combined.includes("Failed to fetch dynamically imported module")
  );
}

export function tryRecoverChunkError(): boolean {
  if (typeof window === "undefined") return false;
  try {
    const lastTs = Number(sessionStorage.getItem(STORAGE_KEY) || "0");
    const now = Date.now();
    if (now - lastTs < RELOAD_COOLDOWN_MS) {
      return false;
    }
    sessionStorage.setItem(STORAGE_KEY, String(now));
    window.location.reload();
    return true;
  } catch {
    return false;
  }
}

export function ChunkErrorRecovery() {
  useEffect(() => {
    const onError = (event: ErrorEvent) => {
      if (isChunkLoadFailure(event.error) || isChunkLoadFailure(event.message)) {
        tryRecoverChunkError();
      }
    };

    const onUnhandledRejection = (event: PromiseRejectionEvent) => {
      if (isChunkLoadFailure(event.reason)) {
        tryRecoverChunkError();
      }
    };

    window.addEventListener("error", onError);
    window.addEventListener("unhandledrejection", onUnhandledRejection);
    return () => {
      window.removeEventListener("error", onError);
      window.removeEventListener("unhandledrejection", onUnhandledRejection);
    };
  }, []);

  return null;
}
