import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';

enum InvoiceStatus {
  draft('DRAFT'),
  sent('SENT'),
  unpaid('UNPAID'),
  partiallyPaid('PARTIALLY_PAID'),
  paid('PAID'),
  overdue('OVERDUE'),
  cancelled('CANCELLED');

  const InvoiceStatus(this.apiValue);
  final String apiValue;

  static InvoiceStatus fromApi(String? raw) {
    final norm = (raw ?? 'DRAFT').toUpperCase().trim();
    return InvoiceStatus.values.firstWhere(
      (e) => e.apiValue == norm,
      orElse: () => InvoiceStatus.draft,
    );
  }

  bool get isPayable =>
      this == InvoiceStatus.sent ||
      this == InvoiceStatus.unpaid ||
      this == InvoiceStatus.partiallyPaid ||
      this == InvoiceStatus.overdue;

  AfabBadgeVariant get badgeVariant => switch (this) {
        InvoiceStatus.draft => AfabBadgeVariant.neutral,
        InvoiceStatus.sent => AfabBadgeVariant.info,
        InvoiceStatus.unpaid => AfabBadgeVariant.warning,
        InvoiceStatus.partiallyPaid => AfabBadgeVariant.primary,
        InvoiceStatus.paid => AfabBadgeVariant.success,
        InvoiceStatus.overdue => AfabBadgeVariant.danger,
        InvoiceStatus.cancelled => AfabBadgeVariant.neutral,
      };

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      InvoiceStatus.draft => l10n.invoicesStatusDraft,
      InvoiceStatus.sent => l10n.invoicesStatusSent,
      InvoiceStatus.unpaid => l10n.invoicesStatusUnpaid,
      InvoiceStatus.partiallyPaid => l10n.invoicesStatusPartiallyPaid,
      InvoiceStatus.paid => l10n.invoicesStatusPaid,
      InvoiceStatus.overdue => l10n.invoicesStatusOverdue,
      InvoiceStatus.cancelled => l10n.invoicesStatusCancelled,
    };
  }
}

@immutable
class InvoiceItemDto {
  const InvoiceItemDto({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.lineSubtotal,
    required this.lineTax,
    required this.lineTotal,
  });

  final String id;
  final String description;
  final Decimal quantity;
  final Decimal unitPrice;
  final Decimal taxRate;
  final Decimal lineSubtotal;
  final Decimal lineTax;
  final Decimal lineTotal;

