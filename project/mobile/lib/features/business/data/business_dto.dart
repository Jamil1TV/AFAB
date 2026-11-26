import 'package:flutter/foundation.dart';

/// Immutable workspace model matching backend `com.afab.business.dto.BusinessDTO`.
@immutable
class BusinessDto {
  const BusinessDto({
    required this.id,
    required this.name,
    this.country,
    required this.currency,
    this.timezone,
    this.fiscalYearStartMonth,
    this.industry,
    this.businessType,
    this.businessEmail,
    this.phoneNumber,
    this.website,
    this.taxId,
    this.addressLine,
    this.city,
    this.state,
    this.postalCode,
    this.description,
    this.logoUrl,
    this.status,
    this.onboardingComplete = false,
    this.createdAt,
    this.dateFormat,
    this.numberFormat,
    this.userRole = 'OWNER',
    this.active = false,
    this.accessMode = 'EDITABLE',
    this.editable = true,
    this.primary = false,
  });

  final String id;
  final String name;
  final String? country;
  final String currency;
  final String? timezone;
  final int? fiscalYearStartMonth;
  final String? industry;
  final String? businessType;
  final String? businessEmail;
  final String? phoneNumber;
  final String? website;
  final String? taxId;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? description;
  final String? logoUrl;
  final String? status;
  final bool onboardingComplete;
  final DateTime? createdAt;
  final String? dateFormat;
  final String? numberFormat;
  final String userRole;
  final bool active;
  final String accessMode;
  final bool editable;
  final bool primary;

  bool get isOwner => userRole.toUpperCase() == 'OWNER';
  bool get isReadOnly => !editable || accessMode.toUpperCase() == 'READ_ONLY';

  factory BusinessDto.fromJson(Map<String, dynamic> json) {
    return BusinessDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      country: json['country']?.toString(),
      currency: (json['currency'] as String?)?.isNotEmpty == true
          ? json['currency'].toString()
          : 'USD',
      timezone: json['timezone']?.toString(),
      fiscalYearStartMonth: (json['fiscalYearStartMonth'] as num?)?.toInt(),
      industry: json['industry']?.toString(),
      businessType: json['businessType']?.toString(),
      businessEmail: json['businessEmail']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      website: json['website']?.toString(),
      taxId: json['taxId']?.toString(),
      addressLine: json['addressLine']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString(),
      description: json['description']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      status: json['status']?.toString(),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      dateFormat: json['dateFormat']?.toString(),
      numberFormat: json['numberFormat']?.toString(),
      userRole: (json['userRole'] as String?) ?? 'OWNER',
      active: json['active'] as bool? ?? false,
      accessMode: (json['accessMode'] as String?) ?? 'EDITABLE',
      editable: json['editable'] as bool? ?? true,
      primary: json['primary'] as bool? ?? false,
    );
  }
}
