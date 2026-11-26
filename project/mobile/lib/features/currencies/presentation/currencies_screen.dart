import 'dart:async';
import 'dart:math' as math;

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/currency_minor_units.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/currencies/data/currencies_repository.dart';
import 'package:afab_mobile/features/currencies/data/currency_dtos.dart';
import 'package:afab_mobile/features/currencies/domain/currencies_providers.dart';
import 'package:afab_mobile/features/currencies/presentation/widgets/currency_migration_sheet.dart';
import 'package:afab_mobile/features/currencies/presentation/widgets/simulated_tick_panel.dart';
import 'package:afab_mobile/features/invoices/domain/invoice_calculator.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/analytics_charts.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum CurrenciesTab { markets, simulatedTick, risk, alerts, directory }

/// Screen `INT-01`: Currencies & FX Markets, Two-Way Converter, Portfolio Impact,
/// Risk Simulator, Device-Local Alerts, and 16-Currency Rate Directory.
class CurrenciesScreen extends ConsumerStatefulWidget {
  const CurrenciesScreen({super.key, this.initialTab});

  final CurrenciesTab? initialTab;

  @override
  ConsumerState<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends ConsumerState<CurrenciesScreen> {
  late CurrenciesTab _tab;
  CurrencyRegion _region = CurrencyRegion.all;
  bool _chartSimulatedMode = false; // Default to historical trajectory
  String _timeframe = '1M';
  bool _showMa5 = false;
  bool _barStyle = false;

  // Converter state
  String _fromCurr = 'EUR';
  String _toCurr = 'USD';
  final _sendCtrl = TextEditingController(text: '1000');
  final _receiveCtrl = TextEditingController(text: '');
  Decimal _convRate = Decimal.one;
  int _swapTurns = 0;
  Timer? _convDebounce;
  CancelToken? _convCancel;

  // Risk simulator state
  final _riskAmountCtrl = TextEditingController(text: '10000');
  String _riskForeignCurrency = 'EUR';
  int _riskTermsDays = 30;

  // Local alerts form state
  bool _showNewAlertForm = false;
  String _alertPairTarget = 'EUR';
  String _alertCondition = 'above';
  final _alertRateCtrl = TextEditingController();
  String? _alertRateError;

  // Directory search state
  final _dirSearchCtrl = TextEditingController();

  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab ?? CurrenciesTab.markets;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final base = ref.read(viewBaseCurrencyProvider);
      setState(() {
        _fromCurr = base;
        _toCurr = base == 'USD' ? 'EUR' : 'USD';
        _riskForeignCurrency = base == 'USD' ? 'EUR' : 'USD';
        _alertPairTarget = base == 'USD' ? 'EUR' : 'USD';
      });
      _syncConverter(fromSend: true);
    });
  }

  @override
  void dispose() {
    _convDebounce?.cancel();
    _convCancel?.cancel();
    _sendCtrl.dispose();
    _receiveCtrl.dispose();
    _riskAmountCtrl.dispose();
    _alertRateCtrl.dispose();
    _dirSearchCtrl.dispose();
    super.dispose();
  }

  void _syncConverter({required bool fromSend}) {
    _convDebounce?.cancel();
    final rawText = fromSend ? _sendCtrl.text : _receiveCtrl.text;
    final parsed = InvoiceCalculator.parseNormalized(rawText);
    if (parsed == null || parsed <= Decimal.zero) {
      if (fromSend) {
        _receiveCtrl.text = '0';
      } else {
        _sendCtrl.text = '0';
      }
      return;
    }

    // Immediate optimistic local calculation while debouncing API call
    if (_fromCurr == _toCurr) {
      _convRate = Decimal.one;
      final formatted = parsed.toStringAsFixed(
        CurrencyMinorUnits.decimalsFor(fromSend ? _toCurr : _fromCurr),
      );
      if (fromSend) {
        _receiveCtrl.text = formatted;
      } else {
        _sendCtrl.text = formatted;
      }
      setState(() {});
      return;
    }

    if (_convRate > Decimal.zero) {
      if (fromSend) {
        final dec = CurrencyMinorUnits.decimalsFor(_toCurr);
        _receiveCtrl.text = (parsed * _convRate).round(scale: dec).toStringAsFixed(dec);
      } else {
        final dec = CurrencyMinorUnits.decimalsFor(_fromCurr);
        final inv = (parsed / _convRate).toDecimal(scaleOnInfinitePrecision: dec + 4);
        _sendCtrl.text = inv.round(scale: dec).toStringAsFixed(dec);
      }
    }

    _convDebounce = Timer(const Duration(milliseconds: 250), () async {
      _convCancel?.cancel();
      final token = CancelToken();
      _convCancel = token;
      try {
        final res = await ref.read(currenciesRepositoryProvider).convert(
              from: fromSend ? _fromCurr : _toCurr,
              to: fromSend ? _toCurr : _fromCurr,
              amount: parsed,
              cancelToken: token,
            );
        if (!mounted) return;
        setState(() {
          _convRate = fromSend
              ? res.exchangeRate
              : (res.exchangeRate > Decimal.zero
                  ? (Decimal.one / res.exchangeRate)
                      .toDecimal(scaleOnInfinitePrecision: 6)
                  : Decimal.one);
          final targetCurr = fromSend ? _toCurr : _fromCurr;
          final dec = CurrencyMinorUnits.decimalsFor(targetCurr);
          final formatted = res.convertedAmount.round(scale: dec).toStringAsFixed(dec);
          if (fromSend) {
            _receiveCtrl.text = formatted;
          } else {
            _sendCtrl.text = formatted;
          }
        });
      } catch (_) {
        // Ignore cancelled or transient errors cleanly.
      }
    });
  }

  void _swapConverter() {
    setState(() {
      final tmpCurr = _fromCurr;
      _fromCurr = _toCurr;
      _toCurr = tmpCurr;
      final tmpText = _sendCtrl.text;
      _sendCtrl.text = _receiveCtrl.text;
      _receiveCtrl.text = tmpText;
      _swapTurns++;
    });
    _syncConverter(fromSend: true);
  }

  Future<void> _copyConverted() async {
    final text = '${_receiveCtrl.text.trim()} $_toCurr';
    await Clipboard.setData(ClipboardData(text: text));
    await HapticFeedback.lightImpact();
    if (mounted) AfabToast.showSuccess(context, context.l10n.commonCopiedToClipboard);
  }

  Future<void> _refreshAll() async {
    ref.invalidate(marketRatesProvider);
    ref.invalidate(directoryRatesMapProvider);
    ref.invalidate(currenciesPortfolioProvider);
    await ref.read(marketRatesProvider.future).catchError((_) => <CurrencyPairDto>[]);
    if (mounted) setState(() => _lastUpdated = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final businessBaseCurrency = (biz?.currency ?? 'USD').toUpperCase();
    final viewBase = ref.watch(viewBaseCurrencyProvider);

    final ratesAsync = ref.watch(marketRatesProvider);
    final selectedPair = ref.watch(selectedPairProvider);
    final portfolioAsync = ref.watch(currenciesPortfolioProvider);
    final dirRatesAsync = ref.watch(directoryRatesMapProvider);
    final alertsAsync = ref.watch(localFxAlertsProvider);

    final pairs = ratesAsync.value ?? const <CurrencyPairDto>[];
    final activePair = selectedPair ?? (pairs.isNotEmpty ? pairs.first : null);
    final filteredTicker =
        pairs.where((p) => p.matchesRegion(_region)).toList();

    final rateByPair = <String, Decimal>{
      for (final p in pairs) p.symbol: p.rate,
    };
    final alerts = alertsAsync.value ?? const <FxRateAlert>[];
    final triggeredAlerts = alerts
        .where((a) => a.isTriggered(rateByPair[a.pair]))
        .toList();

    final tabItems = [
      AfabSegmentItem(value: CurrenciesTab.markets, label: l10n.currenciesTabMarkets),
      AfabSegmentItem(
        value: CurrenciesTab.simulatedTick,
        label: l10n.currenciesTabSimulated,
      ),
      AfabSegmentItem(value: CurrenciesTab.risk, label: l10n.currenciesTabRisk),
      AfabSegmentItem(value: CurrenciesTab.alerts, label: l10n.currenciesTabAlerts),
      AfabSegmentItem(
        value: CurrenciesTab.directory,
        label: l10n.currenciesTabDirectory,
      ),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);

          return RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 24 : 16,
                16,
                isExpanded ? 24 : 16,
                40,
              ),
              children: [
                // Page Title + Ask Copilot + Refresh
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.currenciesTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.currenciesSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AfabStatusBadge(
                          label: ratesAsync.hasError
                              ? l10n.currenciesFeedUnavailable
                              : '${l10n.currenciesLiveActive} · ${DateFormat('HH:mm:ss', 'en_US').format(_lastUpdated)}',
                          variant: ratesAsync.hasError
                              ? AfabBadgeVariant.warning
                              : AfabBadgeVariant.success,
                        ),
                        IconButton(
                          tooltip: l10n.moreHubAskCopilotTooltip,
                          icon: Icon(
                            LucideIcons.sparkles,
                            color: colors.primary,
                            size: 20,
                          ),
                          onPressed: () => context.go(
                            '/copilot',
                            extra: CopilotPromptRequest(
                              prompt:
                                  'Analyze my FX exposure with business base currency $businessBaseCurrency and selected pair ${activePair?.symbol ?? '$_fromCurr/$_toCurr'}.',
                              screenContext: {
                                'page': 'currencies',
                                'tab': _tab.name,
                                'baseCurrency': businessBaseCurrency,
                                'viewBaseCurrency': viewBase,
                                if (activePair != null)
                                  'selectedPair': activePair.symbol,
                              },
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.commonReload,
                          onPressed: _refreshAll,
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // View Base Picker + Base Currency Migration Trigger
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Builder(
                      builder: (context) {
                        final safeViewBase = CurrencyCatalog.core16
                                .any((c) => c.code == viewBase)
                            ? viewBase
                            : 'USD';
                        return SizedBox(
                          width: 155,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('view_base_$safeViewBase'),
                            initialValue: safeViewBase,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.currenciesViewPrefix,
                              isDense: true,
                              prefixIcon:
                                  const Icon(LucideIcons.globe, size: 16),
                            ),
                            items: [
                              for (final c in CurrencyCatalog.core16)
                                DropdownMenuItem(
                                  value: c.code,
                                  child: Text(c.code),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(viewBaseCurrencyProvider.notifier)
                                    .setBase(v);
                                setState(() {
                                  _fromCurr = v;
                                  if (_toCurr == v) {
                                    _toCurr = v == 'USD' ? 'EUR' : 'USD';
                                  }
                                });
                                _syncConverter(fromSend: true);
                              }
                            },
                          ),
                        );
                      },
                    ),
                    AfabButton(
                      label: l10n.currenciesBasePrefix(businessBaseCurrency),
                      icon: LucideIcons.wallet,
                      variant: AfabButtonVariant.soft,
                      compact: true,
                      onPressed: (biz?.isReadOnly == true)
                          ? null
                          : () => showCurrencyMigrationSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Region Filter Chips + Ticker Strip
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in [
                      (CurrencyRegion.all, l10n.currenciesRegionAll),
                      (CurrencyRegion.major, l10n.currenciesRegionMajors),
                      (CurrencyRegion.mena, l10n.currenciesRegionMena),
                      (CurrencyRegion.asia, l10n.currenciesRegionAsia),
                    ])
                      ChoiceChip(
                        label: Text(entry.$2),
                        selected: _region == entry.$1,
                        onSelected: (_) => setState(() => _region = entry.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (filteredTicker.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredTicker.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final p = filteredTicker[i];
                        final isPos = p.change24h >= 0;
                        final selected = activePair?.symbol == p.symbol;
                        return InkWell(
                          onTap: () {
                            ref.read(selectedPairProvider.notifier).select(p);
                            setState(() {
                              _fromCurr = p.base;
                              _toCurr = p.target;
                            });
                            _syncConverter(fromSend: true);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colors.primary.withValues(alpha: 0.12)
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? colors.primary : colors.border,
                              ),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    p.symbol,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    p.rate.toDouble().toStringAsFixed(4),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${isPos ? '+' : ''}${p.change24h.toStringAsFixed(2)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: isPos
                                              ? colors.success
                                              : colors.danger,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 14),

                // 5-Tab Switcher
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: AfabSegmentedBar<CurrenciesTab>(
                    items: tabItems,
                    selectedValue: _tab,
                    onSelected: (t) => setState(() => _tab = t),
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Body
                if (_tab == CurrenciesTab.markets)
                  _buildMarketsTab(
                    context,
                    pairs: pairs,
                    activePair: activePair,
                    ratesLoading: ratesAsync.isLoading,
                    ratesError: ratesAsync.error,
                    portfolioAsync: portfolioAsync,
                    dirRates: dirRatesAsync.value ?? const {},
                    businessBaseCurrency: businessBaseCurrency,
                    isExpanded: isExpanded,
                    width: width,
                  )
                else if (_tab == CurrenciesTab.simulatedTick)
                  _buildSimulatedTab(context, pairs: pairs, activePair: activePair)
                else if (_tab == CurrenciesTab.risk)
                  _buildRiskTab(
                    context,
                    businessBaseCurrency: businessBaseCurrency,
                    dirRates: dirRatesAsync.value ?? const {},
                  )
                else if (_tab == CurrenciesTab.alerts)
                  _buildAlertsTab(
                    context,
                    pairs: pairs,
                    alerts: alerts,
                    triggeredAlerts: triggeredAlerts,
                    rateByPair: rateByPair,
                  )
                else
                  _buildDirectoryTab(
                    context,
                    viewBase: viewBase,
                    dirRates: dirRatesAsync.value ?? const {},
                    pairs: pairs,
                    isExpanded: isExpanded,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarketsTab(
    BuildContext context, {
    required List<CurrencyPairDto> pairs,
    required CurrencyPairDto? activePair,
    required bool ratesLoading,
    required Object? ratesError,
    required AsyncValue<PortfolioFxSnapshot> portfolioAsync,
    required Map<String, Decimal> dirRates,
    required String businessBaseCurrency,
    required bool isExpanded,
    required double width,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    if (ratesLoading && pairs.isEmpty) {
      return const AfabListSkeleton(count: 3);
    }
    if (ratesError != null && pairs.isEmpty) {
      return AfabErrorState(
        title: l10n.currenciesFeedUnavailable,
        message: ratesError.toString(),
        retryLabel: l10n.commonRetry,
        onRetry: _refreshAll,
      );
    }

    final featured = pairs.take(4).toList();
    final featCols = width >= 900 ? 4 : (width >= 480 ? 2 : 1);

    final chartCard = _buildChartCard(context, activePair: activePair);
    final converterCard = _buildConverterCard(
      context,
      portfolioBalance: portfolioAsync.value?.netBalance ?? Decimal.zero,
      portfolioCurrency: portfolioAsync.value?.baseCurrency ?? businessBaseCurrency,
    );

    final portfolioTargets = ['USD', 'EUR', 'TND', 'GBP', 'AED']
        .where((c) => c != businessBaseCurrency)
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (featured.isNotEmpty) ...[
          Text(
            l10n.currenciesFeaturedPairs,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          AfabKpiWrapGrid(
            columns: featCols,
            children: [
              for (final p in featured)
                _FeaturedPairCard(
                  pair: p,
                  selected: activePair?.symbol == p.symbol,
                  onTap: () {
                    ref.read(selectedPairProvider.notifier).select(p);
                    setState(() {
                      _fromCurr = p.base;
                      _toCurr = p.target;
                    });
                    _syncConverter(fromSend: true);
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        if (isExpanded)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: chartCard),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: converterCard),
            ],
          )
        else ...[
          chartCard,
          const SizedBox(height: 14),
          converterCard,
        ],
        const SizedBox(height: 14),
        AfabCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currenciesPortfolioImpactTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              portfolioAsync.when(
                loading: () => const AfabLoader(size: 36),
                error: (e, _) => Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                data: (snap) {
                  if (snap.isReadOnlyBlocked) {
                    return Text(
                      l10n.currenciesPortfolioReadOnlyHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MoneyText(
                        amount: snap.netBalance,
                        currency: snap.baseCurrency,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          for (final target in portfolioTargets)
                            if (dirRates.containsKey(target))
                              AfabInsetPanel(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      target,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: colors.textMuted),
                                    ),
                                    MoneyText(
                                      amount: snap.netBalance * dirRates[target]!,
                                      currency: target,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context, {
    required CurrencyPairDto? activePair,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final from = activePair?.base ?? _fromCurr;
    final to = activePair?.target ?? _toCurr;

    if (_chartSimulatedMode && activePair != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AfabSegmentedBar<bool>(
              items: [
                AfabSegmentItem(
                  value: false,
                  label: l10n.currenciesChartModeHistory,
                ),
                AfabSegmentItem(
                  value: true,
                  label: l10n.currenciesChartModeSimulated,
                ),
              ],
              selectedValue: _chartSimulatedMode,
              onSelected: (v) => setState(() => _chartSimulatedMode = v),
            ),
          ),
          const SizedBox(height: 8),
          SimulatedTickPanel(
            pairSymbol: activePair.symbol,
            spotRate: activePair.rate.toDouble(),
            showTradeFeed: false,
          ),
        ],
      );
    }

    final historyAsync = ref.watch(
      historicalRatesProvider(
        HistoryQueryKey(from: from, to: to, timeframe: _timeframe),
      ),
    );

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '$from/$to',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AfabStatusBadge(
                    label: l10n.currenciesSimulatedTrendCaption,
                    variant: AfabBadgeVariant.neutral,
                  ),
                ],
              ),
              AfabSegmentedBar<bool>(
                items: [
                  AfabSegmentItem(
                    value: false,
                    label: l10n.currenciesChartModeHistory,
                  ),
                  AfabSegmentItem(
                    value: true,
                    label: l10n.currenciesChartModeSimulated,
                  ),
                ],
                selectedValue: _chartSimulatedMode,
                onSelected: (v) => setState(() => _chartSimulatedMode = v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tf in const ['1W', '1M', '3M', '1Y'])
                ChoiceChip(
                  label: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(tf),
                  ),
                  selected: _timeframe == tf,
                  onSelected: (_) => setState(() => _timeframe = tf),
                ),
              FilterChip(
                label: const Text('MA-5'),
                selected: _showMa5,
                onSelected: (v) => setState(() => _showMa5 = v),
              ),
              FilterChip(
                label: Text(
                  _barStyle ? l10n.currenciesChartBar : l10n.currenciesChartLine,
                ),
                selected: _barStyle,
                onSelected: (v) => setState(() => _barStyle = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: historyAsync.when(
              loading: () => const Center(child: AfabLoader(size: 40)),
              error: (e, _) => Center(
                child: Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              data: (points) {
                if (points.isEmpty) {
                  return Center(child: Text(l10n.commonNoData));
                }
                final maxX = points.length == 1
                    ? 0.5
                    : (points.length - 1).toDouble();
                final minX = points.length == 1 ? -0.5 : 0.0;

                if (_barStyle) {
                  return Directionality(
                    textDirection: TextDirection.ltr,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: colors.border,
                            strokeWidth: 1,
                            dashArray: const [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < points.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: points[i].rate,
                                  color: colors.primary,
                                  width: math.max(3, 180 / points.length),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final maSpots = <FlSpot>[];
                if (_showMa5 && points.length >= 5) {
                  for (var i = 4; i < points.length; i++) {
                    var sum = 0.0;
                    for (var j = i - 4; j <= i; j++) {
                      sum += points[j].rate;
                    }
                    maSpots.add(FlSpot(i.toDouble(), sum / 5.0));
                  }
                }

                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: colors.border,
                          strokeWidth: 1,
                          dashArray: const [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xE60C101C),
                          getTooltipItems: (spots) => spots.map((s) {
                            final idx = s.x.round();
                            final date = (idx >= 0 && idx < points.length)
                                ? '${points[idx].date}\n'
                                : '';
                            return LineTooltipItem(
                              '$date${s.y.toStringAsFixed(4)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < points.length; i++)
                              FlSpot(i.toDouble(), points[i].rate),
                          ],
                          isCurved: points.length > 2,
                          color: colors.primary,
                          barWidth: 2.5,
                          dotData: FlDotData(show: points.length <= 2),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colors.primary.withValues(alpha: 0.14),
                          ),
                        ),
                        if (maSpots.isNotEmpty)
                          LineChartBarData(
                            spots: maSpots,
                            isCurved: true,
                            color: colors.warning,
                            barWidth: 1.8,
                            dotData: const FlDotData(show: false),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConverterCard(
    BuildContext context, {
    required Decimal portfolioBalance,
    required String portfolioCurrency,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.currenciesConverterTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _sendCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.currenciesYouSend,
                    isDense: true,
                  ),
                  onChanged: (_) => _syncConverter(fromSend: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _fromCurr,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final c in CurrencyCatalog.core16)
                      DropdownMenuItem(value: c.code, child: Text(c.code)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _fromCurr = v);
                      _syncConverter(fromSend: true);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: InkWell(
              onTap: _swapConverter,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                child: AnimatedRotation(
                  turns: _swapTurns * 0.5,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(
                    LucideIcons.arrowUpDown,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _receiveCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.currenciesYouReceive,
                    isDense: true,
                    suffixIcon: IconButton(
                      onPressed: _copyConverted,
                      icon: const Icon(LucideIcons.copy, size: 16),
                    ),
                  ),
                  onChanged: (_) => _syncConverter(fromSend: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _toCurr,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final c in CurrencyCatalog.core16)
                      DropdownMenuItem(value: c.code, child: Text(c.code)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _toCurr = v);
                      _syncConverter(fromSend: true);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final amt in const ['100', '500', '1000', '5000'])
                ActionChip(
                  label: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text('+$amt'),
                  ),
                  onPressed: () {
                    _sendCtrl.text = amt;
                    _syncConverter(fromSend: true);
                  },
                ),
              if (portfolioBalance > Decimal.zero &&
                  portfolioCurrency == _fromCurr)
                for (final pct in const [25, 50, 75, 100])
                  ActionChip(
                    label: Text(pct == 100 ? 'Max' : '$pct%'),
                    onPressed: () {
                      final share = (portfolioBalance *
                              Decimal.fromInt(pct) /
                              Decimal.fromInt(100))
                          .toDecimal(scaleOnInfinitePrecision: 4)
                          .round(
                            scale: CurrencyMinorUnits.decimalsFor(_fromCurr),
                          );
                      _sendCtrl.text = share.toString();
                      _syncConverter(fromSend: true);
                    },
                  ),
            ],
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${l10n.currenciesMidMarketRate}: 1 $_fromCurr = ${_convRate.toDouble().toStringAsFixed(4)} $_toCurr',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedTab(
    BuildContext context, {
    required List<CurrencyPairDto> pairs,
    required CurrencyPairDto? activePair,
  }) {
    final selectorPairs = pairs.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectorPairs.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final p in selectorPairs)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(p.symbol),
                      ),
                      selected: activePair?.symbol == p.symbol,
                      onSelected: (_) =>
                          ref.read(selectedPairProvider.notifier).select(p),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SimulatedTickPanel(
          pairSymbol: activePair?.symbol ?? '$_fromCurr/$_toCurr',
          spotRate: activePair?.rate.toDouble() ?? _convRate.toDouble(),
          showTradeFeed: true,
        ),
      ],
    );
  }

  Widget _buildRiskTab(
    BuildContext context, {
    required String businessBaseCurrency,
    required Map<String, Decimal> dirRates,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final amount =
        InvoiceCalculator.parseNormalized(_riskAmountCtrl.text) ?? Decimal.zero;

    // Rate of 1 _riskForeignCurrency -> businessBaseCurrency
    Decimal spotRate = Decimal.one;
    if (_riskForeignCurrency != businessBaseCurrency) {
      final baseToForeign = dirRates[_riskForeignCurrency];
      final viewBase = ref.read(viewBaseCurrencyProvider);
      if (viewBase == businessBaseCurrency &&
          baseToForeign != null &&
          baseToForeign > Decimal.zero) {
        spotRate = (Decimal.one / baseToForeign)
            .toDecimal(scaleOnInfinitePrecision: 6);
      } else if (baseToForeign != null &&
          dirRates[businessBaseCurrency] != null &&
          baseToForeign > Decimal.zero) {
        spotRate = (dirRates[businessBaseCurrency]! / baseToForeign)
            .toDecimal(scaleOnInfinitePrecision: 6);
      }
    }

    final spotValuation = (amount * spotRate).round(scale: 4);
    final scenarios = FxRiskCalculator.calculate(
      foreignAmount: amount,
      spotRate: spotRate,
      paymentTermsDays: _riskTermsDays,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AfabCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _riskAmountCtrl,
                      textDirection: TextDirection.ltr,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.currenciesRiskAmountLabel,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _riskForeignCurrency,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.currenciesRiskCurrencyLabel,
                        isDense: true,
                      ),
                      items: [
                        for (final c in CurrencyCatalog.core16)
                          DropdownMenuItem(value: c.code, child: Text(c.code)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _riskForeignCurrency = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.currenciesRiskTermsLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final days in const [15, 30, 60, 90])
                    ChoiceChip(
                      label: Text(l10n.currenciesRiskNetDays(days)),
                      selected: _riskTermsDays == days,
                      onSelected: (_) => setState(() => _riskTermsDays = days),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AfabCard(
          topAccentColor: colors.primary,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currenciesRiskSpotCardTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '1 $_riskForeignCurrency = ${spotRate.toDouble().toStringAsFixed(4)} $businessBaseCurrency',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              MoneyText(
                amount: spotValuation,
                currency: businessBaseCurrency,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.currenciesRiskScenariosTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        for (final s in scenarios) ...[
          AfabCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          s.shiftPct == 0.0
                              ? '0.0% (${l10n.currenciesRiskSpotLabel})'
                              : '${s.shiftPct > 0 ? '+' : ''}${s.shiftPct.toStringAsFixed(1)}%',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '1 $_riskForeignCurrency = ${s.effectiveRate.toDouble().toStringAsFixed(4)} $businessBaseCurrency',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(
                      amount: s.projectedValue,
                      currency: businessBaseCurrency,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (s.shiftPct != 0.0)
                      MoneyText(
                        amount: s.deltaValue,
                        currency: businessBaseCurrency,
                        showSign: true,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: s.deltaValue >= Decimal.zero
                                  ? colors.success
                                  : colors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildAlertsTab(
    BuildContext context, {
    required List<CurrencyPairDto> pairs,
    required List<FxRateAlert> alerts,
    required List<FxRateAlert> triggeredAlerts,
    required Map<String, Decimal> rateByPair,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final base = ref.read(viewBaseCurrencyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.infoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.info.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.bell, size: 17, color: colors.info),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.currenciesAlertsLocalBanner,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              AfabButton(
                label: l10n.currenciesAlertsNewBtn,
                compact: true,
                onPressed: () =>
                    setState(() => _showNewAlertForm = !_showNewAlertForm),
              ),
            ],
          ),
        ),
        if (triggeredAlerts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.successBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.circleCheck, size: 18, color: colors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.currenciesAlertsTriggeredTitle}: ${triggeredAlerts.map((e) => e.pair).join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.success,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_showNewAlertForm) ...[
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final alertTargetOptions = CurrencyCatalog.core16
                  .where((c) => c.code != base)
                  .toList();
              final effectiveAlertTarget = alertTargetOptions
                      .any((c) => c.code == _alertPairTarget)
                  ? _alertPairTarget
                  : alertTargetOptions.first.code;

              return AfabCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('alert_target_$base'),
                            initialValue: effectiveAlertTarget,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.currenciesAlertsPairLabel,
                              isDense: true,
                            ),
                            items: [
                              for (final c in alertTargetOptions)
                                DropdownMenuItem(
                                  value: c.code,
                                  child: Text('$base/${c.code}'),
                                ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _alertPairTarget = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _alertCondition,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.currenciesAlertsConditionLabel,
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'above',
                                child: Text(l10n.currenciesAlertsAbove),
                              ),
                              DropdownMenuItem(
                                value: 'below',
                                child: Text(l10n.currenciesAlertsBelow),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _alertCondition = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _alertRateCtrl,
                      textDirection: TextDirection.ltr,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.currenciesAlertsTargetRate,
                        errorText: _alertRateError,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _showNewAlertForm = false),
                          child: Text(l10n.commonCancel),
                        ),
                        const SizedBox(width: 8),
                        AfabButton(
                          label: l10n.currenciesAlertsSaveBtn,
                          compact: true,
                          onPressed: () async {
                            final parsed = InvoiceCalculator.parseNormalized(
                              _alertRateCtrl.text,
                            );
                            if (parsed == null || parsed <= Decimal.zero) {
                              setState(
                                () => _alertRateError =
                                    l10n.currenciesAlertsInvalidRate,
                              );
                              return;
                            }
                            await ref
                                .read(localFxAlertsProvider.notifier)
                                .addAlert(
                                  base: base,
                                  target: effectiveAlertTarget,
                                  condition: _alertCondition,
                                  targetRate: parsed,
                                );
                            if (!mounted) return;
                            _alertRateCtrl.clear();
                            setState(() {
                              _alertRateError = null;
                              _showNewAlertForm = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 14),
        if (alerts.isEmpty)
          AfabEmptyState(
            icon: LucideIcons.bell,
            title: l10n.currenciesAlertsEmptyTitle,
            description: l10n.currenciesAlertsEmptyDesc,
            actionLabel: l10n.currenciesAlertsNewBtn,
            onAction: () => setState(() => _showNewAlertForm = true),
          )
        else
          for (final a in alerts) ...[
            Builder(
              builder: (ctx) {
                final curRate = rateByPair[a.pair];
                final triggered = a.isTriggered(curRate);
                final awayPct = (curRate != null && curRate > Decimal.zero)
                    ? (((a.targetRate - curRate).toDouble() / curRate.toDouble()) *
                            100.0)
                        .abs()
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AfabCard(
                    topAccentColor: triggered ? colors.success : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      a.pair,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  AfabStatusBadge(
                                    label: a.condition == 'above'
                                        ? l10n.currenciesAlertsAbove
                                        : l10n.currenciesAlertsBelow,
                                    variant: triggered
                                        ? AfabBadgeVariant.success
                                        : AfabBadgeVariant.neutral,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 10,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      a.targetRate.toDouble().toStringAsFixed(4),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ),
                                  if (awayPct != null)
                                    Text(
                                      l10n.currenciesAlertsAwayPct(
                                        awayPct.toStringAsFixed(2),
                                      ),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: a.active,
                          onChanged: (_) => ref
                              .read(localFxAlertsProvider.notifier)
                              .toggleAlert(a.id),
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: colors.danger,
                          ),
                          onPressed: () => ref
                              .read(localFxAlertsProvider.notifier)
                              .deleteAlert(a.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
      ],
    );
  }

  Widget _buildDirectoryTab(
    BuildContext context, {
    required String viewBase,
    required Map<String, Decimal> dirRates,
    required List<CurrencyPairDto> pairs,
    required bool isExpanded,
  }) {
    final l10n = context.l10n;
    final query = _dirSearchCtrl.text.trim().toLowerCase();
    final filtered = CurrencyCatalog.core16.where((c) {
      if (query.isEmpty) return true;
      return c.code.toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query);
    }).toList();

    final pairByTarget = {for (final p in pairs) p.target: p};

    void convertTo(String targetCode) {
      setState(() {
        _fromCurr = viewBase;
        _toCurr = targetCode;
        _tab = CurrenciesTab.markets;
      });
      final p = pairByTarget[targetCode];
      if (p != null) {
        ref.read(selectedPairProvider.notifier).select(p);
      }
      _syncConverter(fromSend: true);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _dirSearchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l10n.currenciesDirectorySearchHint,
            isDense: true,
            prefixIcon: const Icon(LucideIcons.search, size: 18),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          AfabEmptyState(
            icon: LucideIcons.searchX,
            title: l10n.commonNoData,
            description: l10n.currenciesDirectoryEmpty(_dirSearchCtrl.text),
          )
        else if (isExpanded)
          AfabCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.txFormCurrencyLabel)),
                  DataColumn(label: Text(l10n.currenciesYouSend)),
                  DataColumn(label: Text(l10n.currenciesMidMarketRate)),
                  const DataColumn(label: Text('24h')),
                  DataColumn(label: Text(l10n.currenciesDirectoryConvertBtn)),
                ],
                rows: [
                  for (final c in filtered)
                    DataRow(
                      cells: [
                        DataCell(Text('${c.symbol} ${c.code}')),
                        DataCell(Text(c.name)),
                        DataCell(
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              dirRates[c.code]?.toDouble().toStringAsFixed(4) ??
                                  '—',
                            ),
                          ),
                        ),
                        DataCell(
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              pairByTarget[c.code] != null
                                  ? '${pairByTarget[c.code]!.change24h >= 0 ? '+' : ''}${pairByTarget[c.code]!.change24h.toStringAsFixed(2)}%'
                                  : '—',
                            ),
                          ),
                        ),
                        DataCell(
                          TextButton(
                            onPressed: () => convertTo(c.code),
                            child: Text(l10n.currenciesDirectoryConvertBtn),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          )
        else
          for (final c in filtered) ...[
            AfabCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: context.afabColors.secondaryBg,
                    child: Text(
                      c.symbol,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: context.afabColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.code,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          dirRates[c.code]?.toDouble().toStringAsFixed(4) ?? '—',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => convertTo(c.code),
                        child: Text(l10n.currenciesDirectoryConvertBtn),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _FeaturedPairCard extends StatelessWidget {
  const _FeaturedPairCard({
    required this.pair,
    required this.selected,
    required this.onTap,
  });

  final CurrencyPairDto pair;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final isPos = pair.change24h >= 0;
    final accent = isPos ? colors.success : colors.danger;
    final spark = pair.sparkline;

    return AfabCard(
      onTap: onTap,
      topAccentColor: selected ? colors.primary : accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    pair.symbol,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              AfabStatusBadge(
                label:
                    '${isPos ? '+' : ''}${pair.change24h.toStringAsFixed(2)}%',
                variant:
                    isPos ? AfabBadgeVariant.success : AfabBadgeVariant.danger,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              pair.rate.toDouble().toStringAsFixed(4),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (spark.length >= 2) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < spark.length; i++)
                            FlSpot(i.toDouble(), spark[i]),
                        ],
                        isCurved: true,
                        color: accent,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              'L ${pair.low24h.toDouble().toStringAsFixed(4)} · H ${pair.high24h.toDouble().toStringAsFixed(4)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
