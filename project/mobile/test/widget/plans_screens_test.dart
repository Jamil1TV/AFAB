import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/connectivity_provider.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:afab_mobile/features/plans/data/plans_repository.dart';
import 'package:afab_mobile/features/plans/presentation/plans_and_subscription_screen.dart';
import 'package:afab_mobile/features/plans/presentation/widgets/business_allocation_sheet.dart';
import 'package:afab_mobile/features/plans/presentation/widgets/cancel_subscription_sheet.dart';
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
          businessId: 'b-1',
          businessName: 'Carthage Labs',
          currency: 'EUR',
          planTier: 'PLUS',
        ),
      );

  @override
  Future<void> refreshProfile() async {}
}

class _FakeUrlLauncher implements BillingUrlLauncher {
  Uri? lastLaunched;

  @override
  Future<bool> launchExternal(Uri uri) async {
    lastLaunched = uri;
    return true;
  }
}

class _FakePlansRepo extends PlansRepository {
  _FakePlansRepo(this.snapshot) : super(Dio());

  SubscriptionSnapshotDto snapshot;
  bool verifyCalled = false;
  bool directUpgradeCalled = false;
  bool resumeCalled = false;
  List<String>? canceledIds;
  List<String>? downgradedIds;

  @override
  Future<SubscriptionSnapshotDto> verifyCheckout(String sessionId) async {
    verifyCalled = true;
    return snapshot;
  }

  @override
  Future<UpgradeSubscriptionResponseDto> upgradeSubscription({
    required String planSlug,
    required String billingInterval,
    required String locale,
    String returnPath = PlansRepository.defaultReturnPath,
  }) async {
    directUpgradeCalled = true;
    return UpgradeSubscriptionResponseDto(
      mode: 'DIRECT_UPGRADE',
      snapshotJson: {'planSlug': 'pro', 'planName': 'Pro'},
    );
  }

  @override
  Future<SubscriptionSnapshotDto> resumeSubscription() async {
    resumeCalled = true;
    return snapshot;
  }

  @override
  Future<SubscriptionSnapshotDto> cancelSubscription({
    List<String>? selectedBusinessIds,
  }) async {
    canceledIds = selectedBusinessIds;
    return snapshot;
  }

  @override
  Future<SubscriptionSnapshotDto> scheduleDowngrade({
    required String targetPlanSlug,
    String? billingInterval,
    List<String>? selectedBusinessIds,
    bool deferAllocation = false,
  }) async {
    downgradedIds = selectedBusinessIds;
    return snapshot;
  }

  @override
  Future<BillingHistoryResponseDto> getBillingHistory() async {
    return BillingHistoryResponseDto(
      paymentHistory: [
        PaymentHistoryItemDto(
          id: 'pay-1',
          amountCents: 1500,
          currency: 'JPY',
          status: 'PAID',
          paidAt: DateTime(2026, 11, 1),
          hostedInvoiceUrl: 'https://invoice.stripe.com/i/test1',
        ),
        PaymentHistoryItemDto(
          id: 'pay-2',
          amountCents: 1999,
          currency: 'EUR',
          status: 'PAID',
          paidAt: DateTime(2026, 11, 2),
        ),
      ],
      subscriptionHistory: [
        SubscriptionHistoryItemDto(
          id: 'sh-1',
          eventType: 'TRIAL_STARTED',
          details: '7-day Plus trial activated',
          createdAt: DateTime(2026, 11, 1),
        ),
      ],
    );
  }
}

class _FakeBizRepo extends BusinessRepository {
  _FakeBizRepo(this.allocDto) : super(Dio());

  final BusinessAllocationDto allocDto;
  List<String>? updatedAllocIds;
  List<String>? pendingAllocIds;

  @override
  Future<List<BusinessDto>> listBusinesses() async => [
        for (final b in allocDto.businesses)
          BusinessDto(
            id: b.id,
            name: b.name,
            currency: b.currency,
            editable: b.editable,
            primary: b.primary,
            active: b.active,
          ),
      ];

  @override
  Future<BusinessAllocationDto> getAllocations() async => allocDto;

  @override
  Future<BusinessAllocationDto> updateAllocations({
    required List<String> selectedBusinessIds,
    String? primaryBusinessId,
  }) async {
    updatedAllocIds = selectedBusinessIds;
    return allocDto;
  }

