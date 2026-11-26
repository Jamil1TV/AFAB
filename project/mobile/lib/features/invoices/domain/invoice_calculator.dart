import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class InvoiceLineInput {
  const InvoiceLineInput({
    this.description = '',
    this.quantity = '1',
    this.unitPrice = '',
    this.taxRate = '0',
  });

  final String description;
  final String quantity;
  final String unitPrice;
  final String taxRate;
}

@immutable
class ComputedInvoiceLine {
  const ComputedInvoiceLine({
    required this.lineSubtotal,
    required this.lineTax,
    required this.lineTotal,
  });

  final Decimal lineSubtotal;
  final Decimal lineTax;
  final Decimal lineTotal;
}

@immutable
class InvoiceTotalsPreview {
  const InvoiceTotalsPreview({
    required this.lines,
    required this.subtotal,
    required this.taxAmount,
    required this.discount,
    required this.total,
    required this.discountExceedsTotal,
  });

  final List<ComputedInvoiceLine> lines;
  final Decimal subtotal;
  final Decimal taxAmount;
  final Decimal discount;
  final Decimal total;
  final bool discountExceedsTotal;
}

/// Deterministic `Decimal` invoice arithmetic with 1:1 parity to backend
/// `InvoiceService.applyItemsAndTotals` (`HALF_UP` scale 4).
abstract final class InvoiceCalculator {
  static final Decimal _hundred = Decimal.fromInt(100);
  static final Decimal minPositive = Decimal.parse('0.0001');
  static final Decimal maxTaxRate = Decimal.fromInt(100);

  static Decimal? parseNormalized(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return Decimal.tryParse(normalized);
  }

  static ComputedInvoiceLine computeLine(InvoiceLineInput input) {
    final rawQty = parseNormalized(input.quantity) ?? Decimal.zero;
    final rawUnit = parseNormalized(input.unitPrice) ?? Decimal.zero;
    final rawTax = parseNormalized(input.taxRate) ?? Decimal.zero;

    final qty = rawQty > Decimal.zero ? rawQty.round(scale: 4) : Decimal.zero;
    final unit =
        rawUnit >= Decimal.zero ? rawUnit.round(scale: 4) : Decimal.zero;
    final taxRate = (rawTax >= Decimal.zero && rawTax <= maxTaxRate)
        ? rawTax.round(scale: 2)
        : Decimal.zero;

    final lineSub = (qty * unit).round(scale: 4);
    final lineTaxRatio = (lineSub * taxRate) / _hundred;
    final lineTax = lineTaxRatio.toDecimal(scaleOnInfinitePrecision: 8).round(
          scale: 4,
        );
    final lineTotal = (lineSub + lineTax).round(scale: 4);

    return ComputedInvoiceLine(
      lineSubtotal: lineSub,
      lineTax: lineTax,
      lineTotal: lineTotal,
    );
  }

  static InvoiceTotalsPreview computeTotals({
    required List<InvoiceLineInput> items,
    required String discountRaw,
  }) {
    var subtotal = Decimal.zero;
    var taxAmount = Decimal.zero;
    final computed = <ComputedInvoiceLine>[];

    for (final item in items) {
      final line = computeLine(item);
      computed.add(line);
      subtotal += line.lineSubtotal;
      taxAmount += line.lineTax;
    }

    subtotal = subtotal.round(scale: 4);
    taxAmount = taxAmount.round(scale: 4);

    final parsedDiscount = parseNormalized(discountRaw) ?? Decimal.zero;
    final discount =
        parsedDiscount >= Decimal.zero ? parsedDiscount.round(scale: 4) : Decimal.zero;

    final gross = (subtotal + taxAmount).round(scale: 4);
    final discountExceeds = discount > gross;
    final net = discountExceeds ? Decimal.zero : (gross - discount).round(scale: 4);

    return InvoiceTotalsPreview(
      lines: computed,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discount: discount,
      total: net,
      discountExceedsTotal: discountExceeds,
    );
  }
}
