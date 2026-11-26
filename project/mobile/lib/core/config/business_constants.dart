class CountryOption {
  const CountryOption({
    required this.code,
    required this.nameEn,
    required this.nameAr,
  });

  final String code;
  final String nameEn;
  final String nameAr;

  String label(String locale) => locale == 'ar' ? nameAr : nameEn;
}

class LocalizedKeyOption {
  const LocalizedKeyOption({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  final String id;
  final String nameEn;
  final String nameAr;

  String label(String locale) => locale == 'ar' ? nameAr : nameEn;
}

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.nameEn,
    required this.nameAr,
  });

  final String code;
  final String symbol;
  final String nameEn;
  final String nameAr;

  String label(String locale) =>
      '$code ($symbol) — ${locale == 'ar' ? nameAr : nameEn}';
}

/// Centralized EN/AR business setup registries matching
/// `Web/project/frontend/lib/constants/business-data.ts` plus Tunisia (`TN`, `TND`, `Africa/Tunis`),
/// `CHF`, and `TRY` used across backend FX & onboarding flows.
abstract final class BusinessConstants {
  static const List<CountryOption> countries = [
    CountryOption(code: 'US', nameEn: 'United States', nameAr: 'الولايات المتحدة'),
    CountryOption(
      code: 'AE',
      nameEn: 'United Arab Emirates',
      nameAr: 'الإمارات العربية المتحدة',
    ),
    CountryOption(
      code: 'SA',
      nameEn: 'Saudi Arabia',
      nameAr: 'المملكة العربية السعودية',
    ),
    CountryOption(code: 'QA', nameEn: 'Qatar', nameAr: 'قطر'),
    CountryOption(code: 'KW', nameEn: 'Kuwait', nameAr: 'الكويت'),
    CountryOption(code: 'BH', nameEn: 'Bahrain', nameAr: 'البحرين'),
    CountryOption(code: 'OM', nameEn: 'Oman', nameAr: 'عُمان'),
    CountryOption(code: 'TN', nameEn: 'Tunisia', nameAr: 'تونس'),
    CountryOption(code: 'EG', nameEn: 'Egypt', nameAr: 'مصر'),
    CountryOption(code: 'DZ', nameEn: 'Algeria', nameAr: 'الجزائر'),
    CountryOption(code: 'MA', nameEn: 'Morocco', nameAr: 'المغرب'),
    CountryOption(code: 'JO', nameEn: 'Jordan', nameAr: 'الأردن'),
    CountryOption(code: 'LB', nameEn: 'Lebanon', nameAr: 'لبنان'),
    CountryOption(code: 'GB', nameEn: 'United Kingdom', nameAr: 'المملكة المتحدة'),
    CountryOption(code: 'CA', nameEn: 'Canada', nameAr: 'كندا'),
    CountryOption(code: 'DE', nameEn: 'Germany', nameAr: 'ألمانيا'),
    CountryOption(code: 'FR', nameEn: 'France', nameAr: 'فرنسا'),
  ];

  static const List<LocalizedKeyOption> industries = [
    LocalizedKeyOption(
      id: 'technology',
      nameEn: 'Technology & Software',
      nameAr: 'التكنولوجيا والبرمجيات',
    ),
    LocalizedKeyOption(
      id: 'ecommerce',
      nameEn: 'E-commerce & Retail',
      nameAr: 'التجارة الإلكترونية والتجزئة',
    ),
    LocalizedKeyOption(
      id: 'services',
      nameEn: 'Professional Services & Consulting',
      nameAr: 'الخدمات المهنية والاستشارات',
    ),
    LocalizedKeyOption(
      id: 'finance',
      nameEn: 'Financial Services & Fintech',
      nameAr: 'الخدمات المالية والتقنية المالية',
    ),
    LocalizedKeyOption(
      id: 'healthcare',
      nameEn: 'Healthcare & Life Sciences',
      nameAr: 'الرعاية الصحية وعلوم الحياة',
    ),
    LocalizedKeyOption(
      id: 'realestate',
      nameEn: 'Real Estate & Construction',
      nameAr: 'العقارات والإنشاءات',
    ),
    LocalizedKeyOption(
      id: 'media',
      nameEn: 'Media & Entertainment',
      nameAr: 'الإعلام والترفيه',
    ),
    LocalizedKeyOption(
      id: 'food',
      nameEn: 'Food & Beverage',
      nameAr: 'الأغذية والمشروبات',
    ),
    LocalizedKeyOption(
      id: 'manufacturing',
      nameEn: 'Manufacturing & Logistics',
      nameAr: 'التصنيع والخدمات اللوجستية',
    ),
    LocalizedKeyOption(
      id: 'education',
      nameEn: 'Education & Non-profit',
      nameAr: 'التعليم والمنظمات غير الربحية',
    ),
    LocalizedKeyOption(id: 'other', nameEn: 'Other', nameAr: 'أخرى'),
  ];

