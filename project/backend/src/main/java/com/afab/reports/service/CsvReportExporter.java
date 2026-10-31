package com.afab.reports.service;

import com.afab.business.Business;
import com.afab.finance.domain.Transaction;
import com.afab.reports.dto.ProfitAndLossReportDTO;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Component
public class CsvReportExporter {

    public byte[] generateProfitAndLossCsv(Business business, ProfitAndLossReportDTO pnl, List<Transaction> transactions) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (PrintWriter writer = new PrintWriter(new OutputStreamWriter(out, StandardCharsets.UTF_8))) {
            // Write UTF-8 BOM for Microsoft Excel compatibility (especially for Arabic / Unicode characters)
            out.write(0xEF);
            out.write(0xBB);
            out.write(0xBF);

            // Report Header
            writer.println("AFAB Financial Report — Profit & Loss Statement");
            writer.println("Business:," + escapeCsv(business.getName() != null ? business.getName() : "My Business"));
            writer.println("Currency:," + escapeCsv(pnl.getCurrency()));
            writer.println("Period:," + escapeCsv(pnl.getPeriod()));
            writer.println("Generated Date:," + LocalDate.now().format(DateTimeFormatter.ISO_DATE));
            writer.println();

            // Summary Section
            writer.println("Summary Metric,Amount (" + pnl.getCurrency() + ")");
            writer.println("Total Revenue," + pnl.getTotalRevenue());
            writer.println("Total Expenses," + pnl.getTotalExpenses());
            writer.println("Net Operating Income," + pnl.getNetOperatingIncome());
            writer.println("Profit Margin (%)," + String.format("%.2f%%", pnl.getProfitMarginPct()));
            writer.println();

            // Revenue Breakdown
            if (pnl.getRevenueBreakdown() != null && !pnl.getRevenueBreakdown().isEmpty()) {
                writer.println("Revenue Category,Amount,Percentage (%)");
                for (var cat : pnl.getRevenueBreakdown()) {
                    writer.println(escapeCsv(cat.getCategoryName()) + "," + cat.getAmount() + "," + String.format("%.1f%%", cat.getPercentage()));
                }
                writer.println();
            }

            // Expense Breakdown
            if (pnl.getExpenseBreakdown() != null && !pnl.getExpenseBreakdown().isEmpty()) {
                writer.println("Expense Category,Amount,Percentage (%)");
                for (var cat : pnl.getExpenseBreakdown()) {
                    writer.println(escapeCsv(cat.getCategoryName()) + "," + cat.getAmount() + "," + String.format("%.1f%%", cat.getPercentage()));
                }
                writer.println();
            }

            // Line Items Detail
            if (transactions != null && !transactions.isEmpty()) {
                writer.println("Transaction Date,Type,Category,Description,Payment Method,Amount (" + pnl.getCurrency() + ")");
                for (Transaction t : transactions) {
                    String catName = t.getCategory() != null ? t.getCategory().getName() : "Uncategorized";
                    writer.println(String.format("%s,%s,%s,%s,%s,%s",
                            t.getTransactionDate(),
                            t.getType(),
                            escapeCsv(catName),
                            escapeCsv(t.getDescription()),
                            escapeCsv(t.getPaymentMethod()),
                            t.getAmount()
                    ));
                }
            }

            writer.flush();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate CSV report", e);
        }
        return out.toByteArray();
    }

    private String escapeCsv(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }
}
