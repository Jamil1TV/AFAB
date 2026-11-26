import 'dart:async';

import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/connectivity_provider.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/data/ai_repository.dart';
import 'package:afab_mobile/features/ai/data/sse_parser.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/ai/domain/speech_dictation_service.dart';
import 'package:afab_mobile/features/ai/presentation/ai_copilot_screen.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/auth/presentation/login_screen.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/invoices/domain/invoices_providers.dart';
import 'package:afab_mobile/features/invoices/presentation/invoices_screen.dart';
import 'package:afab_mobile/features/notifications/data/notification_dto.dart';
import 'package:afab_mobile/features/notifications/domain/notifications_provider.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:afab_mobile/features/plans/data/plans_repository.dart';
import 'package:afab_mobile/features/plans/presentation/plans_and_subscription_screen.dart';
import 'package:afab_mobile/features/settings/presentation/settings_home_screen.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/transactions_screen.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SweepAuthNotifier extends AuthNotifier {
  @override
  SessionState build() => const SessionState(
        status: SessionStatus.authenticated,
        user: UserProfile(
          id: 'u1',
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

class _FakeAuthRepo extends Fake implements AuthRepository {}

class _SweepNotifications extends NotificationsNotifier {
  @override
  Future<NotificationsResponseDto> build() async =>
      const NotificationsResponseDto(unreadCount: 0, notifications: []);
}

class _SweepCategories extends CategoryListNotifier {
  @override
  Future<List<CategoryDto>> build() async => const [
        CategoryDto(
          id: 'c1',
          businessId: null,
          name: 'Software',
          type: 'EXPENSE',
          icon: 'Laptop',
          color: '#8B5CF6',
          systemDefault: true,
        ),
      ];
}

class _SweepAiHealth extends AiHealthNotifier {
  @override
  AiHealthState build() => const AiHealthState(
        health: AiHealthDto(
          enabled: true,
          ollamaReachable: true,
          chatModel: 'gemma4:e4b',
          chatModelReady: true,
          chatModelLoaded: true,
          embedModel: 'embeddinggemma-2:270m',
          embedModelReady: true,
          busy: false,
          latencyMs: 25,
        ),
        backendConnected: true,
      );

  @override
  Future<void> checkNow({bool fresh = true}) async {}
}

class _SweepSpeech implements SpeechDictationService {
  @override
  Future<void> cancel() async {}
  @override
  Future<bool> startListening({
    required DictationLocaleOption locale,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String message, bool permissionDenied) onError,
  }) async =>
      true;
  @override
  Future<void> stop() async {}
}

class _SweepAiRepo extends AiRepository {
  _SweepAiRepo() : super(dio: Dio(), sseDio: Dio(), eventBus: GlobalEventBus());

  @override
  Future<AiStatusDto> getStatus({bool fresh = false}) async => AiStatusDto(
        health: const AiHealthDto(
          enabled: true,
          ollamaReachable: true,
          chatModel: 'gemma4:e4b',
          chatModelReady: true,
          chatModelLoaded: true,
          embedModel: 'embeddinggemma-2:270m',
          embedModelReady: true,
          busy: false,
          latencyMs: 25,
        ),
        indexedChunks: 10,
        approvedMemories: 1,
        quota: const AiTokenUsageDto(
          promptTokens: 0,
          completionTokens: 0,
          totalTokens: 0,
          monthlyTokensUsed: 100,
          monthlyTokensLimit: 10000,
          monthlyTokensRemaining: 9900,
          monthlyQueriesUsed: 2,
          monthlyQueriesLimit: 50,
          monthlyQueriesRemaining: 48,
          planSlug: 'plus',
          planName: 'Plus',
        ),
      );

  @override
  Future<List<AiConversationSummaryDto>> listConversations() async => const [];

  @override
  Stream<SseEvent> streamChat({
    required String message,
    String? conversationId,
    required String locale,
    AiReasoningMode reasoningMode = AiReasoningMode.fast,
    List<String> attachmentIds = const [],
    Map<String, String>? screenContext,
    CancelToken? cancelToken,
  }) =>
      const Stream.empty();
}

class _SweepInvoicesRepo extends InvoicesRepository {
  _SweepInvoicesRepo() : super(Dio());
}

class _SweepPlansRepo extends PlansRepository {
  _SweepPlansRepo() : super(Dio());

  @override
  Future<BillingHistoryResponseDto> getBillingHistory() async =>
      const BillingHistoryResponseDto(
        paymentHistory: [],
        subscriptionHistory: [],
      );
}

class _SweepBizRepo extends BusinessRepository {
  _SweepBizRepo() : super(Dio());

  @override
  Future<BusinessAllocationDto> getAllocations() async =>
      const BusinessAllocationDto(
        currentPlanSlug: 'plus',
        currentPlanName: 'Plus',
        editableLimit: 3,
        editableCount: 1,
        readOnlyCount: 0,
        totalOwnedCount: 1,
        allocationAttentionRequired: false,
        businesses: [
          BusinessAllocationItemDto(
            id: 'biz-1',
            name: 'Carthage Labs',
            currency: 'TND',
            editable: true,
            primary: true,
            active: true,
          ),
        ],
      );
}

Future<void> _pumpSweep({
  required WidgetTester tester,
  required SharedPreferences prefs,
  required Size size,
  required double textScale,
  required Locale locale,
  required AppearanceSettings appearance,
  required Brightness brightness,
  required Widget screen,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final capturedErrors = <FlutterErrorDetails>[];
  final prevOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    capturedErrors.add(details);
  };

  try {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          isOnlineProvider.overrideWithValue(true),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepo()),
          authNotifierProvider.overrideWith(_SweepAuthNotifier.new),
          businessListProvider.overrideWith(
            (_) async => const [
              BusinessDto(
                id: 'biz-1',
                name: 'Carthage Labs',
                currency: 'TND',
                active: true,
                editable: true,
                accessMode: 'EDITABLE',
                userRole: 'OWNER',
                primary: true,
              ),
            ],
          ),
          activeBusinessIdProvider.overrideWith(ActiveBusinessIdNotifier.new),
          notificationsProvider.overrideWith(_SweepNotifications.new),
          categoryListProvider.overrideWith(_SweepCategories.new),
          dashboardSummaryProvider.overrideWith(
            (_) async => DashboardSummaryDto(
              revenue: KpiMetricDto(
                formattedValue: 'DT 12,450.000',
                change: '+12%',
                isPositive: true,
                rawValue: Decimal.parse('12450'),
                rawChange: Decimal.parse('12'),
              ),
              expenses: KpiMetricDto(
                formattedValue: 'DT 3,100.000',
                change: '-5%',
                isPositive: false,
                rawValue: Decimal.parse('3100'),
                rawChange: Decimal.parse('-5'),
              ),
              profit: KpiMetricDto(
                formattedValue: 'DT 9,350.000',
                change: '+15%',
                isPositive: true,
                rawValue: Decimal.parse('9350'),
                rawChange: Decimal.parse('15'),
              ),
              cashFlow: KpiMetricDto(
                formattedValue: 'DT 8,900.000',
                change: '+8%',
                isPositive: true,
                rawValue: Decimal.parse('8900'),
                rawChange: Decimal.parse('8'),
              ),
              revenueData: const [
                RevenueDataPointDto(
                  month: 'Nov',
                  name: 'Nov',
                  revenue: 12450,
                  expenses: 3100,
                ),
              ],
              transactions: const [],
              expenseCategories: const [],
              reminders: const [],
              customers: const [],
              currency: 'TND',
              businessName: 'Carthage Labs',
              budgets: BudgetSummaryDto(
                currency: 'TND',
                activeBudgetCount: 0,
                approachingCount: 0,
                overBudgetCount: 0,
                budgets: const [],
              ),
            ),
          ),
          aiPulseProvider.overrideWith(
            (_) async => const AiPulseDto(currency: 'TND', alerts: []),
          ),
          subscriptionSnapshotProvider.overrideWith(
            (_) async => const SubscriptionSnapshotDto(
              planSlug: 'plus',
              planName: 'Plus',
              status: 'ACTIVE',
              isTrial: false,
              allocationAttentionRequired: false,
              editableBusinessLimit: 3,
              editableBusinessCount: 1,
              totalBusinessCount: 1,
            ),
          ),
          transactionListProvider.overrideWith(
            (_) async => TransactionPageDto(
              content: const [],
              pageNumber: 0,
              pageSize: 15,
              totalElements: 0,
              totalPages: 0,
              totalInflow: Decimal.zero,
              totalOutflow: Decimal.zero,
              netBalance: Decimal.zero,
              currency: 'TND',
            ),
          ),
          invoicesRepositoryProvider.overrideWithValue(_SweepInvoicesRepo()),
          invoiceSummaryProvider.overrideWith(
            (_) async => InvoiceSummaryDto(
              totalInvoices: 0,
              paidInvoices: 0,
              pendingInvoices: 0,
              overdueInvoices: 0,
              totalInvoiceAmount: Decimal.zero,
              paidAmount: Decimal.zero,
              pendingAmount: Decimal.zero,
              overdueAmount: Decimal.zero,
              currency: 'TND',
              statusBreakdown: const [],
              upcomingDueList: const [],
            ),
          ),
          invoicesListProvider.overrideWith(
            (_) async => InvoicePageDto(
              content: const [],
              pageNumber: 0,
              pageSize: 15,
              totalElements: 0,
              totalPages: 0,
              totalInvoiced: Decimal.zero,
              totalPaid: Decimal.zero,
              totalOutstanding: Decimal.zero,
              currency: 'TND',
            ),
          ),
          aiRepositoryProvider.overrideWithValue(_SweepAiRepo()),
          aiHealthProvider.overrideWith(_SweepAiHealth.new),
          speechDictationServiceProvider.overrideWithValue(_SweepSpeech()),
          aiCustomersDropdownProvider.overrideWith(
            (_) async => const <CustomerDto>[],
          ),
          plansRepositoryProvider.overrideWithValue(_SweepPlansRepo()),
          businessRepositoryProvider.overrideWithValue(_SweepBizRepo()),
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
            settings: appearance,
            brightness: brightness,
            locale: locale,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  } finally {
    FlutterError.onError = prevOnError;
  }
  expect(
    capturedErrors,
    isEmpty,
    reason: capturedErrors.map((e) => e.toString()).join('\n---\n'),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 7 Responsive & Accessibility Matrix Sweep', () {
    final entries = <({String name, Widget screen})>[
      (name: 'LoginScreen', screen: const LoginScreen()),
      (name: 'DashboardScreen', screen: const DashboardScreen()),
      (name: 'TransactionsScreen', screen: const TransactionsScreen()),
      (name: 'InvoicesScreen', screen: const InvoicesScreen()),
      (name: 'AiCopilotScreen', screen: const AiCopilotScreen()),
      (name: 'PlansAndSubscriptionScreen', screen: const PlansAndSubscriptionScreen()),
      (name: 'SettingsHomeScreen', screen: const SettingsHomeScreen()),
    ];

    for (final entry in entries) {
      testWidgets(
        '${entry.name}: zero overflow at 320x568 @ 1.3x Light EN and 1280x800 OLED Dark AR RTL',
        (tester) async {
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();

          await _pumpSweep(
            tester: tester,
            prefs: prefs,
            size: const Size(320, 568),
            textScale: 1.3,
            locale: const Locale('en'),
            appearance: const AppearanceSettings(),
            brightness: Brightness.light,
            screen: entry.screen,
          );
          await _pumpSweep(
            tester: tester,
            prefs: prefs,
            size: const Size(1280, 800),
            textScale: 1.0,
            locale: const Locale('ar'),
            appearance: const AppearanceSettings(
              darkSurface: AfabDarkSurface.oled,
            ),
            brightness: Brightness.dark,
            screen: entry.screen,
          );
        },
      );
    }
  });
}
