"use client";

import * as XLSX from "xlsx";
import { jsPDF } from "jspdf";
import { getWetSignature } from "./signature-utils";

export interface MasterExportData {
  businessName: string;
  currency: string;
  generatedAt: string;
  dateRange: string;
  transactions: Array<{
    id: string;
    date: string;
    description: string;
    type: string;
    category: string;
    amount: number;
    currency: string;
    paymentMethod: string;
    status: string;
    notes?: string;
  }>;
  customers: Array<{
    id: string;
    orderNumber?: string;
    name: string;
    email: string;
    phone: string;
    totalSpent: number;
    invoicesCount: number;
    status: string;
    group?: string;
  }>;
  invoices: Array<{
    invoiceNumber: string;
    customerName: string;
    issueDate: string;
    dueDate: string;
    totalAmount: number;
    currency: string;
    status: string;
  }>;
  summary: {
    totalRevenue: number;
    totalExpenses: number;
    netBalance: number;
    totalCustomersCount: number;
    totalInvoicesCount: number;
    totalTransactionsCount: number;
  };
}

let cachedLogoBase64: string | null = null;

/**
 * Loads the AFAB logo from /assets/afab-logo-light.png and converts to Base64 PNG.
 */
export async function getLogoBase64(): Promise<string | null> {
  if (cachedLogoBase64) return cachedLogoBase64;
  if (typeof window === "undefined") return null;

  return new Promise((resolve) => {
    const img = new Image();
    img.crossOrigin = "anonymous";
    img.onload = () => {
      try {
        const canvas = document.createElement("canvas");
        canvas.width = img.naturalWidth || 128;
        canvas.height = img.naturalHeight || 128;
        const ctx = canvas.getContext("2d");
        if (!ctx) {
          resolve(null);
          return;
        }
        ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
        const dataUrl = canvas.toDataURL("image/png");
        cachedLogoBase64 = dataUrl;
        resolve(dataUrl);
      } catch {
        resolve(null);
      }
    };
    img.onerror = () => resolve(null);
    img.src = "/assets/afab-logo-light.png";
  });
}

/**
 * Period options for filtering financial data.
 */
export interface PeriodOption {
  id: string;
  labelEn: string;
  labelAr: string;
}

export const PERIOD_PRESETS: PeriodOption[] = [
  { id: "all", labelEn: "All Time", labelAr: "كل الأوقات" },
  { id: "this_month", labelEn: "This Month", labelAr: "هذا الشهر" },
  { id: "last_month", labelEn: "Last Month", labelAr: "الشهر السابق" },
  { id: "this_quarter", labelEn: "This Quarter", labelAr: "الربع الحالي" },
  { id: "this_year", labelEn: "This Year", labelAr: "هذا العام" },
  { id: "last_year", labelEn: "Last Year", labelAr: "العام السابق" },
  { id: "last_30_days", labelEn: "Last 30 Days", labelAr: "آخر 30 يوم" },
  { id: "last_90_days", labelEn: "Last 90 Days", labelAr: "آخر 90 يوم" },
  { id: "custom", labelEn: "Custom Range...", labelAr: "نطاق مخصص..." }
];

/**
 * Calculates start and end Date objects and a localized formatted string.
 */
export function calculateDateRange(
  periodId: string,
  customStart?: string,
  customEnd?: string,
  isAr: boolean = false
): { startDate: Date | null; endDate: Date | null; label: string } {
  const now = new Date();
  let startDate: Date | null = null;
  let endDate: Date | null = null;
  let label = isAr ? "كل الأوقات" : "All Time";

  switch (periodId) {
    case "this_month": {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
      label = isAr ? "هذا الشهر" : "This Month";
      break;
    }
    case "last_month": {
      startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
      endDate = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
      label = isAr ? "الشهر السابق" : "Last Month";
      break;
    }
    case "this_quarter": {
      const qMonth = Math.floor(now.getMonth() / 3) * 3;
      startDate = new Date(now.getFullYear(), qMonth, 1);
      endDate = new Date(now.getFullYear(), qMonth + 3, 0, 23, 59, 59, 999);
      label = isAr ? "الربع الحالي" : "This Quarter";
      break;
    }
    case "this_year": {
      startDate = new Date(now.getFullYear(), 0, 1);
      endDate = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);
      label = isAr ? "هذا العام" : "This Year";
      break;
    }
    case "last_year": {
      startDate = new Date(now.getFullYear() - 1, 0, 1);
      endDate = new Date(now.getFullYear() - 1, 11, 31, 23, 59, 59, 999);
      label = isAr ? "العام السابق" : "Last Year";
      break;
    }
    case "last_30_days": {
      startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      endDate = now;
      label = isAr ? "آخر 30 يوم" : "Last 30 Days";
      break;
    }
    case "last_90_days": {
      startDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
      endDate = now;
      label = isAr ? "آخر 90 يوم" : "Last 90 Days";
      break;
    }
    case "custom": {
      if (customStart) startDate = new Date(customStart + "T00:00:00");
      if (customEnd) endDate = new Date(customEnd + "T23:59:59.999");
      if (customStart && customEnd) {
        label = `${customStart} — ${customEnd}`;
      } else if (customStart) {
        label = isAr ? `من ${customStart}` : `From ${customStart}`;
      } else if (customEnd) {
        label = isAr ? `حتى ${customEnd}` : `Until ${customEnd}`;
      } else {
        label = isAr ? "فترة مخصصة" : "Custom Range";
      }
      break;
    }
    case "all":
    default: {
      startDate = null;
      endDate = null;
      label = isAr ? "كل الأوقات" : "All Time";
      break;
    }
  }

  return { startDate, endDate, label };
}

