import 'package:flutter/foundation.dart';

/// Immutable user summary returned inside `AuthResponse.user` and extended
/// by `GET /api/v1/user/me` (`UserProfileDTO`).
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.emailVerified,
    this.businessId,
    this.businessName,
    this.currency = 'USD',
    this.country,
    required this.onboardingComplete,
    this.twoFactorEnabled = false,
    this.enableAiInsights = true,
    this.compactMode = false,
    this.autoCategorizeTransactions = true,
    this.showTips = true,
    this.planTier = 'FREE',
    this.createdAt,
    this.passwordChangedAt,
    this.lastLoginAt,
    this.lastLoginIp,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool emailVerified;
  final String? businessId;
  final String? businessName;
  final String currency;
  final String? country;
  final bool onboardingComplete;
  final bool twoFactorEnabled;
  final bool enableAiInsights;
  final bool compactMode;
  final bool autoCategorizeTransactions;
  final bool showTips;
  final String planTier;
  final DateTime? createdAt;
  final DateTime? passwordChangedAt;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    return combined.isEmpty ? email : combined;
  }

  String get initials {
    final f = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final l = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    final out = '$f$l'.toUpperCase();
    if (out.isNotEmpty) return out;
    return email.isNotEmpty ? email[0].toUpperCase() : 'A';
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    bool? emailVerified,
    String? businessId,
    String? businessName,
    String? currency,
    String? country,
    bool? onboardingComplete,
    bool? twoFactorEnabled,
    bool? enableAiInsights,
    bool? compactMode,
    bool? autoCategorizeTransactions,
    bool? showTips,
    String? planTier,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      enableAiInsights: enableAiInsights ?? this.enableAiInsights,
      compactMode: compactMode ?? this.compactMode,
      autoCategorizeTransactions:
          autoCategorizeTransactions ?? this.autoCategorizeTransactions,
      showTips: showTips ?? this.showTips,
      planTier: planTier ?? this.planTier,
      createdAt: createdAt,
      passwordChangedAt: passwordChangedAt,
      lastLoginAt: lastLoginAt,
      lastLoginIp: lastLoginIp,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseInstant(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    return UserProfile(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      emailVerified: json['emailVerified'] as bool? ?? false,
      businessId: json['businessId']?.toString(),
      businessName: json['businessName']?.toString(),
      currency: (json['currency'] as String?)?.isNotEmpty == true
          ? json['currency'].toString()
          : 'USD',
      country: json['country']?.toString(),
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
      enableAiInsights: json['enableAiInsights'] as bool? ?? true,
      compactMode: json['compactMode'] as bool? ?? false,
      autoCategorizeTransactions:
          json['autoCategorizeTransactions'] as bool? ?? true,
      showTips: json['showTips'] as bool? ?? true,
      planTier: (json['planTier'] as String?) ?? 'FREE',
      createdAt: parseInstant(json['createdAt']),
      passwordChangedAt: parseInstant(json['passwordChangedAt']),
      lastLoginAt: parseInstant(json['lastLoginAt']),
      lastLoginIp: json['lastLoginIp']?.toString(),
    );
  }
}

@immutable
class AuthResponseDto {
  const AuthResponseDto({
    this.accessToken,
    this.csrfToken,
    this.user,
    this.requiresTwoFactor = false,
    this.twoFactorToken,
    this.devOtp,
    this.verificationEmailSent = true,
  });

  final String? accessToken;
  final String? csrfToken;
  final UserProfile? user;
  final bool requiresTwoFactor;
  final String? twoFactorToken;
  final String? devOtp;
  final bool verificationEmailSent;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return AuthResponseDto(
      accessToken: json['accessToken']?.toString(),
      csrfToken: json['csrfToken']?.toString(),
      user: userRaw is Map<String, dynamic>
          ? UserProfile.fromJson(userRaw)
          : (userRaw is Map
              ? UserProfile.fromJson(Map<String, dynamic>.from(userRaw))
              : null),
      requiresTwoFactor: json['requiresTwoFactor'] as bool? ?? false,
      twoFactorToken: json['twoFactorToken']?.toString(),
      devOtp: json['devOtp']?.toString(),
      verificationEmailSent: json['verificationEmailSent'] as bool? ?? true,
    );
  }
}
