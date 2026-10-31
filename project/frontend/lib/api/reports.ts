import { fetchClient } from "./client";
import { AuthStore } from "@/lib/auth-store";

export interface CategoryShare {
  categoryName: string;
  amount: number;
  percentage: number;
  transactionCount: number;
}

export interface MonthlyCashFlow {
  month: string;
  inflow: number;
  outflow: number;
  net: number;
}

export interface ProfitAndLossReport {
  period: string;
  startDate: string;
  endDate: string;
  currency: string;
  totalRevenue: number;
  totalExpenses: number;
  grossProfit: number;
  netOperatingIncome: number;
  profitMarginPct: number;
  revenueBreakdown: CategoryShare[];
  expenseBreakdown: CategoryShare[];
}

export interface CashFlowReport {
  period: string;
  startDate: string;
  endDate: string;
  currency: string;
  cashInflow: number;
  cashOutflow: number;
  netCashChange: number;
  monthlyTrend: MonthlyCashFlow[];
}

export interface ComparisonReport {
  currency: string;
  primaryPeriodLabel: string;
  primaryRevenue: number;
  primaryExpenses: number;
  primaryNetIncome: number;
  comparisonPeriodLabel: string;
  comparisonRevenue: number;
  comparisonExpenses: number;
  comparisonNetIncome: number;
  revenueDifference: number;
  revenueDifferencePct: number;
  expensesDifference: number;
  expensesDifferencePct: number;
  netIncomeDifference: number;
  netIncomeDifferencePct: number;
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

function triggerFileDownload(blob: Blob, fallbackFilename: string, res?: Response) {
  let filename = fallbackFilename;
  const disposition = res?.headers.get("Content-Disposition");
  if (disposition && disposition.includes("filename=")) {
    const match = disposition.match(/filename[^;=\n]*=((['"]).*?\2|[^;\n]*)/);
    if (match && match[1]) {
      filename = match[1].replace(/['"]/g, "").trim();
    }
  }

  const url = window.URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.style.display = "none";
  a.href = url;
  a.download = filename;
  a.setAttribute("download", filename);
  document.body.appendChild(a);
  a.click();

  // Keep blob URL alive long enough for Chromium/Edge to stream and name the file properly
  setTimeout(() => {
    if (a.parentNode) {
      a.parentNode.removeChild(a);
    }
    window.URL.revokeObjectURL(url);
  }, 2000);
}

export class ReportService {
  static async getProfitAndLoss(
    period: string = "this_month",
    startDate?: string,
    endDate?: string
  ): Promise<ProfitAndLossReport> {
    const params = new URLSearchParams({ period });
    if (startDate) params.set("startDate", startDate);
    if (endDate) params.set("endDate", endDate);

    return fetchClient(`/reports/profit-loss?${params.toString()}`);
  }

  static async getCashFlow(
    period: string = "this_month",
    startDate?: string,
    endDate?: string
  ): Promise<CashFlowReport> {
    const params = new URLSearchParams({ period });
    if (startDate) params.set("startDate", startDate);
    if (endDate) params.set("endDate", endDate);

    return fetchClient(`/reports/cash-flow?${params.toString()}`);
  }

  static async getComparison(
    primaryPeriod: string = "this_month",
    comparisonPeriod: string = "last_month"
  ): Promise<ComparisonReport> {
    const params = new URLSearchParams({ primaryPeriod, comparisonPeriod });
    return fetchClient(`/reports/comparison?${params.toString()}`);
  }

  /**
   * Triggers browser download for CSV statement, with bearer auth & active business header.
   */
  static async downloadCsv(period: string = "this_month", startDate?: string, endDate?: string): Promise<void> {
    const token = AuthStore.getAccessToken();
    const activeBusinessId = AuthStore.getActiveBusinessId();
    const params = new URLSearchParams({ period });
    if (startDate) params.set("startDate", startDate);
    if (endDate) params.set("endDate", endDate);

    const headers: Record<string, string> = {};
    if (token) headers["Authorization"] = `Bearer ${token}`;
    if (activeBusinessId) headers["X-Business-Id"] = activeBusinessId;

    const res = await fetch(`${API_BASE_URL}/reports/export/csv?${params.toString()}`, {
      headers,
    });

    if (!res.ok) {
      if (res.status === 403) {
        const errorJson = await res.json().catch(() => ({}));
        if (typeof window !== "undefined") {
          window.dispatchEvent(
            new CustomEvent("afab:plan-limit-reached", {
              detail: errorJson,
            })
          );
        }
        throw new Error(errorJson?.message || "Export quota exceeded. Upgrade your plan.");
      }
      throw new Error("Failed to export CSV report");
    }

    const rawBlob = await res.blob();
    const csvBlob = new Blob([rawBlob], { type: "text/csv;charset=utf-8;" });
    triggerFileDownload(csvBlob, `AFAB-Financial-Report-${period}.csv`, res);
  }

  /**
   * Triggers browser download for PDF statement, with bearer auth & active business header.
   */
  static async downloadPdf(period: string = "this_month", startDate?: string, endDate?: string): Promise<void> {
    const token = AuthStore.getAccessToken();
    const activeBusinessId = AuthStore.getActiveBusinessId();
    const params = new URLSearchParams({ period });
    if (startDate) params.set("startDate", startDate);
    if (endDate) params.set("endDate", endDate);

    const headers: Record<string, string> = {};
    if (token) headers["Authorization"] = `Bearer ${token}`;
    if (activeBusinessId) headers["X-Business-Id"] = activeBusinessId;

    const res = await fetch(`${API_BASE_URL}/reports/export/pdf?${params.toString()}`, {
      headers,
    });

    if (!res.ok) {
      if (res.status === 403) {
        const errorJson = await res.json().catch(() => ({}));
        if (typeof window !== "undefined") {
          window.dispatchEvent(
            new CustomEvent("afab:plan-limit-reached", {
              detail: errorJson,
            })
          );
        }
        throw new Error(errorJson?.message || "Export quota exceeded. Upgrade your plan.");
      }
      throw new Error("Failed to export PDF statement");
    }

    const rawBlob = await res.blob();
    const pdfBlob = new Blob([rawBlob], { type: "application/pdf" });
    triggerFileDownload(pdfBlob, `AFAB-Financial-Statement-${period}.pdf`, res);
  }
}
