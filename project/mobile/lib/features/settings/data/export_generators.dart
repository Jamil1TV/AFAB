import 'dart:typed_data';

import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:excel_community/excel_community.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum ExportDatasetKind { master, transactions, customers, invoices }

/// Pure-Dart `.xlsx` (`excel_community`) and Arabic-capable `.pdf` (`pdf` + bundled Cairo TTF)
/// generators for `SET-07` (`DataExportSettingsScreen`).
abstract final class ExportGenerators {
  static Future<(pw.Font regular, pw.Font bold)> _loadFonts() async {
    try {
      final regData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      return (pw.Font.ttf(regData), pw.Font.ttf(boldData));
    } catch (_) {
      return (pw.Font.helvetica(), pw.Font.helveticaBold());
    }
  }

  static Uint8List buildExcelBytes({
    required ExportDatasetKind kind,
    required String businessName,
    required String displayCurrency,
    required ExportBrandingOverrides branding,
    required List<TransactionDto> transactions,
    required List<CustomerDto> customers,
    required List<InvoiceDto> invoices,
    required Decimal periodNetFlow,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();

    if (kind == ExportDatasetKind.master) {
      final overview = excel['Overview & KPIs'];
      overview.appendRow([
        TextCellValue('Business'),
        TextCellValue(businessName),
      ]);
      if (branding.fiscalMatricule.isNotEmpty) {
        overview.appendRow([
          TextCellValue('Tax ID'),
          TextCellValue(branding.fiscalMatricule),
        ]);
      }
      if (branding.businessPurpose.isNotEmpty) {
        overview.appendRow([
          TextCellValue('Purpose'),
          TextCellValue(branding.businessPurpose),
        ]);
      }
      if (branding.officialAddress.isNotEmpty) {
        overview.appendRow([
          TextCellValue('Address'),
          TextCellValue(branding.officialAddress),
        ]);
      }
      overview.appendRow([
        TextCellValue('Period Transactions'),
        IntCellValue(transactions.length),
      ]);
      overview.appendRow([
        TextCellValue('Clients Directory'),
        IntCellValue(customers.length),
      ]);
      overview.appendRow([
        TextCellValue('Period Invoices'),
        IntCellValue(invoices.length),
      ]);
      overview.appendRow([
        TextCellValue('Net Flow ($displayCurrency)'),
        TextCellValue(
          MoneyFormatter.formatDecimal(periodNetFlow, currency: displayCurrency),
        ),
      ]);
    }

    if (kind == ExportDatasetKind.master ||
        kind == ExportDatasetKind.transactions) {
      final sheet = excel['Transactions'];
      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Type'),
        TextCellValue('Description'),
        TextCellValue('Category'),
        TextCellValue('Amount'),
        TextCellValue('Currency'),
        TextCellValue('Status'),
      ]);
      for (final tx in transactions) {
        sheet.appendRow([
          TextCellValue(tx.transactionDate),
          TextCellValue(tx.type.apiValue),
          TextCellValue(tx.description),
          TextCellValue(tx.categoryName ?? ''),
          DoubleCellValue(tx.amount.toDouble()),
          TextCellValue(tx.currency),
          TextCellValue(tx.status.apiValue),
        ]);
      }
    }

    if (kind == ExportDatasetKind.master ||
        kind == ExportDatasetKind.customers) {
      final sheet = excel['Customers'];
      sheet.appendRow([
        TextCellValue('Name'),
        TextCellValue('Company'),
        TextCellValue('Email'),
        TextCellValue('Phone'),
        TextCellValue('Total Billed'),
        TextCellValue('Outstanding Balance'),
        TextCellValue('Currency'),
      ]);
      for (final c in customers) {
        sheet.appendRow([
          TextCellValue(c.name),
          TextCellValue(c.companyName ?? ''),
          TextCellValue(c.email ?? ''),
          TextCellValue(c.phone ?? ''),
          DoubleCellValue(c.invoicedAmount.toDouble()),
          DoubleCellValue(c.outstandingBalance.toDouble()),
          TextCellValue(displayCurrency),
        ]);
      }
    }

    if (kind == ExportDatasetKind.master ||
        kind == ExportDatasetKind.invoices) {
      final sheet = excel['Invoices'];
      sheet.appendRow([
        TextCellValue('Invoice #'),
        TextCellValue('Customer'),
        TextCellValue('Issue Date'),
        TextCellValue('Due Date'),
        TextCellValue('Total'),
        TextCellValue('Currency'),
        TextCellValue('Status'),
      ]);
      for (final inv in invoices) {
        sheet.appendRow([
          TextCellValue(inv.invoiceNumber),
          TextCellValue(inv.customerName ?? ''),
          TextCellValue(inv.issueDate),
          TextCellValue(inv.dueDate),
          DoubleCellValue(inv.totalAmount.toDouble()),
          TextCellValue(inv.currency),
          TextCellValue(inv.status.apiValue),
        ]);
      }
    }

