import 'dart:async';

import 'package:afab_mobile/app/shell/adaptive_shell.dart';
import 'package:afab_mobile/app/shell/shell_app_bar.dart';
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
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_composer.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

class _FakeHealthNotifier extends AiHealthNotifier {
  _FakeHealthNotifier({required this.healthDto});
  final AiHealthDto healthDto;

  @override
  AiHealthState build() => AiHealthState(
        health: healthDto,
        backendConnected: true,
        lastChecked: DateTime(2026, 11, 26, 12, 0),
      );

  @override
  Future<void> checkNow({bool fresh = true}) async {}
}

class _FakeSpeechService implements SpeechDictationService {
  @override
  Future<void> cancel() async {}

  @override
  Future<bool> startListening({
    required DictationLocaleOption locale,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String message, bool permissionDenied) onError,
  }) async {
    onResult('How much revenue did we make', false);
    return true;
  }

  @override
  Future<void> stop() async {}
}

class _CategoryListStub extends CategoryListNotifier {
  @override
  Future<List<CategoryDto>> build() async => const [
        CategoryDto(
          id: 'cat-1',
          name: 'Office Supplies',
          type: 'EXPENSE',
          systemDefault: false,
        ),
      ];
}

class _FakeAiRepository extends AiRepository {
  _FakeAiRepository()
      : super(dio: Dio(), sseDio: Dio(), eventBus: GlobalEventBus());

  bool approveTxCalled = false;
  bool quotaFailNext = false;

  @override
  Future<AiStatusDto> getStatus({bool fresh = false}) async {
    return AiStatusDto(
      health: const AiHealthDto(
        enabled: true,
        ollamaReachable: true,
        chatModel: 'gemma4:e4b',
        chatModelReady: true,
        chatModelLoaded: true,
        embedModel: 'embeddinggemma-2:270m',
        embedModelReady: true,
        busy: false,
        latencyMs: 38,
      ),
      indexedChunks: 42,
      approvedMemories: 3,
      quota: const AiTokenUsageDto(
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: 0,
        monthlyTokensUsed: 800,
        monthlyTokensLimit: 10000,
        monthlyTokensRemaining: 9200,
        monthlyQueriesUsed: 5,
        monthlyQueriesLimit: 50,
        monthlyQueriesRemaining: 45,
        planSlug: 'plus',
        planName: 'Plus',
      ),
    );
  }

  @override
  Future<List<AiConversationSummaryDto>> listConversations() async => [
        AiConversationSummaryDto(
          id: 'conv-1',
          title: 'Q4 Runway Review',
          locale: 'en',
          activeLanguage: 'EN',
          updatedAt: DateTime.now(),
          messageCount: 2,
        ),
      ];

  @override
  Future<List<BusinessMemoryDto>> listMemory({String status = 'ALL'}) async => [
        const BusinessMemoryDto(
          id: 'mem-1',
          memoryType: BusinessMemoryType.supplierPattern,
          title: 'STEG Electricity',
          content: 'STEG bills bi-monthly; classify as Utilities.',
          status: 'APPROVED',
          hasVector: true,
        ),
      ];