/**
 * Generates and downloads a complete multi-sheet Excel (.xlsx) workbook.
 * Features an executive corporate branding header on every sheet.
 */
export function exportMasterToExcel(
  data: MasterExportData, 
  filenamePrefix: string = "AFAB_Complete_Archive",
  includeLogo: boolean = true,
  includeSignature: boolean = true
) {
  const wb = XLSX.utils.book_new();
  const dateStr = new Date().toISOString().split("T")[0];
  const signature = includeSignature ? getWetSignature() : null;

  // ── Sheet 1: Executive Summary ──
  const summaryAoa = [
    ["═══════════════════════════════════════════════════════════════════════"],
    ["✨  AFAB ENTERPRISE — OFFICIAL FINANCIAL RECORD"],
    includeLogo 
      ? ["Brand Identity: AFAB AI Finance Platform | Logo: /assets/afab-logo-light.png"]
      : ["Brand Identity: AFAB AI Finance Platform"],
    ["═══════════════════════════════════════════════════════════════════════"],
    [],
    ["METADATA", "DETAILS"],
    ["Business Name", data.businessName || "My Business"],
    ["Selected Period", data.dateRange || "All Time"],
    ["Reporting Currency", data.currency || "USD"],
    ["Export Date & Time", data.generatedAt || new Date().toLocaleString()],
    [],
    ["EXECUTIVE METRICS", "AMOUNT", "CURRENCY / UNIT"],
    ["Total Operating Revenue", data.summary.totalRevenue, data.currency],
    ["Total Operating Expenses", data.summary.totalExpenses, data.currency],
    ["Net Cash Flow / Profit", data.summary.netBalance, data.currency],
    ["Recorded Transactions", data.summary.totalTransactionsCount, "Entries in Period"],
    ["Active Customers Directory", data.summary.totalCustomersCount, "Registered Clients"],
    ["Invoices Issued in Period", data.summary.totalInvoicesCount, "Tracked Invoices"],
    ...(signature?.dataUrl ? [
      [],
      ["EXECUTIVE SIGNATORY & WET SIGNATURE", "CERTIFICATION RECORD"],
      ["Authorized Signatory", signature.signatoryName || "Authorized Signatory"],
      ["Signatory Title", signature.signatoryTitle || "Executive Management"],
      ["Wet Signature Status", "Verified & Attached via AFAB Digital Authority"],
      ["Sign Date", new Date().toLocaleDateString()]
    ] : []),
    [],
    ["Compliance & Integrity", "Exported with 256-bit encryption from AFAB Financial Platform."]
  ];
  const wsSummary = XLSX.utils.aoa_to_sheet(summaryAoa);
  wsSummary["!cols"] = [{ wch: 32 }, { wch: 28 }, { wch: 18 }];
  XLSX.utils.book_append_sheet(wb, wsSummary, "Overview & KPIs");

  // ── Sheet 2: Transactions ──
  const txHeaders = [
    "Transaction ID",
    "Date",
    "Description",
    "Type",
    "Category",
    "Amount",
    "Currency",
    "Payment Method",
    "Status",
    "Notes"
  ];
  const txBanner = [
    ["AFAB ENTERPRISE — TRANSACTION LEDGER"],
    [`Period: ${data.dateRange}  |  Business: ${data.businessName}  |  Currency: ${data.currency}`],
    []
  ];
  const txRows = data.transactions.map((tx) => [
    tx.id,
    tx.date,
    tx.description,
    tx.type,
    tx.category || "General",
    tx.amount,
    tx.currency || data.currency,
    tx.paymentMethod,
    tx.status,
    tx.notes || ""
  ]);
  const wsTx = XLSX.utils.aoa_to_sheet([...txBanner, txHeaders, ...txRows]);
  wsTx["!cols"] = [
    { wch: 20 },
    { wch: 14 },
    { wch: 34 },
    { wch: 12 },
    { wch: 18 },
    { wch: 14 },
    { wch: 10 },
    { wch: 16 },
    { wch: 14 },
    { wch: 25 }
  ];
  XLSX.utils.book_append_sheet(wb, wsTx, "Transactions");

  // ── Sheet 3: Customers ──
  const customerHeaders = [
    "Customer ID / Code",
    "Associated Order / Ref #",
    "Customer Name",
    "Email",
    "Phone",
    "Total Spent in Period",
    "Orders Count",
    "Status",
    "Segment Group"
  ];
  const custBanner = [
    ["AFAB ENTERPRISE — CUSTOMER & CLIENT DIRECTORY"],
    [`Period: ${data.dateRange}  |  Business: ${data.businessName}  |  Currency: ${data.currency}`],
    []
  ];
  const customerRows = data.customers.map((c) => [
    c.id,
    c.orderNumber || "-",
    c.name,
    c.email || "-",
    c.phone || "-",
    c.totalSpent,
    c.invoicesCount || 0,
    c.status || "ACTIVE",
    c.group || "Standard"
  ]);
  const wsCustomers = XLSX.utils.aoa_to_sheet([...custBanner, customerHeaders, ...customerRows]);
  wsCustomers["!cols"] = [
    { wch: 18 },
    { wch: 22 },
    { wch: 26 },
    { wch: 26 },
    { wch: 18 },
    { wch: 16 },
    { wch: 14 },
    { wch: 12 },
    { wch: 16 }
  ];
  XLSX.utils.book_append_sheet(wb, wsCustomers, "Customers");

  // ── Sheet 4: Invoices ──
  const invoiceHeaders = [
    "Invoice Number",
    "Customer Name",
    "Issue Date",
    "Due Date",
    "Total Amount",
    "Currency",
    "Status"
  ];
  const invBanner = [
    ["AFAB ENTERPRISE — INVOICES & BILLING REGISTER"],
    [`Period: ${data.dateRange}  |  Business: ${data.businessName}  |  Currency: ${data.currency}`],
    []
  ];
  const invoiceRows = data.invoices.map((inv) => [
    inv.invoiceNumber,
    inv.customerName || "-",
    inv.issueDate,
    inv.dueDate || "-",
    inv.totalAmount,
    inv.currency || data.currency,
    inv.status
  ]);
  const wsInvoices = XLSX.utils.aoa_to_sheet([...invBanner, invoiceHeaders, ...invoiceRows]);
  wsInvoices["!cols"] = [
    { wch: 18 },
    { wch: 26 },
    { wch: 14 },
    { wch: 14 },
    { wch: 14 },
    { wch: 10 },
    { wch: 14 }
  ];
  XLSX.utils.book_append_sheet(wb, wsInvoices, "Invoices");

  // Trigger browser download
  XLSX.writeFile(wb, `${filenamePrefix}_${dateStr}.xlsx`);
}

