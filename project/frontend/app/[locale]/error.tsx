"use client";

import { useEffect } from "react";
import { AlertTriangle, RefreshCw, RotateCcw } from "lucide-react";
import { isChunkLoadFailure, tryRecoverChunkError } from "@/components/ChunkErrorRecovery";

export default function LocaleErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    if (isChunkLoadFailure(error)) {
      tryRecoverChunkError();
    }
  }, [error]);

  return (
    <div className="flex min-h-[70vh] w-full items-center justify-center px-4 py-12">
      <div className="w-full max-w-md rounded-2xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-[#0c101c] p-6 text-center shadow-xl space-y-4">
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-amber-500/10 text-amber-500">
          <AlertTriangle className="h-6 w-6" />
        </div>
        <div className="space-y-1.5">
          <h2 className="text-lg font-bold text-gray-900 dark:text-white">
            Something went wrong loading this page
          </h2>
          <p className="text-xs leading-relaxed text-gray-500 dark:text-gray-400">
            {isChunkLoadFailure(error)
              ? "A fresh update or module chunk failed to load. Reloading restores the latest version."
              : error?.message || "An unexpected error occurred while rendering this view."}
          </p>
        </div>
        <div className="flex items-center justify-center gap-2.5 pt-2">
          <button
            type="button"
            onClick={() => reset()}
            className="afab-btn-secondary px-4 py-2 text-xs"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            <span>Try Again</span>
          </button>
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="afab-btn-primary px-4 py-2 text-xs"
          >
            <RefreshCw className="h-3.5 w-3.5" />
            <span>Reload Page</span>
          </button>
        </div>
      </div>
    </div>
  );
}