  @override
  Stream<SseEvent> streamChat({
    required String message,
    String? conversationId,
    required String locale,
    AiReasoningMode reasoningMode = AiReasoningMode.fast,
    List<String> attachmentIds = const [],
    Map<String, String>? screenContext,
    CancelToken? cancelToken,
  }) async* {
    if (quotaFailNext) {
      yield const SseErrorEvent(
        code: 'PLAN_LIMIT_REACHED',
        message: 'Monthly AI query quota exhausted',
        details: {'feature': 'ai.chat.queries_per_month', 'limit': 50, 'used': 50},
      );
      return;
    }

    yield const SseStatusEvent(
      phase: 'warming_model',
      conversationId: 'conv-1',
      activeLanguage: 'EN',
      reasoningMode: 'deep',
    );
    yield const SseThoughtEvent(text: 'Auditing revenue and utilities...');
    yield const SseToolStartEvent(tool: 'get_business_summary');
    yield const SseToolDoneEvent(
      tool: 'get_business_summary',
      evidenceCount: 1,
    );
    yield const SseDeltaEvent(text: '### Revenue Breakdown\n\nNet profit is **1,250.500 TND**.');
    yield SseDoneEvent(
      response: AiChatResponseDto(
        conversationId: 'conv-1',
        conversationTitle: 'Q4 Runway Review',
        messageId: 'msg-1',
        content: '### Revenue Breakdown\n\nNet profit is **1,250.500 TND**.\n\n```sql\nSELECT 1;\n```\n\n| Metric | Value |\n|---|---|\n| Revenue | 5,000 |',
        thinkingContent: 'Verified BigDecimal summary totals.',
        toolsUsed: const ['get_business_summary'],
        dataCoverage: 'RAG_GROUNDED',
        modelId: 'gemma4:e4b',
        reasoningMode: reasoningMode.apiValue,
        responseLanguage: 'EN',
        latencyMs: 1200,
        charts: const [
          AiChartSpecDto(
            id: 'ch-1',
            chartType: 'bar',
            title: 'Monthly Cash Flow',
            currency: 'TND',
            xKey: 'month',
            series: [
              AiChartSeriesSpecDto(
                key: 'inflow',
                label: 'Inflow',
                colorToken: 'emerald',
              ),
            ],
            data: [
              {'month': 'Oct', 'inflow': 3200},
              {'month': 'Nov', 'inflow': 5000},
            ],
          ),
        ],
        actionDrafts: const [
          AiActionDraftDto(
            draftId: 'd-tx',
            actionType: 'CREATE_TRANSACTION',
            status: 'PENDING',
            title: 'Office Supplies',
            summary: '120 TND expense',
            payload: {
              'type': 'EXPENSE',
              'amount': 120.0,
              'currency': 'TND',
              'description': 'Printer paper',
              'transactionDate': '2026-11-26',
              'paymentMethod': 'CARD',
            },
          ),
        ],
        evidence: [
          AiEvidenceItemDto(
            type: 'TRANSACTION',
            id: 'tx-1',
            title: 'SaaS Retainer',
            subtitle: '2026-11-20',
            amount: Decimal.parse('5000.000'),
            currency: 'TND',
            href: '/dashboard/transactions',
          ),
        ],
        tokenUsage: const AiTokenUsageDto(
          promptTokens: 120,
          completionTokens: 90,
          totalTokens: 210,
          monthlyTokensUsed: 1010,
          monthlyTokensLimit: 10000,
          monthlyTokensRemaining: 8990,
          monthlyQueriesUsed: 6,
          monthlyQueriesLimit: 50,
          monthlyQueriesRemaining: 44,
          planSlug: 'plus',
          planName: 'Plus',
        ),
        suggestedFollowUps: const ['Check overdue invoices'],
      ),
    );
  }