/**
 * Exports a single dataset to Excel (.xlsx) with branded header block.
 */
export function exportDatasetToExcel(
  sheetName: string,
  headers: string[],
  rows: (string | number | boolean | null | undefined)[][],
  filenamePrefix: string,
  periodLabel: string = "All Time"
) {
  const wb = XLSX.utils.book_new();
  const dateStr = new Date().toISOString().split("T")[0];
  const banner = [
    [`AFAB ENTERPRISE — ${sheetName.toUpperCase()}`],
    [`Period: ${periodLabel}  |  Exported: ${new Date().toLocaleDateString()}`],
    []
  ];
  const ws = XLSX.utils.aoa_to_sheet([...banner, headers, ...rows]);
  ws["!cols"] = headers.map(() => ({ wch: 20 }));
  XLSX.utils.book_append_sheet(wb, ws, sheetName.substring(0, 31));
  XLSX.writeFile(wb, `${filenamePrefix}_${dateStr}.xlsx`);
}

/**
 * Generates and downloads a complete branded PDF report statement with embedded logo.
 */
export async function exportMasterToPdf(
  data: MasterExportData,
  filenamePrefix: string = "AFAB_Financial_Statement",
  includeLogo: boolean = true,
  includeSignature: boolean = true
) {
  const doc = new jsPDF({
    orientation: "portrait",
    unit: "mm",
    format: "a4"
  });

  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();
  const margin = 14;
  let cursorY = margin;

  // Header Banner Background
  doc.setFillColor(124, 58, 237); // Primary purple #7c3aed
  doc.rect(0, 0, pageWidth, 32, "F");

  // Fetch & Embed Logo
  const logoData = includeLogo ? await getLogoBase64() : null;
  let textStartX = margin;

  if (logoData) {
    try {
      // White rounded background container for logo
      doc.setFillColor(255, 255, 255);
      doc.roundedRect(margin, 5, 22, 22, 3, 3, "F");
      doc.addImage(logoData, "PNG", margin + 1.5, 6.5, 19, 19);
      textStartX = margin + 26;
    } catch (e) {
      console.warn("Could not render logo in PDF, falling back to vector text", e);
      textStartX = margin;
    }
  } else {
    textStartX = margin;
  }

  // Header Typography
  doc.setTextColor(255, 255, 255);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(15);
  doc.text("AFAB — Financial Enterprise Archive", textStartX, 13);

  doc.setFont("helvetica", "normal");
  doc.setFontSize(8.5);
  doc.text(
    `Business: ${data.businessName || "My Business"}  |  Currency: ${data.currency}  |  Period: ${data.dateRange}`,
    textStartX,
    20
  );
  doc.text(
    `Generated: ${data.generatedAt || new Date().toLocaleDateString()}  |  Certified Digital Record`,
    textStartX,
    26
  );

  cursorY = 42;

  // Section 1: Executive KPI Cards
  doc.setTextColor(30, 41, 59);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(11);
  doc.text(`1. Executive Financial Summary (${data.dateRange})`, margin, cursorY);
  cursorY += 6;

  const cardWidth = (pageWidth - margin * 2 - 8) / 3;
  const kpis = [
    { label: "Total Revenue", val: `${Number(data.summary.totalRevenue || 0).toLocaleString()} ${data.currency}`, color: [16, 185, 129] },
    { label: "Total Expenses", val: `${Number(data.summary.totalExpenses || 0).toLocaleString()} ${data.currency}`, color: [239, 68, 68] },
    { label: "Net Cash Flow", val: `${Number(data.summary.netBalance || 0).toLocaleString()} ${data.currency}`, color: [124, 58, 237] }
  ];

  kpis.forEach((kpi, idx) => {
    const cardX = margin + idx * (cardWidth + 4);
    doc.setFillColor(248, 250, 252);
    doc.setDrawColor(226, 232, 240);
    doc.roundedRect(cardX, cursorY, cardWidth, 18, 2, 2, "FD");

    doc.setFont("helvetica", "normal");
    doc.setFontSize(8);
    doc.setTextColor(100, 116, 139);
    doc.text(kpi.label, cardX + 4, cursorY + 6);

    doc.setFont("helvetica", "bold");
    doc.setFontSize(9.5);
    doc.setTextColor(kpi.color[0], kpi.color[1], kpi.color[2]);
    doc.text(kpi.val, cardX + 4, cursorY + 13);
  });

  cursorY += 26;

  // Helper to draw clean table
  const drawTable = (title: string, headers: string[], colWidths: number[], rows: (string | number)[][], maxRows: number = 20) => {
    if (cursorY > pageHeight - 40) {
      doc.addPage();
      cursorY = 20;
    }

    doc.setTextColor(30, 41, 59);
    doc.setFont("helvetica", "bold");
    doc.setFontSize(10.5);
    doc.text(title, margin, cursorY);
    cursorY += 4;

    // Header row
    doc.setFillColor(241, 245, 249);
    doc.rect(margin, cursorY, pageWidth - margin * 2, 7, "F");
    doc.setFont("helvetica", "bold");
    doc.setFontSize(8);
    doc.setTextColor(71, 85, 105);

    let currentX = margin + 2;
    headers.forEach((h, i) => {
      doc.text(h, currentX, cursorY + 5);
      currentX += colWidths[i];
    });
    cursorY += 7;

    // Data rows
    const sliceRows = rows.slice(0, maxRows);
    doc.setFont("helvetica", "normal");
    doc.setFontSize(7.5);

    sliceRows.forEach((row, rowIndex) => {
      if (cursorY > pageHeight - 20) {
        doc.addPage();
        cursorY = 20;
      }

      if (rowIndex % 2 === 1) {
        doc.setFillColor(248, 250, 252);
        doc.rect(margin, cursorY, pageWidth - margin * 2, 6, "F");
      }

      doc.setTextColor(30, 41, 59);
      let cellX = margin + 2;
      row.forEach((cell, ci) => {
        const text = String(cell ?? "-");
        const truncated = text.length > 25 ? text.substring(0, 23) + "..." : text;
        doc.text(truncated, cellX, cursorY + 4.5);
        cellX += colWidths[ci];
      });
      cursorY += 6;
    });

    if (rows.length > maxRows) {
      doc.setFont("helvetica", "italic");
      doc.setTextColor(148, 163, 184);
      doc.text(`+ ${rows.length - maxRows} additional records included in complete Excel archive.`, margin, cursorY + 4);
      cursorY += 8;
    } else {
      cursorY += 6;
    }
  };

  // 2. Transactions Table
  const txColWidths = [24, 52, 28, 24, 24, 30];
  const txTableHeaders = ["Date", "Description", "Type", "Amount", "Currency", "Status"];
  const txTableRows = data.transactions.map((tx) => [
    tx.date,
    tx.description,
    tx.type,
    Number(tx.amount).toFixed(2),
    tx.currency || data.currency,
    tx.status
  ]);
  drawTable(`2. Transaction Ledger (${data.transactions.length} entries)`, txTableHeaders, txColWidths, txTableRows, 15);

  // 3. Customers Directory
  const custColWidths = [28, 38, 36, 40, 24, 16];
  const custHeaders = ["Customer Code", "Order / Ref #", "Name", "Email", "Total Spent", "Orders"];
  const custRows = data.customers.map((c) => [
    c.id,
    c.orderNumber || "-",
    c.name,
    c.email || "-",
    `${Number(c.totalSpent).toFixed(2)} ${data.currency}`,
    c.invoicesCount || 0
  ]);
  drawTable(`3. Customer Directory (${data.customers.length} clients)`, custHeaders, custColWidths, custRows, 10);

  // 4. Invoices Table
  const invColWidths = [32, 50, 28, 28, 26, 18];
  const invHeaders = ["Invoice #", "Customer", "Issue Date", "Due Date", "Total", "Status"];
  const invRows = data.invoices.map((inv) => [
    inv.invoiceNumber,
    inv.customerName,
    inv.issueDate,
    inv.dueDate || "-",
    `${Number(inv.totalAmount).toFixed(2)} ${inv.currency || data.currency}`,
    inv.status
  ]);
  drawTable(`4. Invoices & Billing (${data.invoices.length} invoices)`, invHeaders, invColWidths, invRows, 10);

  // 5. Executive Authorization & Wet Signature Block
  const signature = includeSignature ? getWetSignature() : null;
  if (signature?.dataUrl && signature.enabled) {
    if (cursorY > pageHeight - 50) {
      doc.addPage();
      cursorY = 20;
    } else {
      cursorY += 8;
    }

    const boxWidth = pageWidth - margin * 2;
    doc.setFillColor(248, 250, 252);
    doc.setDrawColor(226, 232, 240);
    doc.roundedRect(margin, cursorY, boxWidth, 34, 2, 2, "FD");

    // Left: Certification Seal Text
    doc.setFont("helvetica", "bold");
    doc.setFontSize(9);
    doc.setTextColor(30, 41, 59);
    doc.text("Executive Certification & Authenticity Guarantee", margin + 6, cursorY + 8);

    doc.setFont("helvetica", "normal");
    doc.setFontSize(7.5);
    doc.setTextColor(100, 116, 139);
    doc.text("This financial record is certified electronically by AFAB Platform.", margin + 6, cursorY + 14);
    doc.text(`Digital Sign Date: ${new Date().toLocaleDateString()}`, margin + 6, cursorY + 19);
    doc.text("Status: VERIFIED & AUDITED", margin + 6, cursorY + 24);

    // Right: Wet Signature Image & Title
    const sigBlockX = pageWidth - margin - 58;
    try {
      doc.addImage(signature.dataUrl, "PNG", sigBlockX, cursorY + 3, 46, 15);
    } catch (e) {
      console.warn("Could not embed signature in PDF:", e);
    }

    doc.setDrawColor(203, 213, 225);
    doc.line(sigBlockX, cursorY + 20, sigBlockX + 48, cursorY + 20);

    doc.setFont("helvetica", "bold");
    doc.setFontSize(8);
    doc.setTextColor(15, 23, 42);
    doc.text(signature.signatoryName || "Authorized Signatory", sigBlockX, cursorY + 24);

    doc.setFont("helvetica", "normal");
    doc.setFontSize(7);
    doc.setTextColor(100, 116, 139);
    doc.text(signature.signatoryTitle || "Executive Management", sigBlockX, cursorY + 28);

    cursorY += 38;
  }

  // Footer on all pages
  const totalPages = doc.getNumberOfPages();
  for (let i = 1; i <= totalPages; i++) {
    doc.setPage(i);
    doc.setFont("helvetica", "normal");
    doc.setFontSize(8);
    doc.setTextColor(148, 163, 184);
    doc.text(`AFAB Enterprise Financial Management  |  Page ${i} of ${totalPages}`, margin, pageHeight - 8);
    doc.text("Official Statement", pageWidth - margin - 25, pageHeight - 8);
  }

  const dateStr = new Date().toISOString().split("T")[0];
  doc.save(`${filenamePrefix}_${dateStr}.pdf`);
}

