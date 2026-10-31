package com.afab.reports.service;

import com.afab.business.Business;
import com.afab.reports.dto.CategoryShareDTO;
import com.afab.reports.dto.ProfitAndLossReportDTO;
import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Component;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Component
public class PdfReportExporter {

    private static final Color PRIMARY_COLOR = new Color(124, 58, 237); // #7c3aed Purple
    private static final Color TEXT_DARK = new Color(15, 23, 42); // #0f172a
    private static final Color BG_LIGHT = new Color(248, 250, 252); // #f8fafc
    private static final Color BORDER_COLOR = new Color(226, 232, 240); // #e2e8f0
    private static final Color SUCCESS_COLOR = new Color(16, 185, 129); // #10b981 Emerald
    private static final Color EXPENSE_COLOR = new Color(239, 68, 68); // #ef4444 Red

    public byte[] generateProfitAndLossPdf(Business business, ProfitAndLossReportDTO pnl) {
        Document document = new Document(PageSize.A4, 36, 36, 40, 40);
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            // Font configurations
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 20, TEXT_DARK);
            Font subtitleFont = FontFactory.getFont(FontFactory.HELVETICA, 10, Color.GRAY);
            Font sectionFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 13, PRIMARY_COLOR);
            Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.WHITE);
            Font cellFont = FontFactory.getFont(FontFactory.HELVETICA, 9, TEXT_DARK);
            Font cellBoldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, TEXT_DARK);

            // Document Header
            Paragraph title = new Paragraph("AFAB — Profit & Loss Statement", titleFont);
            title.setSpacingAfter(4);
            document.add(title);

            String businessName = business.getName() != null ? business.getName() : "My Business";
            String generatedAt = LocalDate.now().format(DateTimeFormatter.ISO_DATE);
            Paragraph meta = new Paragraph(
                    String.format("Business: %s  |  Period: %s  |  Currency: %s  |  Generated: %s",
                            businessName, pnl.getPeriod(), pnl.getCurrency(), generatedAt),
                    subtitleFont
            );
            meta.setSpacingAfter(18);
            document.add(meta);

            // 1. Financial Performance Summary Table
            Paragraph summaryTitle = new Paragraph("Financial Performance Summary", sectionFont);
            summaryTitle.setSpacingAfter(8);
            document.add(summaryTitle);

            PdfPTable summaryTable = new PdfPTable(4);
            summaryTable.setWidthPercentage(100);
            summaryTable.setSpacingAfter(20);
            summaryTable.setWidths(new float[]{2.5f, 2.5f, 2.5f, 2.5f});

            addHeaderCell(summaryTable, "Total Revenue", headerFont, PRIMARY_COLOR);
            addHeaderCell(summaryTable, "Total Expenses", headerFont, PRIMARY_COLOR);
            addHeaderCell(summaryTable, "Net Income", headerFont, PRIMARY_COLOR);
            addHeaderCell(summaryTable, "Profit Margin", headerFont, PRIMARY_COLOR);

            addBodyCell(summaryTable, String.format("%s %s", pnl.getCurrency(), pnl.getTotalRevenue()), cellBoldFont, SUCCESS_COLOR);
            addBodyCell(summaryTable, String.format("%s %s", pnl.getCurrency(), pnl.getTotalExpenses()), cellBoldFont, EXPENSE_COLOR);
            addBodyCell(summaryTable, String.format("%s %s", pnl.getCurrency(), pnl.getNetOperatingIncome()), cellBoldFont, TEXT_DARK);
            addBodyCell(summaryTable, String.format("%.2f%%", pnl.getProfitMarginPct()), cellBoldFont, TEXT_DARK);

            document.add(summaryTable);

            // 2. Revenue Breakdown
            if (pnl.getRevenueBreakdown() != null && !pnl.getRevenueBreakdown().isEmpty()) {
                Paragraph revTitle = new Paragraph("Revenue by Category", sectionFont);
                revTitle.setSpacingAfter(8);
                document.add(revTitle);

                PdfPTable revTable = new PdfPTable(3);
                revTable.setWidthPercentage(100);
                revTable.setSpacingAfter(18);
                revTable.setWidths(new float[]{5f, 3f, 2f});

                addHeaderCell(revTable, "Category", headerFont, new Color(16, 185, 129));
                addHeaderCell(revTable, "Amount (" + pnl.getCurrency() + ")", headerFont, new Color(16, 185, 129));
                addHeaderCell(revTable, "Share (%)", headerFont, new Color(16, 185, 129));

                for (CategoryShareDTO cat : pnl.getRevenueBreakdown()) {
                    addSimpleCell(revTable, cat.getCategoryName(), cellFont);
                    addSimpleCell(revTable, cat.getAmount().toString(), cellFont);
                    addSimpleCell(revTable, String.format("%.1f%%", cat.getPercentage()), cellFont);
                }
                document.add(revTable);
            }

            // 3. Expense Breakdown
            if (pnl.getExpenseBreakdown() != null && !pnl.getExpenseBreakdown().isEmpty()) {
                Paragraph expTitle = new Paragraph("Expenses by Category", sectionFont);
                expTitle.setSpacingAfter(8);
                document.add(expTitle);

                PdfPTable expTable = new PdfPTable(3);
                expTable.setWidthPercentage(100);
                expTable.setSpacingAfter(20);
                expTable.setWidths(new float[]{5f, 3f, 2f});

                addHeaderCell(expTable, "Category", headerFont, new Color(99, 102, 241));
                addHeaderCell(expTable, "Amount (" + pnl.getCurrency() + ")", headerFont, new Color(99, 102, 241));
                addHeaderCell(expTable, "Share (%)", headerFont, new Color(99, 102, 241));

                for (CategoryShareDTO cat : pnl.getExpenseBreakdown()) {
                    addSimpleCell(expTable, cat.getCategoryName(), cellFont);
                    addSimpleCell(expTable, cat.getAmount().toString(), cellFont);
                    addSimpleCell(expTable, String.format("%.1f%%", cat.getPercentage()), cellFont);
                }
                document.add(expTable);
            }

            // Document Footer
            Paragraph footer = new Paragraph(
                    "This report was automatically compiled by AFAB (AI Finance Assistant for Business). Financial records are tracked on a cash-basis.",
                    FontFactory.getFont(FontFactory.HELVETICA_OBLIQUE, 8, Color.GRAY)
            );
            footer.setSpacingBefore(10);
            document.add(footer);

            document.close();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate PDF report", e);
        }

        return out.toByteArray();
    }

    private void addHeaderCell(PdfPTable table, String text, Font font, Color bgColor) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setBackgroundColor(bgColor);
        cell.setPadding(8);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setBorderColor(BORDER_COLOR);
        table.addCell(cell);
    }

    private void addBodyCell(PdfPTable table, String text, Font font, Color textColor) {
        Font customFont = new Font(font);
        customFont.setColor(textColor);
        PdfPCell cell = new PdfPCell(new Phrase(text, customFont));
        cell.setBackgroundColor(BG_LIGHT);
        cell.setPadding(8);
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setBorderColor(BORDER_COLOR);
        table.addCell(cell);
    }

    private void addSimpleCell(PdfPTable table, String text, Font font) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setPadding(6);
        cell.setBorderColor(BORDER_COLOR);
        table.addCell(cell);
    }
}
