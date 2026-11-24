import type { ReactNode } from "react";
import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export type StatTone = "neutral" | "primary" | "success" | "danger" | "warning" | "info";

const toneIcon: Record<StatTone, string> = {
  neutral: "bg-gray-50 text-gray-500 dark:bg-white/[0.03] dark:text-gray-400 group-hover:bg-[var(--primary)]/10 group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)]",
  primary: "bg-gray-50 text-gray-500 dark:bg-white/[0.03] dark:text-gray-400 group-hover:bg-[var(--primary)]/10 group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)]",
  success: "bg-gray-50 text-gray-500 dark:bg-white/[0.03] dark:text-gray-400 group-hover:bg-[var(--primary)]/10 group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)]",
  danger: "bg-gray-50 text-gray-500 dark:bg-white/[0.03] dark:text-gray-400 group-hover:bg-[var(--primary)]/10 group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)]",
  warning: "bg-gray-50 text-gray-500 dark:bg-white/[0.03] dark:text-gray-400 group-hover:bg-[var(--primary)]/10 group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)]",
  info: "bg-gray-50 text-gray-500 dark:bg-white/[0.03] dark:text-gray-400 group-hover:bg-[var(--primary)]/10 group-hover:text-[var(--primary-hover)] dark:group-hover:text-[var(--primary)]",
};

interface StatCardProps {
  title: ReactNode;
  value: ReactNode;
  icon?: LucideIcon;
  tone?: StatTone;
  /** Small caption under the value (e.g. "vs last month"). */
  hint?: ReactNode;
  /** Optional element in the top-right corner (badge, sparkline...). */
  trailing?: ReactNode;
  className?: string;
  children?: ReactNode;
}

/**
 * AFAB StatCard — the sparkline-free sibling of `KpiCard`.
 * Same surface, icon tile, typography and hover behaviour as the
 * KPI cards on the reference pages, for pages whose metrics
 * have no time series (Reports, Customers, Forex...).
 */
export function StatCard({
  title,
  value,
  icon: Icon,
  tone = "neutral",
  hint,
  trailing,
  className,
  children,
}: StatCardProps) {
  return (
    <div className={cn("afab-card afab-card-hover group relative overflow-hidden p-5", className)}>
      <div className="flex items-center justify-between gap-2">
        <div className="flex min-w-0 items-center gap-2.5">
          {Icon && (
            <div
              className={cn(
                "flex h-10 w-10 shrink-0 items-center justify-center rounded-xl transition-colors",
                toneIcon[tone]
              )}
            >
              <Icon className="h-5 w-5" />
            </div>
          )}
          <span className="text-xs font-medium leading-tight text-gray-500 sm:text-sm dark:text-gray-400">
            {title}
          </span>
        </div>
        {trailing}
      </div>
      <div className="mt-4">
        <div className="text-xl font-bold tracking-tight text-gray-900 sm:text-2xl dark:text-white">
          {value}
        </div>
        {hint && <div className="mt-1.5 text-xs text-gray-400 dark:text-gray-500">{hint}</div>}
      </div>
      {children}
    </div>
  );
}
