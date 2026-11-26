/// ISO-4217 minor-unit fractions and canonical currency display prefixes.
abstract final class CurrencyMinorUnits {
  static const Map<String, int> _fractions = {
    'TND': 3,
    'KWD': 3,
    'BHD': 3,
    'OMR': 3,
    'JOD': 3,
    'LYD': 3,
    'IQD': 3,
    'JPY': 0,
    'KRW': 0,
  };

  static const Map<String, String> _symbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': r'CA$',
    'AUD': r'A$',
    'TRY': '₺',
    'QAR': 'QAR ',
    'AED': 'AED ',
    'SAR': 'SAR ',
    'TND': 'DT ',
    'MAD': 'MAD ',
    'KWD': 'KWD ',
    'BHD': 'BHD ',
    'OMR': 'OMR ',
    'EGP': 'EGP ',
    'CHF': 'CHF ',
    'DZD': 'DZD ',
  };

  static int decimalsFor(String? currencyCode) {
    final code = (currencyCode ?? 'USD').trim().toUpperCase();
    return _fractions[code] ?? 2;
  }

  static String prefixFor(String? currencyCode) {
    final code = (currencyCode ?? 'USD').trim().toUpperCase();
    return _symbols[code] ?? '$code ';
  }
}
