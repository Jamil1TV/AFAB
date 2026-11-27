import 'package:afab_mobile/app/shell/adaptive_shell.dart';
import 'package:afab_mobile/app/shell/afab_floating_nav_dock.dart';
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
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_aurora_backdrop.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_markdown.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_message_bubble.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_thinking_card.dart';
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
import 'package:afab_mobile/features/notifications/data/notification_dto.dart';
import 'package:afab_mobile/features/notifications/domain/notifications_provider.dart';
import 'package:afab_mobile/shared/widgets/afab_brand_logo.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PerfAuthNotifier extends AuthNotifier {
  @override
  SessionState build() => const SessionState(
        status: SessionStatus.authenticated,
        user: UserProfile(
          id: 'u-perf',
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

class _PerfHealthNotifier extends AiHealthNotifier {
  @override
  AiHealthState build() => AiHealthState(
        health: const AiHealthDto(
          enabled: true,
          ollamaReachable: true,
          chatModel: 'gemma4:e4b',
          chatModelReady: true,
          chatModelLoaded: true,
          embedModel: 'embeddinggemma-2:270m',
          embedModelReady: true,
          busy: false,
          latencyMs: 28,
        ),
        backendConnected: true,
        lastChecked: DateTime(2026, 11, 27, 12, 0),
      );

  @override
  Future<void> checkNow({bool fresh = true}) async {}
}

class _PerfNotificationsNotifier extends NotificationsNotifier {
  @override
  Future<NotificationsResponseDto> build() async =>
      const NotificationsResponseDto(unreadCount: 0, notifications: []);
}

class _PerfCategoriesNotifier extends CategoryListNotifier {
  @override
  Future<List<CategoryDto>> build() async => const [];
}

class _PerfSpeechService implements SpeechDictationService {
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

class _PerfAiRepository extends AiRepository {
  _PerfAiRepository()
      : super(dio: Dio(), sseDio: Dio(), eventBus: GlobalEventBus());

  @override
  Future<AiStatusDto> getStatus({bool fresh = false}) async {
    return const AiStatusDto(
      health: AiHealthDto(
        enabled: true,
        ollamaReachable: true,
        chatModel: 'gemma4:e4b',
        chatModelReady: true,
        chatModelLoaded: true,
        embedModel: 'embeddinggemma-2:270m',
        embedModelReady: true,
        busy: false,
        latencyMs: 28,
      ),
      indexedChunks: 24,
      approvedMemories: 3,
      quota: AiTokenUsageDto(
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: 0,
        monthlyTokensUsed: 500,
        monthlyTokensLimit: 10000,
        monthlyTokensRemaining: 9500,
        monthlyQueriesUsed: 2,
        monthlyQueriesLimit: 50,
        monthlyQueriesRemaining: 48,
        planSlug: 'plus',
        planName: 'Plus',
      ),
    );
  }

  @override
  Future<List<AiConversationSummaryDto>> listConversations() async => const [];

  @override
  Future<List<BusinessMemoryDto>> listMemory({String status = 'ALL'}) async =>
      const [];

  @override
  Future<AiConversationDetailDto> getConversation(String id) async {
    if (id == 'conv-120') {
      final msgs = List<AiMessageDto>.generate(120, (i) {
        final isUser = i.isEven;
        return AiMessageDto(
          id: 'msg-$i',
          role: isUser ? 'user' : 'assistant',
          content: isUser
              ? 'Check Q4 invoice balance for client #$i'
              : 'Summary for item #$i: Revenue is **1,250.000 TND** with healthy operating margin.',
          createdAt: DateTime(2026, 11, 27, 10, 0).add(Duration(minutes: i)),
        );
      });
      return AiConversationDetailDto(
        id: 'conv-120',
        title: '120-Message Stress Thread',
        locale: 'en',
        activeLanguage: 'EN',
        messages: msgs,
      );
    }
    return const AiConversationDetailDto(
      id: 'conv-empty',
      title: 'Empty',
      locale: 'en',
    );
  }

  @override
  Stream<SseEvent> streamChat({
    required String message,
    String? conversationId,
    required String locale,
    AiReasoningMode reasoningMode = AiReasoningMode.fast,
    List<String> attachmentIds = const [],
    Map<String, String>? screenContext,
    CancelToken? cancelToken,
  }) async* {}
}

Widget _buildShellApp({
  required SharedPreferences prefs,
  required _PerfAiRepository aiRepo,
  required GoRouter router,
  Brightness brightness = Brightness.dark,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(_PerfAuthNotifier.new),
      businessListProvider.overrideWith(
        (_) async => const [
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
      notificationsProvider.overrideWith(_PerfNotificationsNotifier.new),
      aiRepositoryProvider.overrideWithValue(aiRepo),
      aiHealthProvider.overrideWith(_PerfHealthNotifier.new),
      speechDictationServiceProvider.overrideWithValue(_PerfSpeechService()),
      aiPulseProvider.overrideWith(
        (_) async => AiPulseDto(
          currency: 'TND',
          monthNetProfit: Decimal.parse('1250.500'),
          overdueCount: 0,
          highCount: 0,
          alerts: const [],
        ),
      ),
      categoryListProvider.overrideWith(_PerfCategoriesNotifier.new),
      aiCustomersDropdownProvider.overrideWith((_) async => const <CustomerDto>[]),
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
        brightness: brightness,
        locale: const Locale('en'),
      ),
    ),
  );
}

GoRouter _buildShellRouter({String initialLocation = '/copilot'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AdaptiveShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('Home Tab')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('Finance Tab')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/copilot',
                builder: (_, _) => const AiCopilotScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('Invoices Tab')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) => const Scaffold(
                  body: Center(child: Text('More Tab')),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<void> _pumpFrames(
  WidgetTester tester, {
  int count = 8,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(step);
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AFAB Mobile Performance Benchmark & Regression Suite', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
      '1. Copilot typing (25 keystrokes) triggers zero Aurora/NavDock rebuilds and stays fast',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = _buildShellRouter(initialLocation: '/copilot');
        addTearDown(router.dispose);

        await tester.pumpWidget(
          _buildShellApp(
            prefs: prefs,
            aiRepo: _PerfAiRepository(),
            router: router,
          ),
        );
        await _pumpFrames(tester);

        var auroraRebuilds = 0;
        var dockRebuilds = 0;
        final prevCallback = debugOnRebuildDirtyWidget;
        debugOnRebuildDirtyWidget = (element, builtOnce) {
          final w = element.widget;
          if (w is CopilotAuroraBackdrop) auroraRebuilds++;
          if (w is AfabFloatingNavDock) dockRebuilds++;
        };

        final sw = Stopwatch()..start();
        try {
          const sampleText = 'Summarize Q4 profit trend';
          final fieldFinder = find.byType(TextField).first;
          for (var i = 1; i <= sampleText.length; i++) {
            await tester.enterText(fieldFinder, sampleText.substring(0, i));
            await tester.pump(const Duration(milliseconds: 16));
          }
        } finally {
          sw.stop();
          debugOnRebuildDirtyWidget = prevCallback;
        }

        final avgMs = sw.elapsedMicroseconds / (1000.0 * 25);
        debugPrint(
          '[PERF] Typing 25 keystrokes: avg=${avgMs.toStringAsFixed(2)}ms/key, auroraRebuilds=$auroraRebuilds, dockRebuilds=$dockRebuilds',
        );

        expect(auroraRebuilds, 0);
        expect(dockRebuilds, 0);
        expect(avgMs, lessThan(50.0));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Aurora fog animation maintains ~30fps paint pacing and 0 widget rebuilds across 120 frames (Dark & Light)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Part A: Measure paint pacing directly across 120 × 16.667ms frames (2.0s)
        for (final brightness in [Brightness.dark, Brightness.light]) {
          var paintCalls = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppearanceThemeBuilder.build(
                settings: const AppearanceSettings(),
                brightness: brightness,
                locale: const Locale('en'),
              ),
              home: Scaffold(
                body: SizedBox.expand(
                  child: CopilotAuroraBackdrop(
                    sending: false,
                    activeMode: true,
                    onPaint: () => paintCalls++,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          paintCalls = 0;

          final sw = Stopwatch()..start();
          for (var i = 0; i < 120; i++) {
            await tester.pump(const Duration(microseconds: 16667));
          }
          sw.stop();

          final avgFrameMs = sw.elapsedMicroseconds / (1000.0 * 120);
          debugPrint(
            '[PERF] Aurora 120 frames (${brightness.name}): paints=$paintCalls/120, avgFramePump=${avgFrameMs.toStringAsFixed(2)}ms',
          );

          expect(paintCalls, lessThanOrEqualTo(68));
          expect(paintCalls, greaterThanOrEqualTo(45));
          expect(avgFrameMs, lessThan(16.0));
        }

        // Part B: Verify 0 widget rebuilds inside full AdaptiveShell + AiCopilotScreen over 120 frames
        final router = _buildShellRouter(initialLocation: '/copilot');
        addTearDown(router.dispose);
        await tester.pumpWidget(
          _buildShellApp(
            prefs: prefs,
            aiRepo: _PerfAiRepository(),
            router: router,
          ),
        );
        await _pumpFrames(tester);

        var dirtyWidgetRebuilds = 0;
        final prevCallback = debugOnRebuildDirtyWidget;
        debugOnRebuildDirtyWidget = (_, _) => dirtyWidgetRebuilds++;
        try {
          for (var i = 0; i < 120; i++) {
            await tester.pump(const Duration(microseconds: 16667));
          }
        } finally {
          debugOnRebuildDirtyWidget = prevCallback;
        }

        debugPrint(
          '[PERF] Idle Copilot 120-frame run: dirtyWidgetRebuilds=$dirtyWidgetRebuilds',
        );
        expect(dirtyWidgetRebuilds, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. ThinkingCard 200ms timer isolates header ticks from streaming Markdown (0 Markdown rebuilds over 2.0s)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
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
            home: const Scaffold(
              body: CopilotThinkingCard(
                streamPhase: 'streaming',
                streamingText: '### Revenue Summary\n\n- Operating margin: **42%**',
                thinkingText: 'Auditing ledger',
                activeTools: [],
                completedTools: [],
              ),
            ),
          ),
        );
        await tester.pump();

        var markdownRebuilds = 0;
        var cardRebuilds = 0;
        final prevCallback = debugOnRebuildDirtyWidget;
        debugOnRebuildDirtyWidget = (element, _) {
          if (element.widget is CopilotMarkdown) markdownRebuilds++;
          if (element.widget is CopilotThinkingCard) cardRebuilds++;
        };

        try {
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
        } finally {
          debugOnRebuildDirtyWidget = prevCallback;
        }

        debugPrint(
          '[PERF] ThinkingCard 10 timer ticks (2.0s): markdownRebuilds=$markdownRebuilds, cardRebuilds=$cardRebuilds',
        );
        expect(find.textContaining('2.0s'), findsOneWidget);
        expect(markdownRebuilds, 0);
        expect(cardRebuilds, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '4. 120-message conversation renders lazily (<= 20 mounted bubbles) and flings without exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              authNotifierProvider.overrideWith(_PerfAuthNotifier.new),
              businessListProvider.overrideWith(
                (_) async => const [
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
              aiRepositoryProvider.overrideWithValue(_PerfAiRepository()),
              aiHealthProvider.overrideWith(_PerfHealthNotifier.new),
              speechDictationServiceProvider.overrideWithValue(
                _PerfSpeechService(),
              ),
              aiPulseProvider.overrideWith(
                (_) async => const AiPulseDto(currency: 'TND', alerts: []),
              ),
              categoryListProvider.overrideWith(_PerfCategoriesNotifier.new),
              aiCustomersDropdownProvider.overrideWith(
                (_) async => const <CustomerDto>[],
              ),
            ],
            child: MaterialApp(
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
              home: const AiCopilotScreen(initialConversationId: 'conv-120'),
            ),
          ),
        );
        await _pumpFrames(tester, count: 10);

        final initialMounted =
            find.byType(CopilotMessageBubble).evaluate().length;
        expect(initialMounted, greaterThan(0));
        expect(initialMounted, lessThanOrEqualTo(20));

        final listFinder = find.byType(ListView).first;
        final sw = Stopwatch()..start();
        for (var i = 0; i < 3; i++) {
          await tester.fling(listFinder, const Offset(0, 900), 2200);
          await _pumpFrames(tester, count: 8, step: const Duration(milliseconds: 30));
          await tester.fling(listFinder, const Offset(0, -900), 2200);
          await _pumpFrames(tester, count: 8, step: const Duration(milliseconds: 30));
        }
        sw.stop();

        final afterFlingMounted =
            find.byType(CopilotMessageBubble).evaluate().length;
        debugPrint(
          '[PERF] 120-message thread: mounted=$initialMounted->$afterFlingMounted/120, 6 flings elapsed=${sw.elapsedMilliseconds}ms',
        );

        expect(afterFlingMounted, lessThanOrEqualTo(20));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. Zero BackdropFilter, bounded Image cacheWidth, 5x keyboard toggles & 5-tab switch stress',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 2.0;
        tester.view.viewInsets = FakeViewPadding.zero;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        // Verify AfabBrandLogo decodes bounded cacheWidth for small sizes
        await tester.pumpWidget(
          MaterialApp(
            theme: AppearanceThemeBuilder.build(
              settings: const AppearanceSettings(),
              brightness: Brightness.dark,
              locale: const Locale('en'),
            ),
            home: const Scaffold(
              body: Center(
                child: AfabBrandLogo(size: 22, showGlowRing: false),
              ),
            ),
          ),
        );
        await tester.pump();
        final logoImage = tester.widget<Image>(find.byType(Image).first);
        expect(logoImage.image, isA<ResizeImage>());
        final resizedLogo = logoImage.image as ResizeImage;
        expect(resizedLogo.width, isNotNull);
        expect(resizedLogo.width!, lessThanOrEqualTo(128));

        // Mount full 5-tab AdaptiveShell with AfabFloatingNavDock
        tester.view.devicePixelRatio = 1.0;
        final router = _buildShellRouter(initialLocation: '/dashboard');
        addTearDown(router.dispose);

        await tester.pumpWidget(
          _buildShellApp(
            prefs: prefs,
            aiRepo: _PerfAiRepository(),
            router: router,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.byType(AfabFloatingNavDock), findsOneWidget);

        // Rapidly cycle all 5 tabs: Home -> Finance -> Copilot -> Invoices -> More -> Home
        final tabSw = Stopwatch()..start();
        for (final label in ['Finance', 'Copilot', 'Invoices', 'More', 'Home']) {
          await tester.tap(
            find.descendant(
              of: find.byType(AfabFloatingNavDock),
              matching: find.text(label),
            ),
          );
          await _pumpFrames(tester, count: 4, step: const Duration(milliseconds: 50));
        }
        tabSw.stop();

        // Jump to Copilot and stress-toggle keyboard 5 times
        await tester.tap(
          find.descendant(
            of: find.byType(AfabFloatingNavDock),
            matching: find.text('Copilot'),
          ),
        );
        await _pumpFrames(tester);

        final imeSw = Stopwatch()..start();
        for (var i = 0; i < 5; i++) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pump();
          tester.view.viewInsets = FakeViewPadding.zero;
          await tester.pump(const Duration(milliseconds: 200));
        }
        imeSw.stop();

        debugPrint(
          '[PERF] logoCacheWidth=${resizedLogo.width}px, 5-tab cycle=${tabSw.elapsedMilliseconds}ms, 5x IME toggle=${imeSw.elapsedMilliseconds}ms',
        );

        expect(find.byType(BackdropFilter), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
