import 'package:flutter/foundation.dart';

@immutable
class CategoryDto {
  const CategoryDto({
    required this.id,
    this.businessId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.systemDefault,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? businessId;
  final String name;
  final String type; // 'INCOME' | 'EXPENSE'
  final String? icon;
  final String? color;
  final bool systemDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isIncome => type.toUpperCase() == 'INCOME';
  bool get isExpense => type.toUpperCase() == 'EXPENSE';

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final businessId = json['businessId']?.toString();
    // Java `isSystemDefault()` serializes via Jackson as `"systemDefault"`.
    final isSys = (json['systemDefault'] as bool?) ??
        (json['isSystemDefault'] as bool?) ??
        (businessId == null || businessId.isEmpty);
    return CategoryDto(
      id: (json['id'] ?? '').toString(),
      businessId: businessId,
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'EXPENSE').toString().toUpperCase(),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
      systemDefault: isSys,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
