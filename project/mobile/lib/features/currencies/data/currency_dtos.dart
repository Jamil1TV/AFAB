import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

enum CurrencyRegion { all, major, mena, asia }

@immutable
class CurrencyCatalogEntry {
  const CurrencyCatalogEntry({
    required this.code,
    required this.symbol,
    required this.name,
    required this.region,
  });

  final String code;
  final String symbol;
  final String name;
  final CurrencyRegion region;
}

abstract final class CurrencyCatalog {
  /// Full 16-currency coverage across Converter, Risk Simulator, and Directory.
  static const List<CurrencyCatalogEntry> core16 = [
    CurrencyCatalogEntry(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      region: CurrencyRegion.major,
    ),
    CurrencyCatalogEntry(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      region: CurrencyRegion.major,
    ),
    CurrencyCatalogEntry(
      code: 'TND',
      symbol: 'DT',
      name: 'Tunisian Dinar',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'QAR',
      symbol: 'QR',
      name: 'Qatari Riyal',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      region: CurrencyRegion.major,
    ),
    CurrencyCatalogEntry(
      code: 'AED',
      symbol: 'DH',
      name: 'UAE Dirham',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'SAR',
      symbol: 'SR',
      name: 'Saudi Riyal',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'CAD',
      symbol: 'C\$',
      name: 'Canadian Dollar',
      region: CurrencyRegion.major,
    ),
    CurrencyCatalogEntry(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      region: CurrencyRegion.asia,
    ),
    CurrencyCatalogEntry(
      code: 'CHF',
      symbol: 'CHF',
      name: 'Swiss Franc',
      region: CurrencyRegion.major,
    ),
    CurrencyCatalogEntry(
      code: 'KWD',
      symbol: 'KD',
      name: 'Kuwaiti Dinar',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'MAD',
      symbol: 'MAD',
      name: 'Moroccan Dirham',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'TRY',
      symbol: '₺',
      name: 'Turkish Lira',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'EGP',
      symbol: 'E£',
      name: 'Egyptian Pound',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'AUD',
      symbol: 'A\$',
      name: 'Australian Dollar',
      region: CurrencyRegion.asia,
    ),
    CurrencyCatalogEntry(
      code: 'CNY',
      symbol: '¥',
      name: 'Chinese Yuan',
      region: CurrencyRegion.asia,
    ),
  ];

  /// Extended targets for business currency migration (`INT-02`).
  static const List<CurrencyCatalogEntry> migrationTargets = [
    ...core16,
    CurrencyCatalogEntry(
      code: 'BHD',
      symbol: 'BD',
      name: 'Bahraini Dinar',
      region: CurrencyRegion.mena,
    ),
    CurrencyCatalogEntry(
      code: 'OMR',
      symbol: 'OR',
      name: 'Omani Rial',
      region: CurrencyRegion.mena,
    ),
  ];

  static CurrencyCatalogEntry? findByCode(String code) {
    final upper = code.toUpperCase();
    for (final entry in migrationTargets) {
      if (entry.code == upper) return entry;
    }
    return null;
  }

  static CurrencyRegion regionOf(String code) =>
      findByCode(code)?.region ?? CurrencyRegion.major;
}

@immutable
class CurrencyPairDto {
  const CurrencyPairDto({
    required this.symbol,
    required this.base,
    required this.target,
    required this.rate,
    required this.change24h,
    required this.high24h,
    required this.low24h,
    this.sparkline = const [],
  });

  final String symbol;
  final String base;
  final String target;
  final Decimal rate;
  final double change24h;
  final Decimal high24h;
  final Decimal low24h;
  final List<double> sparkline;

  bool matchesRegion(CurrencyRegion region) {
    if (region == CurrencyRegion.all) return true;
    return CurrencyCatalog.regionOf(target) == region;
  }

