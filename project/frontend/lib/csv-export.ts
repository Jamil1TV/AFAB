import { TransactionItem } from "./api/transactions";

export function exportTransactionsToCSV(
  transactions: TransactionItem[],
  currency: string = "USD",
  filenamePrefix: string = "AFAB_Transactions"
) {
  if (!transactions || transactions.length === 0) {
    alert("No transactions available to export.");
    return;
  }

  const headers = [
    "Transaction ID",
    "Date",
    "Description",
    "Type",
    "Category",
    "Amount",
    "Currency",
    "Payment Method",
    "Status",
    "Tax Deductible",
    "Split Transaction",
    "Notes"
  ];

  const escapeCSV = (val: string | number | boolean | null | undefined): string => {
    if (val === null || val === undefined) return '""';
    const str = String(val).replace(/"/g, '""');
    return `"${str}"`;
  };

  const rows = transactions.map((t) => [
    escapeCSV(t.id),
    escapeCSV(t.transactionDate),
    escapeCSV(t.description),
    escapeCSV(t.type),
    escapeCSV(t.categoryName || "Uncategorized"),
    escapeCSV(t.amount.toFixed(2)),
    escapeCSV(t.currency || currency),
    escapeCSV(t.paymentMethod || "CARD"),
    escapeCSV(t.status || "COMPLETED"),
    escapeCSV(t.taxDeductible ? "YES" : "NO"),
    escapeCSV(t.isSplit ? "YES" : "NO"),
    escapeCSV(t.notes || "")
  ]);

  const csvContent = [
    headers.join(","),
    ...rows.map((r) => r.join(","))
  ].join("\r\n");

  // UTF-8 BOM (\uFEFF) ensures Excel correctly recognizes UTF-8 (Arabic & foreign characters)
  const blob = new Blob(["\uFEFF" + csvContent], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  const dateStr = new Date().toISOString().split("T")[0];

  link.setAttribute("href", url);
  link.setAttribute("download", `${filenamePrefix}_${dateStr}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
}
