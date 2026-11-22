import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

interface PageHeaderProps {
  title: ReactNode;
  subtitle?: ReactNode;
  /** Right-aligned action area (buttons, selectors). */
  actions?: ReactNode;
  /** Optional element rendered inline after the title (e.g. a badge). */
  titleAddon?: ReactNode;
  className?: string;
}

/**
 * AFAB standard page header — mirrors the header used on the reference pages
 * (Dashboard, Transactions, Expenses, Revenue, Invoices):
 * bold 2xl/3xl title, muted subtitle, actions aligned on the opposite side.
 */
export function PageHeader({ title, subtitle, actions, titleAddon, className }: PageHeaderProps) {
  return (
    <div className={cn("flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between", className)}>
      <div className="min-w-0">
        <div className="flex flex-wrap items-center gap-2.5">
          <h1 className="afab-page-title">{title}</h1>
          {titleAddon}
        </div>
        {subtitle && <p className="afab-page-subtitle">{subtitle}</p>}
      </div>
      {actions && (
        <div className="flex flex-wrap items-center gap-2 sm:gap-2.5">{actions}</div>
      )}
    </div>
  );
}