  @override
  Future<AiActionDraftDto> approveTransactionDraft(
    Map<String, dynamic> payload,
  ) async {
    approveTxCalled = true;
    return const AiActionDraftDto(
      draftId: 'd-tx',
      actionType: 'CREATE_TRANSACTION',
      status: 'APPROVED',
      title: 'Office Supplies',
      summary: '120 TND expense saved',
      createdEntityId: 'tx-new-1',
      createdEntityHref: '/dashboard/transactions',
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
  required _FakeAiRepository repo,
  required AiHealthDto health,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
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
      isOnlineProvider.overrideWithValue(true),
      aiRepositoryProvider.overrideWithValue(repo),
      aiHealthProvider.overrideWith(() => _FakeHealthNotifier(healthDto: health)),
      speechDictationServiceProvider.overrideWithValue(_FakeSpeechService()),
      aiPulseProvider.overrideWith(
        (ref) async => AiPulseDto(
          currency: 'TND',
          monthNetProfit: Decimal.parse('1250.500'),
          overdueCount: 2,
          highCount: 1,
          alerts: const [],
        ),
      ),
      categoryListProvider.overrideWith(_CategoryListStub.new),
      aiCustomersDropdownProvider.overrideWith(
        (ref) async => const <CustomerDto>[],
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
        settings: const AppearanceSettings(),
        brightness: brightness,
        locale: locale,
      ),
      home: const AiCopilotScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AiCopilotScreen (`AI-01`) widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
      'renders Welcome, streams SSE message with Chart + Action Draft approval, and renders Dark AR tablet cleanly',
      (tester) async {
        final repo = _FakeAiRepository();
        const readyHealth = AiHealthDto(
          enabled: true,
          ollamaReachable: true,
          chatModel: 'gemma4:e4b',
          chatModelReady: true,
          chatModelLoaded: true,
          embedModel: 'embeddinggemma-2:270m',
          embedModelReady: true,
          busy: false,
          latencyMs: 38,
        );
        _setViewport(tester, const Size(390, 844));

        await tester.pumpWidget(
          _wrap(prefs: prefs, repo: repo, health: readyHealth),
        );
        await tester.pumpAndSettle();

        expect(find.text('Morning CFO Brief'), findsOneWidget);
        expect(find.text('Monthly Profit & Loss'), findsOneWidget);

        // Cycle voice language EN -> FR -> TN
        expect(find.text('EN'), findsAtLeastNWidgets(1));

        // Send a message and receive Markdown + Chart + Action Draft + Evidence
        await tester.enterText(
          find.byType(TextField).first,
          'Summarize revenue',
        );
        await tester.pump();
        await tester.tap(find.byTooltip('Send'));
        await tester.pumpAndSettle();

        expect(find.text('Monthly Cash Flow'), findsOneWidget);
        expect(find.text('SaaS Retainer'), findsOneWidget);
        expect(find.text('Check overdue invoices'), findsOneWidget);

        // Approve CREATE_TRANSACTION draft
        final approveBtn = find.text('Approve & Save');
        await tester.ensureVisible(approveBtn);
        await tester.pumpAndSettle();
        await tester.tap(approveBtn);
        await tester.pumpAndSettle();

        expect(repo.approveTxCalled, isTrue);
        expect(find.textContaining('Saved · Office Supplies'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Tablet Dark AR RTL
        _setViewport(tester, const Size(1024, 768));
        await tester.pumpWidget(
          _wrap(
            prefs: prefs,
            repo: repo,
            health: readyHealth,
            locale: const Locale('ar'),
            brightness: Brightness.dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'displays Ollama Offline banner cleanly',
      (tester) async {
        final repo = _FakeAiRepository();
        const offlineHealth = AiHealthDto(
          enabled: true,
          ollamaReachable: false,
          chatModel: 'gemma4:e4b',
          chatModelReady: false,
          chatModelLoaded: false,
          embedModel: 'embeddinggemma-2:270m',
          embedModelReady: false,
          busy: false,
          latencyMs: 0,
        );
        _setViewport(tester, const Size(390, 844));

        await tester.pumpWidget(
          _wrap(prefs: prefs, repo: repo, health: offlineHealth),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('ollama pull gemma4:e4b'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AdaptiveShell hides redundant workspace AppBar on phone Copilot and collapses NavigationBar when keyboard opens',
      (tester) async {
        final repo = _FakeAiRepository();
        const readyHealth = AiHealthDto(
          enabled: true,
          ollamaReachable: true,
          chatModel: 'gemma4:e4b',
          chatModelReady: true,
          chatModelLoaded: true,
          embedModel: 'embeddinggemma-2:270m',
          embedModelReady: true,
          busy: false,
          latencyMs: 38,
        );
        _setViewport(tester, const Size(390, 844));
        tester.view.viewInsets = FakeViewPadding.zero;
        addTearDown(tester.view.resetViewInsets);

        final router = GoRouter(
          initialLocation: '/copilot',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, _, navigationShell) =>
                  AdaptiveShell(navigationShell: navigationShell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/copilot',
                      builder: (_, _) => const AiCopilotScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
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
              activeBusinessIdProvider.overrideWith(
                ActiveBusinessIdNotifier.new,
              ),
              isOnlineProvider.overrideWithValue(true),
              aiRepositoryProvider.overrideWithValue(repo),
              aiHealthProvider.overrideWith(
                () => _FakeHealthNotifier(healthDto: readyHealth),
              ),
              speechDictationServiceProvider.overrideWithValue(
                _FakeSpeechService(),
              ),
              aiPulseProvider.overrideWith(
                (ref) async => AiPulseDto(
                  currency: 'TND',
                  monthNetProfit: Decimal.parse('1250.500'),
                  overdueCount: 0,
                  highCount: 0,
                  alerts: const [],
                ),
              ),
              categoryListProvider.overrideWith(_CategoryListStub.new),
              aiCustomersDropdownProvider.overrideWith(
                (ref) async => const <CustomerDto>[],
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppearanceThemeBuilder.build(
                settings: const AppearanceSettings(),
                brightness: Brightness.dark,
                locale: const Locale('en'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ShellAppBar), findsNothing);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(CopilotComposer), findsOneWidget);

        // Simulate keyboard opening (300px bottom inset)
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump();
        await tester.pumpAndSettle();

        final navRect = tester.getRect(find.byType(NavigationBar));
        final animatedAlign = tester.widget<AnimatedAlign>(
          find
              .ancestor(
                of: find.byType(NavigationBar),
                matching: find.byType(AnimatedAlign),
              )
              .first,
        );
        expect(animatedAlign.heightFactor, 0.0);
        expect(navRect.top, greaterThanOrEqualTo(544));
        expect(find.byType(CopilotComposer), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
