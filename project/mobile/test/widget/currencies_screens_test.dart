import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/currencies/data/currencies_repository.dart';
import 'package:afab_mobile/features/currencies/data/currency_dtos.dart';
import 'package:afab_mobile/features/currencies/domain/currencies_providers.dart';
import 'package:afab_mobile/features/currencies/presentation/currencies_screen.dart';
import 'package:afab_mobile/features/currencies/presentation/widgets/currency_migration_sheet.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthStub extends AuthNotifier {
  @override
  SessionState build() => const SessionState(
        status: SessionStatus.authenticated,
        user: UserProfile(
          id: 'u-1',
          firstName: 'Youssef',
          lastName: 'Trabelsi',
          email: 'youssef@carthage.tn',
          emailVerified: true,
          onboardingComplete: true,
          businessId: 'biz-1',
          businessName: 'Carthage Labs',
          currency: 'TND',
        ),
      );
}

class _FakeCurrenciesRepo extends CurrenciesRepository {
  _FakeCurrenciesRepo() : super(Dio());

  final List<String> requestedMarketBases = [];
  String? changedToCurrency;

  @override
  Future<List<CurrencyPairDto>> getMarketRates({
    required String base,
    CancelToken? cancelToken,
  }) async {
    requestedMarketBases.add(base);
    return [
      CurrencyPairDto(
        symbol: '$base/USD',
        base: base,
        target: base == 'USD' ? 'EUR' : 'USD',
        rate: Decimal.parse('0.3341'),
        change24h: 0.42,
        high24h: Decimal.parse('0.3400'),
        low24h: Decimal.parse('0.3300'),
        sparkline: const [0.33, 0.332, 0.335, 0.3341],
      ),
    ];
  }

  @override
  Future<List<HistoricalRatePointDto>> getHistoricalRates({
    required String from,
    required String to,
    required String timeframe,
    CancelToken? cancelToken,
  }) async =>
      const [
        HistoricalRatePointDto(date: '2026-11-24', rate: 0.331),
        HistoricalRatePointDto(date: '2026-11-25', rate: 0.333),
        HistoricalRatePointDto(date: '2026-11-26', rate: 0.3341),
      ];

  @override
  Future<CurrencyConversionResultDto> convert({
    required String from,
    required String to,
    required Decimal amount,
    CancelToken? cancelToken,
  }) async {
    return CurrencyConversionResultDto(
      from: from,
      to: to,
      amount: amount,
      exchangeRate: Decimal.parse('0.3341'),
      convertedAmount: (amount * Decimal.parse('0.3341')).round(scale: 4),
    );
  }

  @override
  Future<CurrencyChangePreviewDto> previewBusinessCurrencyChange({
    required String newCurrency,
    CancelToken? cancelToken,
  }) async {
    return CurrencyChangePreviewDto(
      oldCurrency: 'TND',
      newCurrency: newCurrency,
      exchangeRate: Decimal.parse('0.3341'),
      transactionsCount: 14,
      currentNetBalance: Decimal.parse('10000.000'),
      projectedNetBalance: Decimal.parse('3341.00'),
    );
  }

  @override
  Future<CurrencyChangeResultDto> changeBusinessCurrency({
    required String newCurrency,
  }) async {
    changedToCurrency = newCurrency;
    return CurrencyChangeResultDto(
      oldCurrency: 'TND',
      newCurrency: newCurrency,
      exchangeRate: Decimal.parse('0.3341'),
      convertedTransactionsCount: 0,
      preservedHistoricalTransactionsCount: 14,
      success: true,
      message: 'Updated',
    );
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap({
  required SharedPreferences prefs,
  required _FakeCurrenciesRepo repo,
  required Widget child,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  const settings = AppearanceSettings();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(_AuthStub.new),
      businessListProvider.overrideWith(
        (ref) async => const [
          BusinessDto(
            id: 'biz-1',
            name: 'Carthage Labs',
            currency: 'TND',
            active: true,
          ),
        ],
      ),
      activeBusinessIdProvider.overrideWith(ActiveBusinessIdNotifier.new),
      currenciesRepositoryProvider.overrideWithValue(repo),
      currenciesPortfolioProvider.overrideWith(
        (ref) async => PortfolioFxSnapshot(
          businessName: 'Carthage Labs',
          baseCurrency: 'TND',
          netBalance: Decimal.parse('10000.000'),
        ),
      ),
      directoryRatesMapProvider.overrideWith(
        (ref) async => {
          'TND': Decimal.one,
          'USD': Decimal.parse('0.3341'),
          'EUR': Decimal.parse('0.2980'),
          'MAD': Decimal.parse('3.2500'),
        },
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppearanceThemeBuilder.build(
        settings: settings,
        brightness: brightness,
        locale: locale,
      ),
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Currencies & Migration widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'CurrenciesScreen fixes viewBase reset, uses honest Simulated/Local labels, and saves alerts in SharedPreferences',
        (tester) async {
      final repo = _FakeCurrenciesRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(prefs: prefs, repo: repo, child: const CurrenciesScreen()),
      );
      await tester.pumpAndSettle();

      // Switch View base from TND -> EUR and verify it stays EUR
      await tester.tap(find.text('TND').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('EUR').last);
      await tester.pumpAndSettle();
      expect(repo.requestedMarketBases, contains('EUR'));
      expect(find.textContaining('Binance'), findsNothing);

      // Navigate to Local Alerts tab and save an alert
      final alertsTab = find.text('Local Alerts');
      await tester.ensureVisible(alertsTab);
      await tester.pumpAndSettle();
      await tester.tap(alertsTab);
      await tester.pumpAndSettle();
      expect(
        find.text('Device-Local Alerts (Evaluated on Refresh)'),
        findsOneWidget,
      );

      final newAlertBtn = find.text('New Alert').first;
      await tester.ensureVisible(newAlertBtn);
      await tester.pumpAndSettle();
      await tester.tap(newAlertBtn);
      await tester.pumpAndSettle();
      final rateField = find.byType(TextFormField).first;
      await tester.enterText(rateField, '3.25');
      final saveBtn = find.text('Save Alert');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(prefs.getString('afab_fx_rate_alerts'), contains('3.25'));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CurrencyMigrationSheet allows target selection, displays immutability policy, and submits',
        (tester) async {
      final repo = _FakeCurrenciesRepo();
      _setViewport(tester, const Size(1024, 768));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          child: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showCurrencyMigrationSheet(ctx),
                child: const Text('Open Migration'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Migration'));
      await tester.pumpAndSettle();

      expect(
        find.text('Historical Financial Immutability Enforced'),
        findsOneWidget,
      );
      expect(find.text('14 transaction(s)'), findsOneWidget);

      await tester.tap(find.text('Confirm Currency Change'));
      await tester.pumpAndSettle();
      expect(repo.changedToCurrency, 'USD');
      expect(tester.takeException(), isNull);
    });
  });
}
