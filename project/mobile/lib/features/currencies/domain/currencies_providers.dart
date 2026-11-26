import 'dart:convert';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/currencies/data/currencies_repository.dart';
import 'package:afab_mobile/features/currencies/data/currency_dtos.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Holds the "View:" base currency independently of dashboard reloads so user
/// selection NEVER snaps back to business base currency (fixing Web bug).
class ViewBaseCurrencyNotifier extends Notifier<String> {
  String? _userSelectedCode;
  String? _userSelectedBizId;

  @override
  String build() {
    ref.watch(activeBusinessIdProvider);
    final biz = ref.watch(activeBusinessProvider);
    if (_userSelectedCode != null && _userSelectedBizId == biz?.id) {
      return _userSelectedCode!;
    }
    if (biz == null) {
      return _userSelectedCode ?? 'USD';
    }
    return biz.currency.toUpperCase();
  }

  void setBase(String code) {
    final upper = code.toUpperCase().trim();
    if (upper.isNotEmpty) {
      _userSelectedBizId = ref.read(activeBusinessProvider)?.id;
      _userSelectedCode = upper;
      state = upper;
    }
  }
}

final viewBaseCurrencyProvider =
    NotifierProvider<ViewBaseCurrencyNotifier, String>(
  ViewBaseCurrencyNotifier.new,
);

final marketRatesProvider = FutureProvider<List<CurrencyPairDto>>((ref) async {
  final base = ref.watch(viewBaseCurrencyProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .read(currenciesRepositoryProvider)
      .getMarketRates(base: base, cancelToken: cancelToken);
});

class SelectedPairNotifier extends Notifier<CurrencyPairDto?> {
  @override
  CurrencyPairDto? build() {
    final rates = ref.watch(marketRatesProvider).value;
    if (rates == null || rates.isEmpty) return null;
    return rates.first;
  }

  void select(CurrencyPairDto pair) => state = pair;
}

final selectedPairProvider =
    NotifierProvider<SelectedPairNotifier, CurrencyPairDto?>(
  SelectedPairNotifier.new,
);

@immutable
class HistoryQueryKey {
  const HistoryQueryKey({
    required this.from,
    required this.to,
    required this.timeframe,
  });

  final String from;
  final String to;
  final String timeframe;

  @override
  bool operator ==(Object other) =>
      other is HistoryQueryKey &&
      other.from == from &&
      other.to == to &&
      other.timeframe == timeframe;

  @override
  int get hashCode => Object.hash(from, to, timeframe);
}

final historicalRatesProvider = FutureProvider.autoDispose
    .family<List<HistoricalRatePointDto>, HistoryQueryKey>((ref, key) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref.read(currenciesRepositoryProvider).getHistoricalRates(
        from: key.from,
        to: key.to,
        timeframe: key.timeframe,
        cancelToken: cancelToken,
      );
});

/// Resolves spot rates for ALL 16 core currencies relative to `viewBaseCurrency`,
/// fetching missing non-popular currencies (`MAD`, `TRY`, `EGP`, `AUD`, `CNY`)
/// via `GET /currencies/convert` instead of hardcoded constants.
final directoryRatesMapProvider =
    FutureProvider<Map<String, Decimal>>((ref) async {
  final base = ref.watch(viewBaseCurrencyProvider);
  final marketPairs = await ref.watch(marketRatesProvider.future);
  final map = <String, Decimal>{base: Decimal.one};
  for (final p in marketPairs) {
    map[p.target] = p.rate;
  }

  final repo = ref.read(currenciesRepositoryProvider);
  final missing = CurrencyCatalog.core16
      .map((c) => c.code)
      .where((code) => !map.containsKey(code))
      .toList();

  if (missing.isNotEmpty) {
    await Future.wait(
      missing.map((target) async {
        try {
          final res = await repo.convert(
            from: base,
            to: target,
            amount: Decimal.one,
          );
          if (res.exchangeRate > Decimal.zero) {
            map[target] = res.exchangeRate;
          }
        } catch (_) {
          // Skip unavailable pair rather than fabricating hardcoded rates.
        }
      }),
    );
  }
  return map;
});

@immutable
class PortfolioFxSnapshot {
  const PortfolioFxSnapshot({
    required this.businessName,
    required this.baseCurrency,
    required this.netBalance,
    this.isReadOnlyBlocked = false,
  });

  final String businessName;
  final String baseCurrency;
  final Decimal netBalance;
  final bool isReadOnlyBlocked;
}

final currenciesPortfolioProvider =
    FutureProvider<PortfolioFxSnapshot>((ref) async {
  final biz = ref.watch(activeBusinessProvider);
  final fallbackCurr = (biz?.currency ?? 'USD').toUpperCase();
  final fallbackName = biz?.name ?? 'AFAB';
  if (biz?.isReadOnly == true) {
    return PortfolioFxSnapshot(
      businessName: fallbackName,
      baseCurrency: fallbackCurr,
      netBalance: Decimal.zero,
      isReadOnlyBlocked: true,
    );
  }
  try {
    final summary = await ref
        .read(dashboardRepositoryProvider)
        .getSummary(DashboardPeriod.month);
    return PortfolioFxSnapshot(
      businessName:
          summary.businessName.isNotEmpty ? summary.businessName : fallbackName,
      baseCurrency:
          summary.currency.isNotEmpty ? summary.currency : fallbackCurr,
      netBalance: summary.profit.rawValue,
    );
  } on BusinessReadOnlyFailure {
    return PortfolioFxSnapshot(
      businessName: fallbackName,
      baseCurrency: fallbackCurr,
      netBalance: Decimal.zero,
      isReadOnlyBlocked: true,
    );
  } on ForbiddenFailure {
    return PortfolioFxSnapshot(
      businessName: fallbackName,
      baseCurrency: fallbackCurr,
      netBalance: Decimal.zero,
      isReadOnlyBlocked: true,
    );
  }
});

const String _alertsStorageKey = 'afab_fx_rate_alerts';

class LocalFxAlertsNotifier extends AsyncNotifier<List<FxRateAlert>> {
  @override
  Future<List<FxRateAlert>> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_alertsStorageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => FxRateAlert.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<FxRateAlert> list) async {
    state = AsyncValue.data(list);
    await ref.read(sharedPreferencesProvider).setString(
          _alertsStorageKey,
          jsonEncode(list.map((e) => e.toJson()).toList()),
        );
  }

  Future<void> addAlert({
    required String base,
    required String target,
    required String condition,
    required Decimal targetRate,
  }) async {
    final current = state.value ?? const [];
    final alert = FxRateAlert(
      id: const Uuid().v4(),
      pair: '${base.toUpperCase()}/${target.toUpperCase()}',
      base: base.toUpperCase(),
      target: target.toUpperCase(),
      condition: condition,
      targetRate: targetRate,
      active: true,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    await _persist([alert, ...current]);
  }

  Future<void> toggleAlert(String id) async {
    final current = state.value ?? const [];
    await _persist([
      for (final a in current)
        if (a.id == id) a.copyWith(active: !a.active) else a,
    ]);
  }

  Future<void> deleteAlert(String id) async {
    final current = state.value ?? const [];
    await _persist(current.where((a) => a.id != id).toList());
  }
}

final localFxAlertsProvider =
    AsyncNotifierProvider<LocalFxAlertsNotifier, List<FxRateAlert>>(
  LocalFxAlertsNotifier.new,
);
