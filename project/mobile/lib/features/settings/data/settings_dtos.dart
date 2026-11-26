import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class BusinessMemberDto {
  const BusinessMemberDto({
    required this.memberId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  final String memberId;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String status;
  final DateTime? joinedAt;

  String get fullName {
    final s = '$firstName $lastName'.trim();
    return s.isEmpty ? email : s;
  }

  factory BusinessMemberDto.fromJson(Map<String, dynamic> json) {
    final rawDt = json['joinedAt']?.toString();
    return BusinessMemberDto(
      memberId: (json['memberId'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'MEMBER').toString().toUpperCase(),
      status: (json['status'] ?? 'ACTIVE').toString().toUpperCase(),
      joinedAt:
          rawDt != null && rawDt.isNotEmpty ? DateTime.tryParse(rawDt) : null,
    );
  }
}

@immutable
class SessionDto {
  const SessionDto({
    required this.id,
    this.deviceInfo,
    this.ipAddress,
    this.createdAt,
    this.expiresAt,
    this.currentSession = false,
  });

  final String id;
  final String? deviceInfo;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool currentSession;

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return SessionDto(
      id: (json['id'] ?? '').toString(),
      deviceInfo: json['deviceInfo']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      createdAt: parseDt(json['createdAt']),
      expiresAt: parseDt(json['expiresAt']),
      currentSession: json['currentSession'] as bool? ?? false,
    );
  }
}

@immutable
class TwoFactorSetupDto {
  const TwoFactorSetupDto({
    required this.secret,
    required this.qrCodeUri,
    required this.backupCodes,
  });

  final String secret;
  final String qrCodeUri;
  final List<String> backupCodes;

  factory TwoFactorSetupDto.fromJson(Map<String, dynamic> json) {
    final rawCodes = json['backupCodes'] as List<dynamic>? ?? const [];
    return TwoFactorSetupDto(
      secret: (json['secret'] ?? '').toString(),
      qrCodeUri: (json['qrCodeUri'] ?? '').toString(),
      backupCodes: rawCodes.map((e) => e.toString()).toList(),
    );
  }
}

@immutable
class BlockingBusinessDto {
  const BlockingBusinessDto({
    required this.businessId,
    required this.businessName,
    required this.activeMemberCount,
    required this.hasOtherActiveMembers,
  });

  final String businessId;
  final String businessName;
  final int activeMemberCount;
  final bool hasOtherActiveMembers;

  factory BlockingBusinessDto.fromJson(Map<String, dynamic> json) {
    return BlockingBusinessDto(
      businessId: (json['businessId'] ?? '').toString(),
      businessName: (json['businessName'] ?? '').toString(),
      activeMemberCount: (json['activeMemberCount'] as num?)?.toInt() ?? 1,
      hasOtherActiveMembers: json['hasOtherActiveMembers'] as bool? ?? false,
    );
  }
}

@immutable
class AccountDeletionPreflightDto {
  const AccountDeletionPreflightDto({
    required this.canDelete,
    this.blockingBusinesses = const [],
    this.guidance = '',
  });

  final bool canDelete;
  final List<BlockingBusinessDto> blockingBusinesses;
  final String guidance;

  factory AccountDeletionPreflightDto.fromJson(Map<String, dynamic> json) {
    final rawBlocking =
        json['blockingBusinesses'] as List<dynamic>? ?? const [];
    return AccountDeletionPreflightDto(
      canDelete: json['canDelete'] as bool? ?? false,
      blockingBusinesses: rawBlocking
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                BlockingBusinessDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      guidance: (json['guidance'] ?? '').toString(),
    );
  }
}

@immutable
class ExportBrandingOverrides {
  const ExportBrandingOverrides({
    this.fiscalMatricule = '',
    this.businessPurpose = '',
    this.officialAddress = '',
    this.includeLogo = true,
    this.includeSignature = true,
  });

  final String fiscalMatricule;
  final String businessPurpose;
  final String officialAddress;
  final bool includeLogo;
  final bool includeSignature;

  Map<String, dynamic> toJson() => {
        'fiscalMatricule': fiscalMatricule,
        'businessPurpose': businessPurpose,
        'officialAddress': officialAddress,
        'includeLogo': includeLogo,
        'includeSignature': includeSignature,
      };

  String encode() => jsonEncode(toJson());

  factory ExportBrandingOverrides.fromJson(Map<String, dynamic> json) {
    return ExportBrandingOverrides(
      fiscalMatricule: (json['fiscalMatricule'] ?? '').toString(),
      businessPurpose: (json['businessPurpose'] ?? '').toString(),
      officialAddress: (json['officialAddress'] ?? '').toString(),
      includeLogo: json['includeLogo'] as bool? ?? true,
      includeSignature: json['includeSignature'] as bool? ?? true,
    );
  }
}

@immutable
class SignatureItem {
  const SignatureItem({
    required this.id,
    required this.label,
    required this.filePath,
    required this.signatoryName,
    required this.signatoryTitle,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String label;
  final String filePath;
  final String signatoryName;
  final String signatoryTitle;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  SignatureItem copyWith({
    String? label,
    String? filePath,
    String? signatoryName,
    String? signatoryTitle,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return SignatureItem(
      id: id,
      label: label ?? this.label,
      filePath: filePath ?? this.filePath,
      signatoryName: signatoryName ?? this.signatoryName,
      signatoryTitle: signatoryTitle ?? this.signatoryTitle,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'filePath': filePath,
        'signatoryName': signatoryName,
        'signatoryTitle': signatoryTitle,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SignatureItem.fromJson(Map<String, dynamic> json) {
    return SignatureItem(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? 'Signature').toString(),
      filePath: (json['filePath'] ?? '').toString(),
      signatoryName: (json['signatoryName'] ?? '').toString(),
      signatoryTitle:
          (json['signatoryTitle'] ?? 'Authorized Signatory').toString(),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

@immutable
class SignatureRegistry {
  const SignatureRegistry({
    this.activeId,
    this.autoApply = true,
    this.signatures = const [],
  });

  final String? activeId;
  final bool autoApply;
  final List<SignatureItem> signatures;

  SignatureItem? get activeSignature {
    if (signatures.isEmpty) return null;
    if (activeId != null) {
      final hit = signatures.where((s) => s.id == activeId).firstOrNull;
      if (hit != null) return hit;
    }
    return signatures.where((s) => s.isDefault).firstOrNull ?? signatures.first;
  }

  SignatureRegistry copyWith({
    String? activeId,
    bool clearActiveId = false,
    bool? autoApply,
    List<SignatureItem>? signatures,
  }) {
    return SignatureRegistry(
      activeId: clearActiveId ? null : (activeId ?? this.activeId),
      autoApply: autoApply ?? this.autoApply,
      signatures: signatures ?? this.signatures,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeId': activeId,
        'autoApply': autoApply,
        'signatures': signatures.map((e) => e.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  factory SignatureRegistry.fromJson(Map<String, dynamic> json) {
    final rawList = json['signatures'] as List<dynamic>? ?? const [];
    return SignatureRegistry(
      activeId: json['activeId']?.toString(),
      autoApply: json['autoApply'] as bool? ?? true,
      signatures: rawList
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => SignatureItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}