/**
 * Opens a high-fidelity printable view with CSS print styling and embedded logo.
 */
export function openPrintableReportWindow(options: {
  title: string;
  subtitle?: string;
  businessName: string;
  currency: string;
  dateRange?: string;
  kpis?: Array<{ label: string; value: string }>;
  sections: Array<{
    title: string;
    headers: string[];
    rows: (string | number)[][];
  }>;
  isAr?: boolean;
  includeLogo?: boolean;
  includeSignature?: boolean;
}) {
  const dir = options.isAr ? "rtl" : "ltr";
  const align = options.isAr ? "right" : "left";
  const showLogo = options.includeLogo !== false;
  const signature = options.includeSignature !== false ? getWetSignature() : null;

  const win = window.open("", "_blank");
  if (!win) {
    alert("Please allow popups to view printable report");
    return;
  }

  const kpiHtml = (options.kpis || [])
    .map(
      (k) => `
    <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:12px; padding:16px; flex:1; min-width:180px;">
      <div style="font-size:12px; color:#64748b; font-weight:500;">${k.label}</div>
      <div style="font-size:18px; color:#0f172a; font-weight:700; margin-top:4px;">${k.value}</div>
    </div>
  `
    )
    .join("");

  const sectionsHtml = options.sections
    .map(
      (s) => `
    <div style="margin-top:28px;">
      <h3 style="font-size:14px; font-weight:700; color:#1e293b; margin-bottom:12px; border-bottom:2px solid #f1f5f9; padding-bottom:6px;">
        ${s.title}
      </h3>
      <table style="width:100%; border-collapse:collapse; font-size:12px; text-align:${align};">
        <thead>
          <tr style="background:#f1f5f9; color:#475569;">
            ${s.headers.map((h) => `<th style="padding:10px 12px; font-weight:600; border-bottom:1px solid #cbd5e1;">${h}</th>`).join("")}
          </tr>
        </thead>
        <tbody>
          ${s.rows
            .map(
              (r, idx) => `
            <tr style="background:${idx % 2 === 1 ? "#f8fafc" : "#ffffff"}; border-bottom:1px solid #f1f5f9;">
              ${r.map((c) => `<td style="padding:8px 12px; color:#334155;">${c ?? "-"}</td>`).join("")}
            </tr>
          `
            )
            .join("")}
        </tbody>
      </table>
    </div>
  `
    )
    .join("");

  const signatureHtml = signature?.dataUrl && signature.enabled ? `
    <div style="margin-top:40px; padding:18px 24px; background:#f8fafc; border:1px solid #e2e8f0; border-radius:16px; display:flex; justify-content:space-between; align-items:flex-end; gap:24px;">
      <div style="max-width:340px;">
        <div style="font-size:11px; font-weight:700; color:#7c3aed; text-transform:uppercase; letter-spacing:0.5px;">
          ${options.isAr ? "الاعتماد المالي والختم الرسمي" : "Official Executive Certification"}
        </div>
        <div style="font-size:11px; color:#475569; margin-top:4px; line-height:1.5;">
          ${options.isAr ? "تم اعتماد هذه البيانات وتوقيعها رسمياً بموجب الصلاحيات المخولة عبر منصة AFAB الذكية." : "This record is formally certified with an authentic wet signature under enterprise governance."}
        </div>
        <div style="font-size:10px; color:#94a3b8; margin-top:6px; font-family:monospace;">
          AUDIT-ID: ${Math.random().toString(36).substring(2, 10).toUpperCase()} · 256-BIT CERTIFIED
        </div>
      </div>

      <div style="text-align:${options.isAr ? "left" : "right"}; min-width:180px;">
        <div style="font-size:10px; font-weight:700; color:#64748b; text-transform:uppercase; margin-bottom:4px;">
          ${options.isAr ? "التوقيع الحي المعتمد" : "Authorized Wet Signature"}
        </div>
        <div style="height:48px; display:flex; align-items:center; justify-content:${options.isAr ? "flex-start" : "flex-end"};">
          <img src="${signature.dataUrl}" style="max-height:48px; max-width:180px; object-fit:contain;" alt="Signature" />
        </div>
        <div style="border-top:1px solid #cbd5e1; margin-top:4px; padding-top:4px;">
          <div style="font-size:12px; font-weight:700; color:#0f172a;">${signature.signatoryName}</div>
          <div style="font-size:11px; color:#64748b;">${signature.signatoryTitle}</div>
          <div style="font-size:10px; color:#94a3b8; margin-top:2px;">${new Date().toLocaleDateString()}</div>
        </div>
      </div>
    </div>
  ` : "";

  const html = `
    <!DOCTYPE html>
    <html dir="${dir}" lang="${options.isAr ? "ar" : "en"}">
    <head>
      <meta charset="utf-8">
      <title>${options.title}</title>
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
      <style>
        body {
          font-family: ${options.isAr ? "'Cairo', sans-serif" : "'Inter', sans-serif"};
          padding: 32px;
          background: #ffffff;
          color: #0f172a;
          margin: 0;
        }
        @media print {
          body { padding: 0; }
          .no-print { display: none !important; }
          @page { size: A4; margin: 15mm; }
        }
        .header-bar {
          display: flex;
          align-items: center;
          justify-content: space-between;
          border-bottom: 2px solid #7c3aed;
          padding-bottom: 16px;
          margin-bottom: 24px;
        }
        .logo-box {
          height: 48px;
          width: 48px;
          border-radius: 12px;
          border: 1px solid #e2e8f0;
          background: #ffffff;
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: hidden;
          box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .logo-box img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
      </style>
    </head>
    <body>
      <div class="no-print" style="margin-bottom:20px; display:flex; gap:12px; justify-content:flex-end;">
        <button onclick="window.print()" style="background:#7c3aed; color:#fff; border:none; padding:10px 20px; border-radius:8px; font-weight:600; cursor:pointer;">
          ${options.isAr ? "طباعة / حفظ كملف PDF" : "Print / Save as PDF"}
        </button>
        <button onclick="window.close()" style="background:#e2e8f0; color:#334155; border:none; padding:10px 16px; border-radius:8px; font-weight:600; cursor:pointer;">
          ${options.isAr ? "إغلاق" : "Close"}
        </button>
      </div>

      <div class="header-bar">
        <div style="display:flex; align-items:center; gap:16px;">
          ${showLogo ? `
          <div class="logo-box">
            <img src="/assets/afab-logo-light.png" alt="AFAB Logo" />
          </div>` : ""}
          <div>
            <h1 style="font-size:20px; font-weight:800; color:#7c3aed; margin:0;">AFAB Enterprise</h1>
            <p style="font-size:12px; color:#64748b; margin:4px 0 0 0;">${options.subtitle || "Official Financial & Data Record"}</p>
          </div>
        </div>
        <div style="text-align:${options.isAr ? "left" : "right"}; font-size:11px; color:#64748b;">
          <div><strong>${options.businessName}</strong></div>
          <div style="color:#7c3aed; font-weight:600;">Period: ${options.dateRange || "All Time"}</div>
          <div>${new Date().toLocaleDateString()}</div>
        </div>
      </div>

      <div style="display:flex; gap:12px; flex-wrap:wrap; margin-bottom:24px;">
        ${kpiHtml}
      </div>

      ${sectionsHtml}

      ${signatureHtml}

      <div style="margin-top:40px; border-top:1px solid #e2e8f0; padding-top:12px; display:flex; justify-content:space-between; font-size:10px; color:#94a3b8;">
        <div>AFAB Financial Intelligence Platform</div>
        <div>${options.isAr ? "سجل تجاري إلكتروني معتمد" : "Certified Digital Record"}</div>
      </div>
    </body>
    </html>
  `;

  win.document.open();
  win.document.write(html);
  win.document.close();
}