  static const List<LocalizedKeyOption> businessTypes = [
    LocalizedKeyOption(
      id: 'sole_proprietorship',
      nameEn: 'Sole Proprietorship',
      nameAr: 'ملكية فردية',
    ),
    LocalizedKeyOption(
      id: 'llc',
      nameEn: 'Limited Liability Company (LLC)',
      nameAr: 'شركة ذات مسؤولية محدودة',
    ),
    LocalizedKeyOption(
      id: 'corporation',
      nameEn: 'Corporation',
      nameAr: 'شركة مساهمة',
    ),
    LocalizedKeyOption(
      id: 'partnership',
      nameEn: 'Partnership',
      nameAr: 'شراكة',
    ),
    LocalizedKeyOption(
      id: 'freelancer',
      nameEn: 'Freelancer / Individual',
      nameAr: 'مستقل / فرد',
    ),
    LocalizedKeyOption(
      id: 'non_profit',
      nameEn: 'Non-Profit',
      nameAr: 'منظمة غير ربحية',
    ),
  ];

  static const List<CurrencyOption> currencies = [
    CurrencyOption(code: 'USD', symbol: r'$', nameEn: 'US Dollar', nameAr: 'دولار أمريكي'),
    CurrencyOption(code: 'EUR', symbol: '€', nameEn: 'Euro', nameAr: 'يورو'),
    CurrencyOption(code: 'AED', symbol: 'AED', nameEn: 'UAE Dirham', nameAr: 'درهم إماراتي'),
    CurrencyOption(code: 'SAR', symbol: 'SAR', nameEn: 'Saudi Riyal', nameAr: 'ريال سعودي'),
    CurrencyOption(code: 'QAR', symbol: 'QAR', nameEn: 'Qatari Riyal', nameAr: 'ريال قطري'),
    CurrencyOption(code: 'KWD', symbol: 'KWD', nameEn: 'Kuwaiti Dinar', nameAr: 'دينار كويتي'),
    CurrencyOption(code: 'BHD', symbol: 'BHD', nameEn: 'Bahraini Dinar', nameAr: 'دينار بحريني'),
    CurrencyOption(code: 'OMR', symbol: 'OMR', nameEn: 'Omani Rial', nameAr: 'ريال عماني'),
    CurrencyOption(code: 'TND', symbol: 'DT', nameEn: 'Tunisian Dinar', nameAr: 'دينار تونسي'),
    CurrencyOption(code: 'EGP', symbol: 'EGP', nameEn: 'Egyptian Pound', nameAr: 'جنيه مصري'),
    CurrencyOption(code: 'DZD', symbol: 'DZD', nameEn: 'Algerian Dinar', nameAr: 'دينار جزائري'),
    CurrencyOption(code: 'MAD', symbol: 'MAD', nameEn: 'Moroccan Dirham', nameAr: 'درهم مغربي'),
    CurrencyOption(code: 'GBP', symbol: '£', nameEn: 'British Pound', nameAr: 'جنيه إسترليني'),
    CurrencyOption(code: 'CAD', symbol: r'CA$', nameEn: 'Canadian Dollar', nameAr: 'دولار كندي'),
    CurrencyOption(code: 'AUD', symbol: r'A$', nameEn: 'Australian Dollar', nameAr: 'دولار أسترالي'),
    CurrencyOption(code: 'CHF', symbol: 'CHF', nameEn: 'Swiss Franc', nameAr: 'فرنك سويسري'),
    CurrencyOption(code: 'JPY', symbol: '¥', nameEn: 'Japanese Yen', nameAr: 'ين ياباني'),
    CurrencyOption(code: 'TRY', symbol: '₺', nameEn: 'Turkish Lira', nameAr: 'ليرة تركية'),
  ];

  static const List<CurrencyOption> switcherCurrencies = [
    CurrencyOption(code: 'USD', symbol: r'$', nameEn: 'US Dollar', nameAr: 'دولار أمريكي'),
    CurrencyOption(code: 'EUR', symbol: '€', nameEn: 'Euro', nameAr: 'يورو'),
    CurrencyOption(code: 'AED', symbol: 'AED', nameEn: 'UAE Dirham', nameAr: 'درهم إماراتي'),
    CurrencyOption(code: 'SAR', symbol: 'SAR', nameEn: 'Saudi Riyal', nameAr: 'ريال سعودي'),
    CurrencyOption(code: 'QAR', symbol: 'QAR', nameEn: 'Qatari Riyal', nameAr: 'ريال قطري'),
    CurrencyOption(code: 'GBP', symbol: '£', nameEn: 'British Pound', nameAr: 'جنيه إسترليني'),
    CurrencyOption(code: 'TND', symbol: 'DT', nameEn: 'Tunisian Dinar', nameAr: 'دينار تونسي'),
  ];

