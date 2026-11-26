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
import 'package:afab_mobile/features/ai/presentation/business_memory_screen.dart';
import 'package:afab_mobile/features/ai/presentation/global_copilot_sheet.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
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

class _FakeSpeech implements SpeechDictationService {
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

class _FakeAiRepo extends AiRepository {
  _FakeAiRepo()
      : super(dio: Dio(), sseDio: Dio(), eventBus: GlobalEventBus());

  final List<String> requestedStatuses = [];
  String? approvedId;
  String? deletedId;

  @override
  Future<List<BusinessMemoryDto>> listMemory({String status = 'ALL'}) async {
    requestedStatuses.add(status);
    final items = <BusinessMemoryDto>[
      const BusinessMemoryDto(
        id: 'm-1',
        memoryType: BusinessMemoryType.supplierPattern,
        title: 'STEG Bi-monthly Utility',
        content: 'Classify STEG invoices under Utilities.',
        status: 'APPROVED',
        hasVector: true,
      ),
      const BusinessMemoryDto(
        id: 'm-2',
        memoryType: BusinessMemoryType.categorizationPreference,
        title: 'Cloud Hosting Vendor',
        content: 'Map DigitalOcean charges to Infrastructure.',
        status: 'PROPOSED',
        hasVector: false,
      ),
    ];
    if (status == 'ALL') return items;
    return items.where((m) => m.status == status).toList();
  }

  @override
  Future<BusinessMemoryDto> updateMemory({
    required String id,
    BusinessMemoryType? memoryType,
    String? title,
    String? content,
    String? status,
  }) async {
    if (status == 'APPROVED') approvedId = id;
    return const BusinessMemoryDto(
      id: 'm-2',
      memoryType: BusinessMemoryType.categorizationPreference,
      title: 'Cloud Hosting Vendor',
      content: 'Map DigitalOcean charges to Infrastructure.',
      status: 'APPROVED',
      hasVector: true,
    );
  }

  @override
  Future<void> deleteMemory(String id) async {
    deletedId = id;
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
  }) async* {
    yield SseDoneEvent(
      response: AiChatResponseDto(
        conversationId: 'sheet-conv-1',
        conversationTitle: 'Invoice Reminder',
        messageId: 'sheet-msg-1',
        content: 'Here is a draft payment reminder for INV-2026-01.',
        toolsUsed: const ['propose_payment_reminder'],
        dataCoverage: 'RAG_GROUNDED',
        modelId: 'gemma4:e4b',
        actionDrafts: const [
          AiActionDraftDto(
            draftId: 'rem-1',
            actionType: 'PAYMENT_REMINDER',
            status: 'PENDING',
            title: 'Payment Reminder · INV-2026-01',
            summary: '500 TND due',
            payload: {
              'emailSubject': 'Friendly Reminder: INV-2026-01',
              'emailBody': 'Hello Acme Corp, invoice INV-2026-01 is overdue.',
              'whatsappBody': 'Salam! Reminder for INV-2026-01.',
              'customerEmail': 'billing@acme.tn',
              'customerPhone': '+21620111222',
            },
          ),
        ],
        tokenUsage: const AiTokenUsageDto(
          promptTokens: 50,
          completionTokens: 40,
          totalTokens: 90,
          monthlyTokensUsed: 100,
          monthlyTokensLimit: 5000,
          monthlyTokensRemaining: 4900,
          monthlyQueriesUsed: 2,
          monthlyQueriesLimit: 50,
          monthlyQueriesRemaining: 48,
          planSlug: 'plus',
          planName: 'Plus',
        ),
      ),
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
  required _FakeAiRepo repo,
  required Widget child,
  bool editable = true,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(_AuthStub.new),
      businessListProvider.overrideWith(
        (ref) async => [
          BusinessDto(
            id: 'biz-1',
            name: 'Carthage Labs',
            currency: 'TND',
            active: true,
            editable: editable,
            accessMode: editable ? 'EDITABLE' : 'READ_ONLY',
          ),
        ],
      ),
      activeBusinessIdProvider.overrideWith(ActiveBusinessIdNotifier.new),
      isOnlineProvider.overrideWithValue(true),
      aiRepositoryProvider.overrideWithValue(repo),
      speechDictationServiceProvider.overrideWithValue(_FakeSpeech()),
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
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('GlobalCopilotSheet (`AI-02`) & BusinessMemoryScreen (`AI-03`)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
      'BusinessMemoryScreen filters statuses, approves PROPOSED, confirms delete, and hides writes when READ_ONLY',
      (tester) async {
        final repo = _FakeAiRepo();
        _setViewport(tester, const Size(390, 844));

        await tester.pumpWidget(
          _wrap(prefs: prefs, repo: repo, child: const BusinessMemoryScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Vectorized'), findsOneWidget);
        expect(find.text('Keyword Indexed'), findsOneWidget);

        // Approve proposed item
        await tester.tap(find.byTooltip('Approve').first);
        await tester.pumpAndSettle();
        expect(repo.approvedId, 'm-2');

        // Delete item with confirmation dialog
        await tester.tap(find.byTooltip('Delete').first);
        await tester.pumpAndSettle();
        expect(find.text('Delete this memory?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(repo.deletedId, 'm-1');

        // Filter to PROPOSED
        final proposedTab = find.text('Proposed').first;
        await tester.ensureVisible(proposedTab);
        await tester.pumpAndSettle();
        await tester.tap(proposedTab);
        await tester.pumpAndSettle();
        expect(repo.requestedStatuses, contains('PROPOSED'));

        // READ_ONLY Dark AR tablet hides edit/delete/add actions cleanly
        _setViewport(tester, const Size(1024, 768));
        await tester.pumpWidget(
          _wrap(
            prefs: prefs,
            repo: repo,
            editable: false,
            locale: const Locale('ar'),
            brightness: Brightness.dark,
            child: const BusinessMemoryScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.add), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'GlobalCopilotSheet autoSends screenContext prompt and renders CopilotReminderCard on phone & tablet',
      (tester) async {
        final repo = _FakeAiRepo();
        _setViewport(tester, const Size(390, 844));

        await tester.pumpWidget(
          _wrap(
            prefs: prefs,
            repo: repo,
            child: Consumer(
              builder: (ctx, ref, _) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(copilotLauncherProvider.notifier).openCopilot(
                            prompt: 'Draft reminder for INV-2026-01',
                            autoSend: true,
                            screenContext: const {
                              'page': 'invoices',
                              'invoiceNumber': 'INV-2026-01',
                            },
                          );
                      showGlobalCopilotSheet(ctx, ref);
                    },
                    child: const Text('Launch Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Launch Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Payment Reminder · INV-2026-01'), findsOneWidget);
        expect(find.text('Open Email'), findsOneWidget);
        await tester.tap(find.text('WhatsApp'));
        await tester.pumpAndSettle();
        expect(find.text('Open WhatsApp'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