  factory CurrencyPairDto.fromJson(Map<String, dynamic> json) {
    final rawSpark = json['sparkline'] as List<dynamic>? ?? const [];
    return CurrencyPairDto(
      symbol: (json['symbol'] ?? '').toString(),
      base: (json['base'] ?? 'USD').toString().toUpperCase(),
      target: (json['target'] ?? 'EUR').toString().toUpperCase(),
      rate: MoneyFormatter.parseDecimal(json['rate']),
      change24h: (json['change24h'] as num?)?.toDouble() ?? 0.0,
      high24h: MoneyFormatter.parseDecimal(json['high24h']),
      low24h: MoneyFormatter.parseDecimal(json['low24h']),
      sparkline: rawSpark
          .whereType<num>()
          .map((e) => e.toDouble())
          .toList(),
    );
  }
}

@immutable
class HistoricalRatePointDto {
  const HistoricalRatePointDto({
    required this.date,
    required this.rate,
  });

  final String date;
  final double rate;

  factory HistoricalRatePointDto.fromJson(Map<String, dynamic> json) {
    return HistoricalRatePointDto(
      date: (json['date'] ?? '').toString(),
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class CurrencyConversionResultDto {
  const CurrencyConversionResultDto({
    required this.from,
    required this.to,
    required this.amount,
    required this.exchangeRate,
    required this.convertedAmount,
  });

  final String from;
  final String to;
  final Decimal amount;
  final Decimal exchangeRate;
  final Decimal convertedAmount;

  factory CurrencyConversionResultDto.fromJson(Map<String, dynamic> json) {
    return CurrencyConversionResultDto(
      from: (json['from'] ?? 'USD').toString().toUpperCase(),
      to: (json['to'] ?? 'EUR').toString().toUpperCase(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      exchangeRate: MoneyFormatter.parseDecimal(json['exchangeRate']),
      convertedAmount: MoneyFormatter.parseDecimal(json['convertedAmount']),
    );
  }
}

@immutable
class CurrencyChangePreviewDto {
  const CurrencyChangePreviewDto({
    required this.oldCurrency,
    required this.newCurrency,
    required this.exchangeRate,
    required this.transactionsCount,
    required this.currentNetBalance,
    required this.projectedNetBalance,
  });

  final String oldCurrency;
  final String newCurrency;
  final Decimal exchangeRate;
  final int transactionsCount;
  final Decimal currentNetBalance;
  final Decimal projectedNetBalance;

  factory CurrencyChangePreviewDto.fromJson(Map<String, dynamic> json) {
    return CurrencyChangePreviewDto(
      oldCurrency: (json['oldCurrency'] ?? 'USD').toString().toUpperCase(),
      newCurrency: (json['newCurrency'] ?? 'EUR').toString().toUpperCase(),
      exchangeRate: MoneyFormatter.parseDecimal(json['exchangeRate']),
      transactionsCount: (json['transactionsCount'] as num?)?.toInt() ?? 0,
      currentNetBalance: MoneyFormatter.parseDecimal(json['currentNetBalance']),
      projectedNetBalance: MoneyFormatter.parseDecimal(
        json['projectedNetBalance'],
      ),
    );
  }
}

@immutable
class CurrencyChangeResultDto {
  const CurrencyChangeResultDto({
    required this.oldCurrency,
    required this.newCurrency,
    required this.exchangeRate,
    required this.convertedTransactionsCount,
    required this.preservedHistoricalTransactionsCount,
    required this.success,
    required this.message,
  });

  final String oldCurrency;
  final String newCurrency;
  final Decimal exchangeRate;
  final int convertedTransactionsCount;
  final int preservedHistoricalTransactionsCount;
  final bool success;
  final String message;

  factory CurrencyChangeResultDto.fromJson(Map<String, dynamic> json) {
    return CurrencyChangeResultDto(
      oldCurrency: (json['oldCurrency'] ?? 'USD').toString().toUpperCase(),
      newCurrency: (json['newCurrency'] ?? 'EUR').toString().toUpperCase(),
      exchangeRate: MoneyFormatter.parseDecimal(json['exchangeRate']),
      convertedTransactionsCount:
          (json['convertedTransactionsCount'] as num?)?.toInt() ?? 0,
      preservedHistoricalTransactionsCount:
          (json['preservedHistoricalTransactionsCount'] as num?)?.toInt() ?? 0,
      success: json['success'] as bool? ?? false,
      message: (json['message'] ?? '').toString(),
    );
  }
}

@immutable
class FxRateAlert {
  const FxRateAlert({
    required this.id,
    required this.pair,
    required this.base,
    required this.target,
    required this.condition,
    required this.targetRate,
    this.active = true,
    required this.createdAt,
  });

  final String id;
  final String pair;
  final String base;
  final String target;
  final String condition; // 'above' | 'below'
  final Decimal targetRate;
  final bool active;
  final String createdAt;

  bool isTriggered(Decimal? currentRate) {
    if (!active || currentRate == null) return false;
    return condition == 'above'
        ? currentRate >= targetRate
        : currentRate <= targetRate;
  }

  FxRateAlert copyWith({bool? active}) {
    return FxRateAlert(
      id: id,
      pair: pair,
      base: base,
      target: target,
      condition: condition,
      targetRate: targetRate,
      active: active ?? this.active,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pair': pair,
        'base': base,
        'target': target,
        'condition': condition,
        'targetRate': targetRate.toString(),
        'active': active,
        'createdAt': createdAt,
      };

  factory FxRateAlert.fromJson(Map<String, dynamic> json) {
    return FxRateAlert(
      id: (json['id'] ?? '').toString(),
      pair: (json['pair'] ?? '').toString(),
      base: (json['base'] ?? 'USD').toString().toUpperCase(),
      target: (json['target'] ?? 'EUR').toString().toUpperCase(),
      condition: (json['condition'] ?? 'above').toString(),
      targetRate: MoneyFormatter.parseDecimal(json['targetRate']),
      active: json['active'] as bool? ?? true,
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

@immutable
class FxRiskScenario {
  const FxRiskScenario({
    required this.shiftPct,
    required this.effectiveRate,
    required this.projectedValue,
    required this.deltaValue,
  });

  final double shiftPct;
  final Decimal effectiveRate;
  final Decimal projectedValue;
  final Decimal deltaValue;
}

abstract final class FxRiskCalculator {
  static const List<double> defaultShiftsPct = [3.0, 1.5, 0.0, -1.5, -3.0];

  static List<FxRiskScenario> calculate({
    required Decimal foreignAmount,
    required Decimal spotRate,
    required int paymentTermsDays,
  }) {
    final spotValue = (foreignAmount * spotRate).round(scale: 4);
    final termScale = paymentTermsDays >= 90
        ? 1.5
        : (paymentTermsDays >= 60 ? 1.25 : (paymentTermsDays <= 15 ? 0.7 : 1.0));

    return [
      for (final baseShift in defaultShiftsPct)
        _buildScenario(
          shiftPct: baseShift == 0.0
              ? 0.0
              : double.parse((baseShift * termScale).toStringAsFixed(2)),
          foreignAmount: foreignAmount,
          spotRate: spotRate,
          spotValue: spotValue,
        ),
    ];
  }

  static FxRiskScenario _buildScenario({
    required double shiftPct,
    required Decimal foreignAmount,
    required Decimal spotRate,
    required Decimal spotValue,
  }) {
    final multiplier = Decimal.parse((1.0 + shiftPct / 100.0).toStringAsFixed(6));
    final effRate = (spotRate * multiplier).round(scale: 6);
    final projected = (foreignAmount * effRate).round(scale: 4);
    final delta = (projected - spotValue).round(scale: 4);
    return FxRiskScenario(
      shiftPct: shiftPct,
      effectiveRate: effRate,
      projectedValue: projected,
      deltaValue: delta,
    );
  }
}