  factory InvoiceItemDto.fromJson(Map<String, dynamic> json) {
    return InvoiceItemDto(
      id: (json['id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      quantity: MoneyFormatter.parseDecimal(json['quantity']),
      unitPrice: MoneyFormatter.parseDecimal(json['unitPrice']),
      taxRate: MoneyFormatter.parseDecimal(json['taxRate']),
      lineSubtotal: MoneyFormatter.parseDecimal(json['lineSubtotal']),
      lineTax: MoneyFormatter.parseDecimal(json['lineTax']),
      lineTotal: MoneyFormatter.parseDecimal(json['lineTotal']),
    );
  }
}

@immutable
class PaymentDto {
  const PaymentDto({
    required this.id,
    required this.invoiceId,
    this.incomeTransactionId,
    this.idempotencyKey,
    required this.amount,
    required this.currency,
    this.convertedBaseAmount,
    this.baseCurrency,
    this.exchangeRate,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String invoiceId;
  final String? incomeTransactionId;
  final String? idempotencyKey;
  final Decimal amount;
  final String currency;
  final Decimal? convertedBaseAmount;
  final String? baseCurrency;
  final Decimal? exchangeRate;
  final String paymentDate;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final DateTime? createdAt;

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: (json['id'] ?? '').toString(),
      invoiceId: (json['invoiceId'] ?? '').toString(),
      incomeTransactionId: json['incomeTransactionId']?.toString(),
      idempotencyKey: json['idempotencyKey']?.toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      currency: (json['currency'] ?? 'USD').toString(),
      convertedBaseAmount: json['convertedBaseAmount'] != null
          ? MoneyFormatter.parseDecimal(json['convertedBaseAmount'])
          : null,
      baseCurrency: json['baseCurrency']?.toString(),
      exchangeRate: json['exchangeRate'] != null
          ? MoneyFormatter.parseDecimal(json['exchangeRate'])
          : null,
      paymentDate: (json['paymentDate'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? 'BANK_TRANSFER').toString(),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

@immutable
class InvoiceDto {
  const InvoiceDto({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.customerEmail,
    required this.status,
    required this.storedStatus,
    required this.overdue,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingBalance,
    this.notes,
    this.issuedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.payments = const [],
  });

  final String id;
  final String businessId;
  final String invoiceNumber;
  final String? customerId;
  final String? customerName;
  final String? customerEmail;
  final InvoiceStatus status;
  final InvoiceStatus storedStatus;
  final bool overdue;
  final String issueDate;
  final String dueDate;
  final String currency;
  final Decimal subtotal;
  final Decimal discountAmount;
  final Decimal taxAmount;
  final Decimal totalAmount;
  final Decimal paidAmount;
  final Decimal outstandingBalance;
  final String? notes;
  final DateTime? issuedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<InvoiceItemDto> items;
  final List<PaymentDto> payments;

  factory InvoiceDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawPayments = json['payments'] as List<dynamic>? ?? const [];
    return InvoiceDto(
      id: (json['id'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString(),
      customerEmail: json['customerEmail']?.toString(),
      status: InvoiceStatus.fromApi(json['status']?.toString()),
      storedStatus: InvoiceStatus.fromApi(
        (json['storedStatus'] ?? json['status'])?.toString(),
      ),
      overdue: json['overdue'] as bool? ?? false,
      issueDate: (json['issueDate'] ?? '').toString(),
      dueDate: (json['dueDate'] ?? '').toString(),
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      subtotal: MoneyFormatter.parseDecimal(json['subtotal']),
      discountAmount: MoneyFormatter.parseDecimal(json['discountAmount']),
      taxAmount: MoneyFormatter.parseDecimal(json['taxAmount']),
      totalAmount: MoneyFormatter.parseDecimal(json['totalAmount']),
      paidAmount: MoneyFormatter.parseDecimal(json['paidAmount']),
      outstandingBalance: MoneyFormatter.parseDecimal(
        json['outstandingBalance'],
      ),
      notes: json['notes']?.toString(),
      issuedAt: json['issuedAt'] is String
          ? DateTime.tryParse(json['issuedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] is String
          ? DateTime.tryParse(json['cancelledAt'] as String)
          : null,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(InvoiceItemDto.fromJson)
          .toList(),
      payments: rawPayments
          .whereType<Map<String, dynamic>>()
          .map(PaymentDto.fromJson)
          .toList(),
    );
  }
}

@immutable
class InvoicePageDto {
  const InvoicePageDto({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.currency,
  });

  final List<InvoiceDto> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final Decimal totalInvoiced;
  final Decimal totalPaid;
  final Decimal totalOutstanding;
  final String currency;

  factory InvoicePageDto.fromJson(Map<String, dynamic> json) {
    final raw = json['content'] as List<dynamic>? ?? const [];
    return InvoicePageDto(
      content: raw
          .whereType<Map<String, dynamic>>()
          .map(InvoiceDto.fromJson)
          .toList(),
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 15,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalInvoiced: MoneyFormatter.parseDecimal(json['totalInvoiced']),
      totalPaid: MoneyFormatter.parseDecimal(json['totalPaid']),
      totalOutstanding: MoneyFormatter.parseDecimal(json['totalOutstanding']),
      currency: (json['currency'] ?? 'USD').toString(),
    );
  }
}

@immutable
class InvoiceStatusBreakdownItemDto {
  const InvoiceStatusBreakdownItemDto({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  final String name;
  final Decimal amount;
  final double percentage;
  final String color;

  factory InvoiceStatusBreakdownItemDto.fromJson(Map<String, dynamic> json) {
    return InvoiceStatusBreakdownItemDto(
      name: (json['name'] ?? '').toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      color: (json['color'] ?? '#3B82F6').toString(),
    );
  }
}

@immutable
class UpcomingInvoiceItemDto {
  const UpcomingInvoiceItemDto({
    required this.invoiceId,
    required this.customerName,
    this.email,
    required this.dueDate,
    required this.amount,
  });

  /// Backend `InvoiceSummaryDTO.UpcomingInvoiceItem.invoiceId` actually holds
  /// the human-readable `invoiceNumber` (`INV-YYYY-XXXX`), not the UUID!
  final String invoiceId;
  final String customerName;
  final String? email;
  final String dueDate;
  final Decimal amount;

  factory UpcomingInvoiceItemDto.fromJson(Map<String, dynamic> json) {
    return UpcomingInvoiceItemDto(
      invoiceId: (json['invoiceId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      email: json['email']?.toString(),
      dueDate: (json['dueDate'] ?? '').toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
    );
  }
}

@immutable
class InvoiceSummaryDto {
  const InvoiceSummaryDto({
    required this.totalInvoices,
    required this.paidInvoices,
    required this.pendingInvoices,
    required this.overdueInvoices,
    required this.totalInvoiceAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.overdueAmount,
    required this.currency,
    required this.statusBreakdown,
    required this.upcomingDueList,
  });

  final int totalInvoices;
  final int paidInvoices;
  final int pendingInvoices;
  final int overdueInvoices;
  final Decimal totalInvoiceAmount;
  final Decimal paidAmount;
  final Decimal pendingAmount;
  final Decimal overdueAmount;
  final String currency;
  final List<InvoiceStatusBreakdownItemDto> statusBreakdown;
  final List<UpcomingInvoiceItemDto> upcomingDueList;

  factory InvoiceSummaryDto.fromJson(Map<String, dynamic> json) {
    final bd = json['statusBreakdown'] as List<dynamic>? ?? const [];
    final up = json['upcomingDueList'] as List<dynamic>? ?? const [];
    return InvoiceSummaryDto(
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      paidInvoices: (json['paidInvoices'] as num?)?.toInt() ?? 0,
      pendingInvoices: (json['pendingInvoices'] as num?)?.toInt() ?? 0,
      overdueInvoices: (json['overdueInvoices'] as num?)?.toInt() ?? 0,
      totalInvoiceAmount: MoneyFormatter.parseDecimal(
        json['totalInvoiceAmount'],
      ),
      paidAmount: MoneyFormatter.parseDecimal(json['paidAmount']),
      pendingAmount: MoneyFormatter.parseDecimal(json['pendingAmount']),
      overdueAmount: MoneyFormatter.parseDecimal(json['overdueAmount']),
      currency: (json['currency'] ?? 'USD').toString(),
      statusBreakdown: bd
          .whereType<Map<String, dynamic>>()
          .map(InvoiceStatusBreakdownItemDto.fromJson)
          .toList(),
      upcomingDueList: up
          .whereType<Map<String, dynamic>>()
          .map(UpcomingInvoiceItemDto.fromJson)
          .toList(),
    );
  }
}

@immutable
class InvoiceItemRequestDto {
  const InvoiceItemRequestDto({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
  });

  final String description;
  final Decimal quantity;
  final Decimal unitPrice;
  final Decimal taxRate;

  Map<String, dynamic> toJson() => {
        'description': description.trim(),
        'quantity': quantity.toString(),
        'unitPrice': unitPrice.toString(),
        'taxRate': taxRate.toString(),
      };
}

@immutable
class CreateInvoiceRequestDto {
  const CreateInvoiceRequestDto({
    this.customerId,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.discountAmount,
    this.notes,
    required this.items,
  });

  final String? customerId;
  final String issueDate; // YYYY-MM-DD
  final String dueDate; // YYYY-MM-DD
  final String currency;
  final Decimal discountAmount;
  final String? notes;
  final List<InvoiceItemRequestDto> items;

  Map<String, dynamic> toJson() {
    final cleanNotes = notes?.trim();
    return {
      if (customerId != null && customerId!.isNotEmpty) 'customerId': customerId,
      'issueDate': issueDate,
      'dueDate': dueDate,
      'currency': currency.toUpperCase(),
      'discountAmount': discountAmount.toString(),
      if (cleanNotes != null && cleanNotes.isNotEmpty) 'notes': cleanNotes,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

@immutable
class RecordPaymentRequestDto {
  const RecordPaymentRequestDto({
    required this.amount,
    required this.currency,
    required this.paymentDate,
    this.paymentMethod = 'BANK_TRANSFER',
    this.reference,
    this.notes,
    required this.idempotencyKey,
    this.exchangeRate,
  });

  final Decimal amount;
  final String currency;
  final String paymentDate; // YYYY-MM-DD
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final String idempotencyKey;
  final Decimal? exchangeRate;

  Map<String, dynamic> toJson() {
    final cleanRef = reference?.trim();
    final cleanNotes = notes?.trim();
    return {
      'amount': amount.toString(),
      'currency': currency.toUpperCase(),
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod,
      if (cleanRef != null && cleanRef.isNotEmpty) 'reference': cleanRef,
      if (cleanNotes != null && cleanNotes.isNotEmpty) 'notes': cleanNotes,
      'idempotencyKey': idempotencyKey,
      if (exchangeRate != null) 'exchangeRate': exchangeRate.toString(),
    };
  }
}
