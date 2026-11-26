import 'package:afab_mobile/core/money/currency_minor_units.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

/// Immutable workspace item matching `BusinessAllocationDTO.BusinessAllocationItemDTO`.
@immutable
class BusinessAllocationItemDto {
  const BusinessAllocationItemDto({
    required this.id,
    required this.name,
    required this.currency,
    this.industry,
    this.country,
    this.logoUrl,
    this.accessMode = 'EDITABLE',
    this.editable = true,
    this.primary = false,
    this.active = false,
    this.selectedForPending = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String currency;
  final String? industry;
  final String? country;
  final String? logoUrl;
  final String accessMode;
  final bool editable;
  final bool primary;
  final bool active;
  final bool selectedForPending;
  final DateTime? createdAt;

  bool get isReadOnly => !editable || accessMode.toUpperCase() == 'READ_ONLY';

  factory BusinessAllocationItemDto.fromJson(Map<String, dynamic> json) {
    final rawDt = json['createdAt']?.toString();
    return BusinessAllocationItemDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      currency: (json['currency'] as String?)?.isNotEmpty == true
          ? json['currency'].toString().toUpperCase()
          : 'USD',
      industry: json['industry']?.toString(),
      country: json['country']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      accessMode: (json['accessMode'] ?? 'EDITABLE').toString(),
      editable: json['editable'] as bool? ?? true,
      primary: json['primary'] as bool? ?? false,
      active: json['active'] as bool? ?? false,
      selectedForPending: json['selectedForPending'] as bool? ?? false,
      createdAt:
          rawDt != null && rawDt.isNotEmpty ? DateTime.tryParse(rawDt) : null,
    );
  }
}

/// Matching `BusinessAllocationDTO.java`.
@immutable
class BusinessAllocationDto {
  const BusinessAllocationDto({
    required this.currentPlanSlug,
    required this.currentPlanName,
    required this.editableLimit,
    required this.editableCount,
    required this.readOnlyCount,
    required this.totalOwnedCount,
    required this.allocationAttentionRequired,
    this.pendingPlanSlug,
    this.pendingPlanName,
    this.pendingEditableLimit,
    this.pendingChangeEffectiveAt,
    this.pendingBusinessIds = const [],
    this.businesses = const [],
  });

  final String currentPlanSlug;
  final String currentPlanName;
  final int editableLimit;
  final int editableCount;
  final int readOnlyCount;
  final int totalOwnedCount;
  final bool allocationAttentionRequired;
  final String? pendingPlanSlug;
  final String? pendingPlanName;
  final int? pendingEditableLimit;
  final DateTime? pendingChangeEffectiveAt;
  final List<String> pendingBusinessIds;
  final List<BusinessAllocationItemDto> businesses;

