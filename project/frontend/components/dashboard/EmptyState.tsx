import type { ReactNode } from "react";
import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

interface EmptyStateProps {
  icon: LucideIcon;
  title: ReactNode;
  description?: ReactNode;
  action?: ReactNode;
  /** "danger" is used for error states (failed loads). */
  tone?: "neutral" | "danger";
  className?: string;
}

/**
 * AFAB empty / error state — same visual as the empty ledger state on
 * the Transactions reference page.
 */
export function EmptyState({ icon: Icon, title, description, action, tone = "neutral", className }: EmptyStateProps) {
  return (
    <div className={cn("flex flex-col items-center justify-center px-4 py-16 text-center", className)}>
      <div
        className={cn(
          "mb-4 flex h-14 w-14 items-center justify-center rounded-2xl",
          tone === "danger"
            ? "bg-red-50 text-red-500 dark:bg-red-500/10 dark:text-red-400"
            : "bg-gray-100 text-gray-400 dark:bg-white/5"
        )}
      >
        <Icon className="h-6 w-6" />
      </div>
      <h3 className="text-sm font-bold text-gray-900 dark:text-white">{title}</h3>
      {description && (
        <p className="mt-1 max-w-sm text-xs leading-relaxed text-gray-500 dark:text-gray-400">{description}</p>
      )}
      {action && <div className="mt-5">{action}</div>}
    </div>
  );
}
