import 'package:flutter/foundation.dart';

@immutable
class ReceiptDto {
  const ReceiptDto({
    required this.id,
    required this.businessId,
    required this.transactionId,
    required this.originalFilename,
    required this.contentType,
    required this.fileSizeBytes,
    required this.sha256Checksum,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String transactionId;
  final String originalFilename;
  final String contentType;
  final int fileSizeBytes;
  final String sha256Checksum;
  final DateTime? createdAt;

  bool get isPdf => contentType.toLowerCase() == 'application/pdf';
  bool get isImage => contentType.toLowerCase().startsWith('image/');

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get shortTypeLabel {
    return switch (contentType.toLowerCase()) {
      'application/pdf' => 'PDF',
      'image/jpeg' => 'JPEG',
      'image/png' => 'PNG',
      'image/webp' => 'WEBP',
      _ => contentType.toUpperCase(),
    };
  }

  factory ReceiptDto.fromJson(Map<String, dynamic> json) {
    return ReceiptDto(
      id: (json['id'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      transactionId: (json['transactionId'] ?? '').toString(),
      originalFilename: (json['originalFilename'] ?? 'receipt').toString(),
      contentType: (json['contentType'] ?? 'application/octet-stream').toString(),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      sha256Checksum: (json['sha256Checksum'] ?? '').toString(),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

@immutable
class PresignedDownloadDto {
  const PresignedDownloadDto({
    required this.receiptId,
    required this.url,
    required this.expiresInSeconds,
    required this.filename,
    required this.contentType,
  });

  final String receiptId;
  final String url;
  final int expiresInSeconds;
  final String filename;
  final String contentType;

  factory PresignedDownloadDto.fromJson(Map<String, dynamic> json) {
    return PresignedDownloadDto(
      receiptId: (json['receiptId'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 300,
      filename: (json['filename'] ?? 'receipt').toString(),
      contentType: (json['contentType'] ?? 'application/octet-stream').toString(),
    );
  }
}
