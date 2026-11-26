import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CategoryPickerIconOption {
  const CategoryPickerIconOption({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}

class CategoryColorSwatchOption {
  const CategoryColorSwatchOption({
    required this.hex,
    required this.semanticName,
  });

  final String hex;
  final String semanticName;
}

/// Maps backend category icon identifiers onto Lucide vector icons and provides
/// the 10-icon picker grid and 8 pure-hex swatches (never storing `var(...)`).
abstract final class CategoryIconMapper {
  static const List<CategoryPickerIconOption> pickerIcons = [
    CategoryPickerIconOption(name: 'Tag', icon: LucideIcons.tag),
    CategoryPickerIconOption(name: 'DollarSign', icon: LucideIcons.dollarSign),
    CategoryPickerIconOption(name: 'Briefcase', icon: LucideIcons.briefcase),
    CategoryPickerIconOption(name: 'TrendingUp', icon: LucideIcons.trendingUp),
    CategoryPickerIconOption(name: 'Building', icon: LucideIcons.building2),
    CategoryPickerIconOption(name: 'Laptop', icon: LucideIcons.laptop),
    CategoryPickerIconOption(name: 'Users', icon: LucideIcons.users),
    CategoryPickerIconOption(name: 'Package', icon: LucideIcons.package),
    CategoryPickerIconOption(name: 'Plane', icon: LucideIcons.plane),
    CategoryPickerIconOption(name: 'ShoppingBag', icon: LucideIcons.shoppingBag),
  ];

  static const List<CategoryColorSwatchOption> pickerColorSwatches = [
    CategoryColorSwatchOption(hex: '#10B981', semanticName: 'Emerald'),
    CategoryColorSwatchOption(hex: '#06B6D4', semanticName: 'Cyan'),
    CategoryColorSwatchOption(hex: '#8B5CF6', semanticName: 'Violet'),
    CategoryColorSwatchOption(hex: '#3B82F6', semanticName: 'Blue'),
    CategoryColorSwatchOption(hex: '#F59E0B', semanticName: 'Amber'),
    CategoryColorSwatchOption(hex: '#EF4444', semanticName: 'Red'),
    CategoryColorSwatchOption(hex: '#EC4899', semanticName: 'Pink'),
    CategoryColorSwatchOption(hex: '#64748B', semanticName: 'Slate'),
  ];

  static final Map<String, IconData> _byName = {
    'tag': LucideIcons.tag,
    'dollarsign': LucideIcons.dollarSign,
    'briefcase': LucideIcons.briefcase,
    'trendingup': LucideIcons.trendingUp,
    'building': LucideIcons.building2,
    'building2': LucideIcons.building2,
    'laptop': LucideIcons.laptop,
    'users': LucideIcons.users,
    'package': LucideIcons.package,
    'plane': LucideIcons.plane,
    'shoppingbag': LucideIcons.shoppingBag,
    'utensils': LucideIcons.utensils,
    'car': LucideIcons.car,
    'home': LucideIcons.home,
    'house': LucideIcons.home,
    'zap': LucideIcons.zap,
    'wifi': LucideIcons.wifi,
    'creditcard': LucideIcons.creditCard,
    'receipt': LucideIcons.receipt,
  };

  static IconData resolve(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) {
      return LucideIcons.tag;
    }
    final normalized = rawName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return _byName[normalized] ?? LucideIcons.tag;
  }
}