  static const List<LocalizedKeyOption> timezones = [
    LocalizedKeyOption(
      id: 'Asia/Dubai',
      nameEn: 'Asia/Dubai (GMT+4 - UAE Time)',
      nameAr: 'آسيا/دبي (GMT+4 - توقيت الإمارات)',
    ),
    LocalizedKeyOption(
      id: 'Asia/Riyadh',
      nameEn: 'Asia/Riyadh (GMT+3 - Saudi Time)',
      nameAr: 'آسيا/الرياض (GMT+3 - توقيت السعودية)',
    ),
    LocalizedKeyOption(
      id: 'Asia/Qatar',
      nameEn: 'Asia/Qatar (GMT+3 - Qatar Time)',
      nameAr: 'آسيا/قطر (GMT+3 - توقيت قطر)',
    ),
    LocalizedKeyOption(
      id: 'Africa/Tunis',
      nameEn: 'Africa/Tunis (GMT+1 - Tunisia Time)',
      nameAr: 'إفريقيا/تونس (GMT+1 - توقيت تونس)',
    ),
    LocalizedKeyOption(
      id: 'Africa/Cairo',
      nameEn: 'Africa/Cairo (GMT+3 - Cairo Time)',
      nameAr: 'إفريقيا/القاهرة (GMT+3 - توقيت القاهرة)',
    ),
    LocalizedKeyOption(
      id: 'Africa/Algiers',
      nameEn: 'Africa/Algiers (GMT+1 - Algiers Time)',
      nameAr: 'إفريقيا/الجزائر (GMT+1 - توقيت الجزائر)',
    ),
    LocalizedKeyOption(
      id: 'UTC',
      nameEn: 'UTC (Universal Time Coordinated)',
      nameAr: 'التوقيت العالمي المنسق (UTC)',
    ),
    LocalizedKeyOption(
      id: 'Europe/London',
      nameEn: 'Europe/London (GMT / BST)',
      nameAr: 'أوروبا/لندن (GMT / BST)',
    ),
    LocalizedKeyOption(
      id: 'Europe/Paris',
      nameEn: 'Europe/Paris (GMT+1 - CET)',
      nameAr: 'أوروبا/باريس (GMT+1 - توقيت وسط أوروبا)',
    ),
    LocalizedKeyOption(
      id: 'America/New_York',
      nameEn: 'America/New_York (EST / EDT)',
      nameAr: 'أمريكا/نيويورك (EST / EDT)',
    ),
    LocalizedKeyOption(
      id: 'America/Los_Angeles',
      nameEn: 'America/Los_Angeles (PST / PDT)',
      nameAr: 'أمريكا/لوس أنجلوس (PST / PDT)',
    ),
    LocalizedKeyOption(
      id: 'Asia/Tokyo',
      nameEn: 'Asia/Tokyo (JST)',
      nameAr: 'آسيا/طوكيو (JST)',
    ),
    LocalizedKeyOption(
      id: 'Australia/Sydney',
      nameEn: 'Australia/Sydney (AEST)',
      nameAr: 'أستراليا/سيدني (AEST)',
    ),
  ];

  static const List<LocalizedKeyOption> months = [
    LocalizedKeyOption(id: '1', nameEn: 'January', nameAr: 'يناير'),
    LocalizedKeyOption(id: '2', nameEn: 'February', nameAr: 'فبراير'),
    LocalizedKeyOption(id: '3', nameEn: 'March', nameAr: 'مارس'),
    LocalizedKeyOption(id: '4', nameEn: 'April', nameAr: 'أبريل'),
    LocalizedKeyOption(id: '5', nameEn: 'May', nameAr: 'مايو'),
    LocalizedKeyOption(id: '6', nameEn: 'June', nameAr: 'يونيو'),
    LocalizedKeyOption(id: '7', nameEn: 'July', nameAr: 'يوليو'),
    LocalizedKeyOption(id: '8', nameEn: 'August', nameAr: 'أغسطس'),
    LocalizedKeyOption(id: '9', nameEn: 'September', nameAr: 'سبتمبر'),
    LocalizedKeyOption(id: '10', nameEn: 'October', nameAr: 'أكتوبر'),
    LocalizedKeyOption(id: '11', nameEn: 'November', nameAr: 'نوفمبر'),
    LocalizedKeyOption(id: '12', nameEn: 'December', nameAr: 'ديسمبر'),
  ];

  static String localizedCountry(String value, String locale) {
    final trimmed = value.trim();
    for (final item in countries) {
      if (item.code.toUpperCase() == trimmed.toUpperCase() ||
          item.nameEn.toLowerCase() == trimmed.toLowerCase() ||
          item.nameAr == trimmed) {
        return item.label(locale);
      }
    }
    return trimmed;
  }

  static String localizedMonth(int month, String locale) {
    if (month < 1 || month > 12) return '';
    return months[month - 1].label(locale);
  }
}
