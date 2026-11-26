import 'dart:convert';
import 'dart:io';

import 'package:afab_mobile/core/money/currency_minor_units.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Generates RFC-4180 UTF-8 BOM CSV exports preserving ISO-4217 minor units
/// (e.g., 3 decimals for `TND`/`KWD`, 0 for `JPY`, 2 default) and shares cleanly.
abstract final class CsvExporter {
  static String escapeField(String? raw) {
    final value = raw ?? '';
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String buildTransactionsCsv(
    List<TransactionDto> rows, {
    required String fallbackCurrency,
  }) {
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(
      [
        'ID',
        'Date',
        'Type',
        'Description',
        'Category',
        'Amount',
        'Currency',
        'Original Amount',
        'Original Currency',
        'Exchange Rate',
        'Payment Method',
        'Status',
        'Tax Deductible',
        'Tax Rate (%)',
        'Split',
        'Notes',
      ].map(escapeField).join(','),
    );

    for (final tx in rows) {
      final baseCurr =
          tx.resolvedBaseCurrency.isNotEmpty ? tx.resolvedBaseCurrency : fallbackCurrency;
      final basePrecision = CurrencyMinorUnits.decimalsFor(baseCurr);
      final formattedAmount =
          tx.amount.round(scale: basePrecision).toStringAsFixed(basePrecision);

      final origCurr = tx.originalCurrency ?? baseCurr;
      final origPrecision = CurrencyMinorUnits.decimalsFor(origCurr);
      final formattedOrig = tx.originalAmount != null
          ? tx.originalAmount!
              .round(scale: origPrecision)
              .toStringAsFixed(origPrecision)
          : formattedAmount;

      buffer.writeln(
        [
          tx.id,
          tx.transactionDate,
          tx.type.apiValue,
          tx.description,
          tx.categoryName ?? (tx.isSplit ? 'Split' : 'Uncategorized'),
          formattedAmount,
          baseCurr,
          formattedOrig,
          origCurr,
          tx.exchangeRate?.toString() ?? '1',
          tx.paymentMethod.apiValue,
          tx.status.apiValue,
          tx.taxDeductible ? 'Yes' : 'No',
          tx.taxRate?.toString() ?? '',
          tx.isSplit ? 'Yes' : 'No',
          tx.notes ?? '',
        ].map(escapeField).join(','),
      );
    }

    return buffer.toString();
  }

  static Future<void> shareCsv({
    required String csvContent,
    required String filename,
    String? subject,
  }) async {
    final dir = await getTemporaryDirectory();
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(utf8.encode(csvContent), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: subject,
      ),
    );
  }
}