    if (defaultSheet != null &&
        defaultSheet != 'Overview & KPIs' &&
        defaultSheet != 'Transactions' &&
        defaultSheet != 'Customers' &&
        defaultSheet != 'Invoices') {
      excel.delete(defaultSheet);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? const []);
  }

  static Future<Uint8List> buildPdfBytes({
    required ExportDatasetKind kind,
    required String locale,
    required String businessName,
    required String periodLabel,
    required String displayCurrency,
    required ExportBrandingOverrides branding,
    required List<TransactionDto> transactions,
    required List<CustomerDto> customers,
    required List<InvoiceDto> invoices,
    required Decimal periodNetFlow,
    Uint8List? signaturePngBytes,
    String? signatoryName,
    String? signatoryTitle,
  }) async {
    final (regFont, boldFont) = await _loadFonts();
    final isAr = locale == 'ar';
    final doc = pw.Document(
      title: '$businessName - Export',
      author: businessName,
    );

    final baseStyle = pw.TextStyle(font: regFont, fontSize: 9.5);
    final boldStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final titleStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 18,
      color: PdfColors.indigo900,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: regFont, bold: boldFont),
        build: (ctx) {
          final widgets = <pw.Widget>[
            pw.Text(businessName.isEmpty ? 'AFAB' : businessName, style: titleStyle),
            pw.SizedBox(height: 4),
            pw.Text(
              '${kind.name.toUpperCase()} · $periodLabel · ${AfabDateFormatter.formatDateTime(DateTime.now())}',
              style: baseStyle,
            ),
            if (branding.fiscalMatricule.isNotEmpty)
              pw.Text('Tax ID: ${branding.fiscalMatricule}', style: baseStyle),
            if (branding.officialAddress.isNotEmpty)
              pw.Text(branding.officialAddress, style: baseStyle),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
          ];

          if (kind == ExportDatasetKind.master) {
            widgets.add(
              pw.Text(
                'Summary: ${transactions.length} transactions | ${customers.length} customers | ${invoices.length} invoices | Net: ${MoneyFormatter.formatDecimal(periodNetFlow, currency: displayCurrency)}',
                style: boldStyle,
              ),
            );
            widgets.add(pw.SizedBox(height: 12));
          }

          if (kind == ExportDatasetKind.master ||
              kind == ExportDatasetKind.transactions) {
            widgets.add(pw.Text('Transactions', style: boldStyle));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(
              pw.TableHelper.fromTextArray(
                headerStyle: boldStyle,
                cellStyle: baseStyle,
                headers: const ['Date', 'Type', 'Description', 'Amount', 'Status'],
                data: [
                  for (final tx in transactions.take(250))
                    [
                      tx.transactionDate,
                      tx.type.apiValue,
                      tx.description,
                      MoneyFormatter.formatDecimal(
                        tx.amount,
                        currency: tx.currency,
                      ),
                      tx.status.apiValue,
                    ],
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 14));
          }

          if (kind == ExportDatasetKind.master ||
              kind == ExportDatasetKind.customers) {
            widgets.add(pw.Text('Customers', style: boldStyle));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(
              pw.TableHelper.fromTextArray(
                headerStyle: boldStyle,
                cellStyle: baseStyle,
                headers: const ['Name', 'Company', 'Email', 'Balance'],
                data: [
                  for (final c in customers.take(250))
                    [
                      c.name,
                      c.companyName ?? '',
                      c.email ?? '',
                      MoneyFormatter.formatDecimal(
                        c.outstandingBalance,
                        currency: displayCurrency,
                      ),
                    ],
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 14));
          }

          if (kind == ExportDatasetKind.master ||
              kind == ExportDatasetKind.invoices) {
            widgets.add(pw.Text('Invoices', style: boldStyle));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(
              pw.TableHelper.fromTextArray(
                headerStyle: boldStyle,
                cellStyle: baseStyle,
                headers: const ['Number', 'Customer', 'Due Date', 'Total', 'Status'],
                data: [
                  for (final inv in invoices.take(250))
                    [
                      inv.invoiceNumber,
                      inv.customerName ?? '',
                      inv.dueDate,
                      MoneyFormatter.formatDecimal(
                        inv.totalAmount,
                        currency: inv.currency,
                      ),
                      inv.status.apiValue,
                    ],
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 16));
          }

          if (branding.includeSignature && signaturePngBytes != null) {
            final imgProvider = pw.MemoryImage(signaturePngBytes);
            widgets.add(
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Image(imgProvider, width: 120, height: 48),
                    if (signatoryName != null && signatoryName.isNotEmpty)
                      pw.Text(signatoryName, style: boldStyle),
                    if (signatoryTitle != null && signatoryTitle.isNotEmpty)
                      pw.Text(signatoryTitle, style: baseStyle),
                  ],
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return doc.save();
  }
}