  @override
  Future<BusinessAllocationDto> savePendingAllocations({
    required String targetPlanSlug,
    required List<String> selectedBusinessIds,
  }) async {
    pendingAllocIds = selectedBusinessIds;
    return allocDto;
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

List<BusinessAllocationItemDto> _fiveOwned() => List.generate(
      5,
      (i) => BusinessAllocationItemDto(
        id: 'b-${i + 1}',
        name: 'Workspace ${i + 1}',
        currency: 'EUR',
        industry: 'Technology',
        editable: i < 4,
        primary: i == 0,
        active: i == 0,
      ),
    );

Widget _wrap({
  required SharedPreferences prefs,
  required _FakePlansRepo plansRepo,
  required _FakeBizRepo bizRepo,
  required SubscriptionSnapshotDto snapshot,
  required _FakeUrlLauncher launcher,
  required Widget home,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(_AuthStub.new),
      isOnlineProvider.overrideWithValue(true),
      plansRepositoryProvider.overrideWithValue(plansRepo),
      businessRepositoryProvider.overrideWithValue(bizRepo),
      billingUrlLauncherProvider.overrideWithValue(launcher),
      subscriptionSnapshotProvider.overrideWith((_) async => snapshot),
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
      home: home,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 6 Plans & Billing widget tests (`PLAN-01` & `PLAN-02`)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
      'PlansAndSubscriptionScreen renders features checklists, EUR/JPY formatting, PAST_DUE + Pending banners, Direct Upgrade, and Dark AR tablet cleanly',
      (tester) async {
        final owned = _fiveOwned();
        final alloc = BusinessAllocationDto(
          currentPlanSlug: 'free',
          currentPlanName: 'Free',
          editableLimit: 1,
          editableCount: 1,
          readOnlyCount: 4,
          totalOwnedCount: 5,
          allocationAttentionRequired: false,
          pendingPlanSlug: 'free',
          pendingPlanName: 'Free',
          pendingEditableLimit: 1,
          pendingBusinessIds: const ['b-2'],
          businesses: owned,
        );
        final snap = SubscriptionSnapshotDto(
          planSlug: 'free',
          planName: 'Free',
          currency: 'EUR',
          status: 'PAST_DUE',
          isTrial: false,
          gracePeriodHoursRemaining: 36,
          trialEligible: true,
          allocationAttentionRequired: false,
          editableBusinessLimit: 1,
          editableBusinessCount: 1,
          totalBusinessCount: 5,
          hasStripeCustomer: true,
          hasActiveStripeSubscription: false,
          stripeConfigured: true,
          entitlements: const {
            'ai.chat.tokens_per_month': 10000,
            'ai.chat.queries_per_month': 20,
          },
          usage: const {
            'ai.chat.tokens_per_month': 4000,
            'ai.chat.queries_per_month': 5,
          },
        );
        final plansRepo = _FakePlansRepo(snap);
        final bizRepo = _FakeBizRepo(alloc);
        final launcher = _FakeUrlLauncher();

        _setViewport(tester, const Size(390, 844));
        await tester.pumpWidget(
          _wrap(
            prefs: prefs,
            plansRepo: plansRepo,
            bizRepo: bizRepo,
            snapshot: snap,
            launcher: launcher,
            home: const PlansAndSubscriptionScreen(
              checkoutStatus: 'success',
              sessionId: 'cs_test_1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(plansRepo.verifyCalled, isTrue);
        // Feature checklists inside plan cards
        expect(find.text("What's included:"), findsOneWidget);
        expect(find.text('Everything in Free, plus:'), findsOneWidget);
        expect(find.text('Everything in Plus, plus:'), findsOneWidget);
        // Grace period banner
        expect(
          find.textContaining('3-Day Grace Period (36h remaining)'),
          findsOneWidget,
        );
        // Payment history formats per-row currencies cleanly
        expect(find.textContaining('1,500'), findsOneWidget);
        expect(find.textContaining('19.99'), findsWidgets);
        expect(tester.takeException(), isNull);

        // Tablet 1024x768 Dark AR RTL + Plus DIRECT_UPGRADE
        final plusSnap = SubscriptionSnapshotDto(
          planSlug: 'plus',
          planName: 'Plus',
          currency: 'EUR',
          status: 'ACTIVE',
          isTrial: false,
          pendingPlanSlug: 'free',
          pendingPlanName: 'Free',
          allocationAttentionRequired: false,
          editableBusinessLimit: 3,
          editableBusinessCount: 3,
          totalBusinessCount: 5,
          hasStripeCustomer: true,
          hasActiveStripeSubscription: true,
          stripeConfigured: true,
        );
        _setViewport(tester, const Size(1024, 768));
        await tester.pumpWidget(
          _wrap(
            prefs: prefs,
            plansRepo: plansRepo,
            bizRepo: bizRepo,
            snapshot: plusSnap,
            launcher: launcher,
            locale: const Locale('ar'),
            brightness: Brightness.dark,
            home: const PlansAndSubscriptionScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final upgradeBtn = find.text('الترقية إلى Pro');
        await tester.ensureVisible(upgradeBtn);
        await tester.pumpAndSettle();
        await tester.tap(upgradeBtn);
        await tester.pumpAndSettle();
        expect(plansRepo.directUpgradeCalled, isTrue);
      },
    );

    testWidgets(
      'BusinessAllocationSheet enforces 3-of-5 DOWNGRADE cap and CancelSubscriptionSheet enforces 1-of-N selector',
      (tester) async {
        final owned = _fiveOwned();
        final alloc = BusinessAllocationDto(
          currentPlanSlug: 'pro',
          currentPlanName: 'Pro',
          editableLimit: 5,
          editableCount: 4,
          readOnlyCount: 1,
          totalOwnedCount: 5,
          allocationAttentionRequired: false,
          businesses: owned,
        );
        const snap = SubscriptionSnapshotDto(
          planSlug: 'plus',
          planName: 'Plus',
          status: 'TRIALING',
          isTrial: true,
          trialDaysRemaining: 6,
          allocationAttentionRequired: false,
          editableBusinessLimit: 3,
          editableBusinessCount: 3,
          totalBusinessCount: 5,
          hasActiveStripeSubscription: true,
        );
        final plansRepo = _FakePlansRepo(snap);
        final bizRepo = _FakeBizRepo(alloc);
        final launcher = _FakeUrlLauncher();

        _setViewport(tester, const Size(390, 844));
        await tester.pumpWidget(
          _wrap(
            prefs: prefs,
            plansRepo: plansRepo,
            bizRepo: bizRepo,
            snapshot: snap,
            launcher: launcher,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => showBusinessAllocationSheet(
                        ctx,
                        mode: BusinessAllocationMode.downgrade,
                        businesses: owned,
                        maxAllowed: 3,
                        targetPlanSlug: 'plus',
                        targetPlanName: 'Plus',
                      ),
                      child: const Text('Open Downgrade Sheet'),
                    ),
                    ElevatedButton(
                      onPressed: () => showCancelSubscriptionSheet(
                        ctx,
                        snapshot: snap,
                        businesses: owned,
                      ),
                      child: const Text('Open Cancel Sheet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Test Downgrade 3-of-5 cap
        await tester.tap(find.text('Open Downgrade Sheet'));
        await tester.pumpAndSettle();
        expect(find.text('Selected 3 / 3'), findsOneWidget);
        // Workspace 5 is unchecked & dimmed because cap is reached; tapping does not add 4th
        final ws5 = find.text('Workspace 5');
        await tester.scrollUntilVisible(
          ws5,
          120,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .last,
        );
        await tester.pumpAndSettle();
        await tester.tap(ws5);
        await tester.pumpAndSettle();
        expect(find.text('Selected 3 / 3'), findsOneWidget);

        await tester.tap(find.text('Confirm Downgrade to Plus'));
        await tester.pumpAndSettle();
        expect(plansRepo.downgradedIds, hasLength(3));

        // Test Cancel trial sheet
        await tester.tap(find.text('Open Cancel Sheet'));
        await tester.pumpAndSettle();
        expect(
          find.text('No payment will be collected when your trial ends.'),
          findsOneWidget,
        );
        final confirmCancelBtn = find.text('Confirm Cancellation');
        await tester.ensureVisible(confirmCancelBtn);
        await tester.pumpAndSettle();
        await tester.tap(confirmCancelBtn);
        await tester.pumpAndSettle();
        expect(plansRepo.canceledIds, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
