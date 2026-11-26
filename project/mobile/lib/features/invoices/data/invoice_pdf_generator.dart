import 'dart:io';
import 'dart:typed_data';

import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Pure Dart A4 PDF generator for `InvoiceDTO`.
/// Fixes the Web PDF bug by reading `invoice.subtotal` and
/// `invoice.discountAmount` directly instead of nonexistent `subtotalAmount`.
abstract final class InvoicePdfGenerator {
  static Future<Uint8List> buildPdfBytes(
    InvoiceDto invoice, {
    required String businessName,
    String numberFormat = 'US',
    Uint8List? signaturePngBytes,
    String? signatoryName,
    String? signatoryTitle,
  }) async {
    final doc = pw.Document(
      title: invoice.invoiceNumber,
      author: businessName,
    );

    String fmt(Decimal amount) => MoneyFormatter.formatDecimal(
          amount,
          currency: invoice.currency,
          numberFormat: numberFormat,
        );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    businessName.isEmpty ? 'AFAB' : businessName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    invoice.invoiceNumber,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      invoice.status.apiValue,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BILL TO',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    (invoice.customerName != null &&
                            invoice.customerName!.isNotEmpty)
                        ? invoice.customerName!
                        : 'Walk-in Customer',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (invoice.customerEmail != null &&
                      invoice.customerEmail!.isNotEmpty)
                    pw.Text(
                      invoice.customerEmail!,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Issue Date: ${invoice.issueDate}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Due Date: ${invoice.dueDate}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Currency: ${invoice.currency}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            headers: const [
              'Description',
              'Qty',
              'Unit Price',
              'Tax %',
              'Line Total',
            ],
            data: [
              for (final item in invoice.items)
                [
                  item.description,
                  item.quantity.toString(),
                  fmt(item.unitPrice),
                  '${item.taxRate}%',
                  fmt(item.lineTotal),
                ],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 230,
              child: pw.Column(
                children: [
                  _pdfTotalRow('Subtotal', fmt(invoice.subtotal)),
                  _pdfTotalRow('Tax', fmt(invoice.taxAmount)),
                  if (invoice.discountAmount > Decimal.zero)
                    _pdfTotalRow('Discount', '-${fmt(invoice.discountAmount)}'),
                  pw.Divider(color: PdfColors.grey400),
                  _pdfTotalRow(
                    'Total',
                    fmt(invoice.totalAmount),
                    bold: true,
                    fontSize: 12,
                  ),
                  _pdfTotalRow('Paid', fmt(invoice.paidAmount)),
                  _pdfTotalRow(
                    'Outstanding Balance',
                    fmt(invoice.outstandingBalance),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          if (invoice.notes != null && invoice.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              'NOTES',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              invoice.notes!.trim(),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
            ),
          ],
          if (signaturePngBytes != null && signaturePngBytes.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Image(
                    pw.MemoryImage(signaturePngBytes),
                    width: 120,
                    height: 46,
                  ),
                  if (signatoryName != null && signatoryName.isNotEmpty)
                    pw.Text(
                      signatoryName,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  if (signatoryTitle != null && signatoryTitle.isNotEmpty)
                    pw.Text(
                      signatoryTitle,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _pdfTotalRow(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 10,
  }) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static Future<void> exportAndShare(
    InvoiceDto invoice, {
    required String businessName,
    String numberFormat = 'US',
    Uint8List? signaturePngBytes,
    String? signatoryName,
    String? signatoryTitle,
  }) async {
    final bytes = await buildPdfBytes(
      invoice,
      businessName: businessName,
      numberFormat: numberFormat,
      signaturePngBytes: signaturePngBytes,
      signatoryName: signatoryName,
      signatoryTitle: signatoryTitle,
    );
    final dir = await getTemporaryDirectory();
    final safeName = invoice.invoiceNumber
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final file = File('${dir.path}/$safeName.pdf');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: invoice.invoiceNumber,
      ),
    );
  }
}