  factory BusinessAllocationDto.fromJson(Map<String, dynamic> json) {
    final rawPendingIds = json['pendingBusinessIds'] as List<dynamic>? ?? const [];
    final rawBiz = json['businesses'] as List<dynamic>? ?? const [];
    final rawEff = json['pendingChangeEffectiveAt']?.toString();
    return BusinessAllocationDto(
      currentPlanSlug:
          (json['currentPlanSlug'] ?? 'free').toString().toLowerCase(),
      currentPlanName: (json['currentPlanName'] ?? 'Free').toString(),
      editableLimit: (json['editableLimit'] as num?)?.toInt() ?? 1,
      editableCount: (json['editableCount'] as num?)?.toInt() ?? 0,
      readOnlyCount: (json['readOnlyCount'] as num?)?.toInt() ?? 0,
      totalOwnedCount: (json['totalOwnedCount'] as num?)?.toInt() ?? 0,
      allocationAttentionRequired:
          json['allocationAttentionRequired'] as bool? ?? false,
      pendingPlanSlug: json['pendingPlanSlug']?.toString().toLowerCase(),
      pendingPlanName: json['pendingPlanName']?.toString(),
      pendingEditableLimit: (json['pendingEditableLimit'] as num?)?.toInt(),
      pendingChangeEffectiveAt: rawEff != null && rawEff.isNotEmpty
          ? DateTime.tryParse(rawEff)
          : null,
      pendingBusinessIds: rawPendingIds.map((e) => e.toString()).toList(),
      businesses: rawBiz
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => BusinessAllocationItemDto.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

/// Matching `BillingHistoryResponse.SubscriptionHistoryItemDTO`.
@immutable
class SubscriptionHistoryItemDto {
  const SubscriptionHistoryItemDto({
    required this.id,
    required this.eventType,
    this.fromPlanSlug,
    this.toPlanSlug,
    this.fromStatus,
    this.toStatus,
    this.effectiveAt,
    this.details,
    this.createdAt,
  });

  final String id;
  final String eventType;
  final String? fromPlanSlug;
  final String? toPlanSlug;
  final String? fromStatus;
  final String? toStatus;
  final DateTime? effectiveAt;
  final String? details;
  final DateTime? createdAt;

  factory SubscriptionHistoryItemDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return SubscriptionHistoryItemDto(
      id: (json['id'] ?? '').toString(),
      eventType: (json['eventType'] ?? '').toString(),
      fromPlanSlug: json['fromPlanSlug']?.toString(),
      toPlanSlug: json['toPlanSlug']?.toString(),
      fromStatus: json['fromStatus']?.toString(),
      toStatus: json['toStatus']?.toString(),
      effectiveAt: parseDt(json['effectiveAt']),
      details: json['details']?.toString(),
      createdAt: parseDt(json['createdAt']),
    );
  }
}

/// Matching `BillingHistoryResponse.PaymentHistoryItemDTO`.
@immutable
class PaymentHistoryItemDto {
  const PaymentHistoryItemDto({
    required this.id,
    this.stripeInvoiceId,
    required this.amountCents,
    required this.currency,
    required this.status,
    this.failureReason,
    this.hostedInvoiceUrl,
    this.invoicePdfUrl,
    this.paidAt,
    this.failedAt,
    this.createdAt,
  });

  final String id;
  final String? stripeInvoiceId;
  final int amountCents;
  final String currency;
  final String status;
  final String? failureReason;
  final String? hostedInvoiceUrl;
  final String? invoicePdfUrl;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? createdAt;

  /// Converts Stripe smallest-unit integer to `Decimal` using ISO-4217 minor units
  /// (0 decimals for JPY/KRW, 3 decimals for TND/KWD/BHD/OMR, 2 decimals otherwise).
  Decimal get amountDecimal {
    final scale = CurrencyMinorUnits.decimalsFor(currency);
    if (scale == 0) return Decimal.fromInt(amountCents);
    var divisor = 1;
    for (var i = 0; i < scale; i++) {
      divisor *= 10;
    }
    return (Decimal.fromInt(amountCents) / Decimal.fromInt(divisor))
        .toDecimal(scaleOnInfinitePrecision: scale);
  }

  factory PaymentHistoryItemDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return PaymentHistoryItemDto(
      id: (json['id'] ?? '').toString(),
      stripeInvoiceId: json['stripeInvoiceId']?.toString(),
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?)?.isNotEmpty == true
          ? json['currency'].toString().toUpperCase()
          : 'USD',
      status: (json['status'] ?? 'OPEN').toString().toUpperCase(),
      failureReason: json['failureReason']?.toString(),
      hostedInvoiceUrl: json['hostedInvoiceUrl']?.toString(),
      invoicePdfUrl: json['invoicePdfUrl']?.toString(),
      paidAt: parseDt(json['paidAt']),
      failedAt: parseDt(json['failedAt']),
      createdAt: parseDt(json['createdAt']),
    );
  }
}

@immutable
class BillingHistoryResponseDto {
  const BillingHistoryResponseDto({
    this.subscriptionHistory = const [],
    this.paymentHistory = const [],
  });

  final List<SubscriptionHistoryItemDto> subscriptionHistory;
  final List<PaymentHistoryItemDto> paymentHistory;

  factory BillingHistoryResponseDto.fromJson(Map<String, dynamic> json) {
    final rawSub = json['subscriptionHistory'] as List<dynamic>? ?? const [];
    final rawPay = json['paymentHistory'] as List<dynamic>? ?? const [];
    return BillingHistoryResponseDto(
      subscriptionHistory: rawSub
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => SubscriptionHistoryItemDto.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      paymentHistory: rawPay
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                PaymentHistoryItemDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

@immutable
class CheckoutSessionResponseDto {
  const CheckoutSessionResponseDto({
    this.sessionId,
    this.url,
    required this.mode,
  });

  final String? sessionId;
  final String? url;
  final String mode; // CHECKOUT or PORTAL

  factory CheckoutSessionResponseDto.fromJson(Map<String, dynamic> json) {
    return CheckoutSessionResponseDto(
      sessionId: json['sessionId']?.toString(),
      url: json['url']?.toString(),
      mode: (json['mode'] ?? 'CHECKOUT').toString().toUpperCase(),
    );
  }
}

@immutable
class PortalSessionResponseDto {
  const PortalSessionResponseDto({required this.url});

  final String url;

  factory PortalSessionResponseDto.fromJson(Map<String, dynamic> json) {
    return PortalSessionResponseDto(url: (json['url'] ?? '').toString());
  }
}

@immutable
class UpgradeSubscriptionResponseDto {
  const UpgradeSubscriptionResponseDto({
    required this.mode,
    this.sessionId,
    this.url,
    this.snapshotJson,
  });

  final String mode; // DIRECT_UPGRADE, CHECKOUT, or PORTAL
  final String? sessionId;
  final String? url;
  final Map<String, dynamic>? snapshotJson;

  factory UpgradeSubscriptionResponseDto.fromJson(Map<String, dynamic> json) {
    final rawSnap = json['snapshot'];
    return UpgradeSubscriptionResponseDto(
      mode: (json['mode'] ?? 'CHECKOUT').toString().toUpperCase(),
      sessionId: json['sessionId']?.toString(),
      url: json['url']?.toString(),
      snapshotJson:
          rawSnap is Map ? Map<String, dynamic>.from(rawSnap) : null,
    );
  }
}