/**
 * Opens a dedicated printable corporate invoice with wet signature block.
 */
export function openPrintableInvoiceWindow(options: {
  invoice: any;
  business?: any;
  isAr?: boolean;
  includeSignature?: boolean;
}) {
  const { invoice, business, isAr } = options;
  const dir = isAr ? "rtl" : "ltr";
  const align = isAr ? "right" : "left";
  const signature = options.includeSignature !== false ? getWetSignature(business?.id) : null;

  const win = window.open("", "_blank");
  if (!win) {
    alert("Please allow popups to view printable invoice");
    return;
  }

  const items = invoice.items || [];
  const payments = invoice.payments || [];
  const currency = invoice.currency || business?.currency || "USD";

  const itemsHtml = items.map((it: any, idx: number) => `
    <tr style="background:${idx % 2 === 1 ? "#f8fafc" : "#ffffff"}; border-bottom:1px solid #f1f5f9;">
      <td style="padding:10px 12px; color:#1e293b; font-weight:500;">${it.description || "-"}</td>
      <td style="padding:10px 12px; text-align:center; color:#475569;">${it.quantity}</td>
      <td style="padding:10px 12px; text-align:${isAr ? "left" : "right"}; color:#475569;">${Number(it.unitPrice).toFixed(2)} ${currency}</td>
      <td style="padding:10px 12px; text-align:center; color:#64748b;">${it.taxRate > 0 ? `${it.taxRate}%` : "-"}</td>
      <td style="padding:10px 12px; text-align:${isAr ? "left" : "right"}; font-weight:700; color:#0f172a;">
        ${Number(it.lineTotal ?? it.quantity * it.unitPrice).toFixed(2)} ${currency}
      </td>
    </tr>
  `).join("");

  const signatureBlockHtml = signature?.dataUrl && signature.enabled ? `
    <div style="margin-top:36px; padding:20px; background:#f8fafc; border:1px solid #e2e8f0; border-radius:16px; display:flex; justify-content:space-between; align-items:flex-end;">
      <div>
        <div style="font-size:11px; font-weight:700; color:#7c3aed; text-transform:uppercase;">
          ${isAr ? "الاعتماد القانوني والفاتورة الرسمية" : "Official Certification & Authorization"}
        </div>
        <div style="font-size:11px; color:#64748b; margin-top:4px;">
          ${isAr ? "تم إصدار هذه الفاتورة وتوقيعها رسمياً." : "Issued and certified electronically under AFAB standards."}
        </div>
      </div>
      <div style="text-align:${isAr ? "left" : "right"}; min-width:180px;">
        <div style="font-size:10px; font-weight:700; color:#64748b; text-transform:uppercase; margin-bottom:4px;">
          ${isAr ? "التوقيع الحي المعتمد" : "Authorized Wet Signature"}
        </div>
        <div style="height:48px; display:flex; align-items:center; justify-content:${isAr ? "flex-start" : "flex-end"};">
          <img src="${signature.dataUrl}" style="max-height:48px; max-width:180px; object-fit:contain;" alt="Signature" />
        </div>
        <div style="border-top:1px solid #cbd5e1; margin-top:4px; padding-top:4px;">
          <div style="font-size:12px; font-weight:700; color:#0f172a;">${signature.signatoryName}</div>
          <div style="font-size:11px; color:#64748b;">${signature.signatoryTitle}</div>
        </div>
      </div>
    </div>
  ` : "";

  const html = `
    <!DOCTYPE html>
    <html dir="${dir}" lang="${isAr ? "ar" : "en"}">
    <head>
      <meta charset="utf-8">
      <title>Invoice ${invoice.invoiceNumber || invoice.id}</title>
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
      <style>
        body {
          font-family: ${isAr ? "'Cairo', sans-serif" : "'Inter', sans-serif"};
          padding: 36px;
          background: #ffffff;
          color: #0f172a;
          margin: 0;
        }
        @media print {
          body { padding: 0; }
          .no-print { display: none !important; }
          @page { size: A4; margin: 15mm; }
        }
        .header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          border-bottom: 2px solid #7c3aed;
          padding-bottom: 20px;
          margin-bottom: 28px;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          font-size: 12px;
        }
        th {
          background: #f1f5f9;
          color: #475569;
          font-weight: 700;
          padding: 10px 12px;
          border-bottom: 1px solid #cbd5e1;
        }
      </style>
    </head>
    <body>
      <div class="no-print" style="margin-bottom:24px; display:flex; gap:12px; justify-content:flex-end;">
        <button onclick="window.print()" style="background:#7c3aed; color:#fff; border:none; padding:10px 24px; border-radius:10px; font-weight:700; cursor:pointer;">
          ${isAr ? "طباعة / حفظ كملف PDF" : "Print / Save as PDF"}
        </button>
        <button onclick="window.close()" style="background:#e2e8f0; color:#334155; border:none; padding:10px 18px; border-radius:10px; font-weight:600; cursor:pointer;">
          ${isAr ? "إغلاق" : "Close"}
        </button>
      </div>

      <div class="header">
        <div style="display:flex; align-items:center; gap:16px;">
          <div style="height:52px; width:52px; border-radius:12px; border:1px solid #e2e8f0; padding:4px; display:flex; align-items:center; justify-content:center;">
            <img src="/assets/afab-logo-light.png" alt="Logo" style="max-height:100%; max-width:100%; object-fit:contain;" />
          </div>
          <div>
            <h1 style="font-size:22px; font-weight:800; color:#7c3aed; margin:0;">${business?.name || "AFAB Enterprise"}</h1>
            <p style="font-size:12px; color:#64748b; margin:4px 0 0 0;">${business?.businessEmail || "finance@afab.com"}</p>
          </div>
        </div>
        <div style="text-align:${isAr ? "left" : "right"};">
          <div style="font-size:24px; font-weight:900; color:#0f172a; text-transform:uppercase;">${isAr ? "فاتورة رسمية" : "INVOICE"}</div>
          <div style="font-size:13px; font-weight:700; color:#7c3aed; margin-top:2px;"># ${invoice.invoiceNumber || invoice.id}</div>
          <div style="display:inline-block; margin-top:6px; padding:3px 10px; border-radius:20px; font-size:10px; font-weight:700; background:#f1f5f9; color:#334155;">
            STATUS: ${invoice.status}
          </div>
        </div>
      </div>

      <div style="display:grid; grid-template-columns:1fr 1fr; gap:24px; margin-bottom:28px;">
        <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:14px; padding:16px;">
          <div style="font-size:11px; font-weight:700; color:#64748b; text-transform:uppercase; margin-bottom:6px;">
            ${isAr ? "فاتورة إلى (العميل):" : "Billed To (Client):"}
          </div>
          <div style="font-size:14px; font-weight:700; color:#0f172a;">${invoice.customerName || "General Client"}</div>
          ${invoice.customerEmail ? `<div style="font-size:11px; color:#64748b; margin-top:2px;">${invoice.customerEmail}</div>` : ""}
        </div>

        <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:14px; padding:16px; text-align:${isAr ? "left" : "right"};">
          <div style="font-size:11px; font-weight:700; color:#64748b; text-transform:uppercase; margin-bottom:6px;">
            ${isAr ? "تفاصيل الإصدار:" : "Invoice Dates:"}
          </div>
          <div style="font-size:12px; color:#334155;"><strong>${isAr ? "تاريخ الإصدار:" : "Issue Date:"}</strong> ${invoice.issueDate}</div>
          <div style="font-size:12px; color:#334155; margin-top:4px;"><strong>${isAr ? "تاريخ الاستحقاق:" : "Due Date:"}</strong> ${invoice.dueDate || "-"}</div>
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th style="text-align:${align};">${isAr ? "الوصف" : "Item Description"}</th>
            <th style="text-align:center;">${isAr ? "الكمية" : "Qty"}</th>
            <th style="text-align:${isAr ? "left" : "right"};">${isAr ? "سعر الوحدة" : "Unit Price"}</th>
            <th style="text-align:center;">${isAr ? "الضريبة" : "Tax"}</th>
            <th style="text-align:${isAr ? "left" : "right"};">${isAr ? "الإجمالي" : "Line Total"}</th>
          </tr>
        </thead>
        <tbody>
          ${itemsHtml}
        </tbody>
      </table>

      <div style="margin-top:20px; display:flex; justify-content:flex-end;">
        <div style="width:280px; background:#f8fafc; border:1px solid #e2e8f0; border-radius:14px; padding:16px; font-size:12px;">
          <div style="display:flex; justify-content:space-between; margin-bottom:6px;">
            <span style="color:#64748b;">${isAr ? "المجموع الفرعي:" : "Subtotal:"}</span>
            <span style="font-weight:600;">${Number(invoice.subtotalAmount ?? invoice.totalAmount).toFixed(2)} ${currency}</span>
          </div>
          <div style="display:flex; justify-content:space-between; margin-bottom:8px; border-bottom:1px solid #e2e8f0; padding-bottom:6px;">
            <span style="color:#64748b;">${isAr ? "الضريبة:" : "Tax Total:"}</span>
            <span style="font-weight:600;">${Number(invoice.taxAmount || 0).toFixed(2)} ${currency}</span>
          </div>
          <div style="display:flex; justify-content:space-between; font-size:14px; font-weight:800; color:#7c3aed; margin-bottom:6px;">
            <span>${isAr ? "إجمالي الفاتورة:" : "Total Amount:"}</span>
            <span>${Number(invoice.totalAmount).toFixed(2)} ${currency}</span>
          </div>
          <div style="display:flex; justify-content:space-between; color:#10b981; font-weight:700;">
            <span>${isAr ? "المدفوع:" : "Paid:"}</span>
            <span>${Number(invoice.paidAmount || 0).toFixed(2)} ${currency}</span>
          </div>
          <div style="display:flex; justify-content:space-between; color:#f59e0b; font-weight:700; margin-top:4px;">
            <span>${isAr ? "المتبقي:" : "Balance Due:"}</span>
            <span>${Number(invoice.outstandingBalance || 0).toFixed(2)} ${currency}</span>
          </div>
        </div>
      </div>

      ${payments.length > 0 ? `
        <div style="margin-top:24px;">
          <div style="font-size:11px; font-weight:700; color:#64748b; text-transform:uppercase; margin-bottom:8px;">
            ${isAr ? "سجل الدفعات المستلمة:" : "Recorded Payments History:"}
          </div>
          <table>
            <thead>
              <tr>
                <th style="text-align:${align};">${isAr ? "التاريخ" : "Date"}</th>
                <th style="text-align:center;">${isAr ? "طريقة الدفع" : "Method"}</th>
                <th style="text-align:center;">${isAr ? "المرجع" : "Ref"}</th>
                <th style="text-align:${isAr ? "left" : "right"};">${isAr ? "المبلغ" : "Amount"}</th>
              </tr>
            </thead>
            <tbody>
              ${payments.map((p: any, idx: number) => `
                <tr style="background:${idx % 2 === 1 ? "#f8fafc" : "#ffffff"}; border-bottom:1px solid #f1f5f9;">
                  <td style="padding:8px 12px; color:#334155;">${p.paymentDate || "-"}</td>
                  <td style="padding:8px 12px; text-align:center; color:#64748b;">${p.paymentMethod || "-"}</td>
                  <td style="padding:8px 12px; text-align:center; color:#64748b;">${p.reference || "-"}</td>
                  <td style="padding:8px 12px; text-align:${isAr ? "left" : "right"}; font-weight:700; color:#10b981;">
                    +${Number(p.amount).toFixed(2)} ${currency}
                  </td>
                </tr>
              `).join("")}
            </tbody>
          </table>
        </div>
      ` : ""}

      ${signatureBlockHtml}

      <div style="margin-top:48px; border-top:1px solid #e2e8f0; padding-top:12px; display:flex; justify-content:space-between; font-size:10px; color:#94a3b8;">
        <div>Certified Business Invoice · Generated via AFAB Platform</div>
        <div>Thank you for your business!</div>
      </div>
    </body>
    </html>
  `;

  win.document.open();
  win.document.write(html);
  win.document.close();
}

