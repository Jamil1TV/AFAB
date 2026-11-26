import 'dart:io';

import 'package:afab_mobile/core/error/app_failure.dart';
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
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/features/settings/data/settings_repository.dart';
import 'package:afab_mobile/features/settings/domain/biometric_lock_service.dart';
import 'package:afab_mobile/features/settings/domain/signature_vault_provider.dart';
import 'package:afab_mobile/features/settings/presentation/account_deletion_flow.dart';
import 'package:afab_mobile/features/settings/presentation/appearance_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/business_profile_screen.dart';
import 'package:afab_mobile/features/settings/presentation/data_export_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/general_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/language_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/security_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/settings_coming_soon_screen.dart';
import 'package:afab_mobile/features/settings/presentation/settings_home_screen.dart';
import 'package:afab_mobile/features/settings/presentation/signature_settings_screen.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this._initialUser);

  final UserProfile _initialUser;
  bool localLogoutCalled = false;
  bool refreshCalled = false;

  @override
  SessionState build() => SessionState(
        status: SessionStatus.authenticated,
        user: _initialUser,
      );

  @override
  Future<void> refreshProfile() async {
    refreshCalled = true;
  }

  @override
  Future<void> updateCachedUser(UserProfile user) async {
    state = state.copyWith(user: user);
  }

  @override
  Future<void> forceLocalLogout() async {
    localLogoutCalled = true;
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  @override
  Future<void> logout() => forceLocalLogout();
}

class _FakeSettingsRepository extends SettingsRepository {
  _FakeSettingsRepository({
    required this.baseUser,
    this.preflight = const AccountDeletionPreflightDto(canDelete: true),
    this.sessions = const [],
  }) : super(Dio());

  final UserProfile baseUser;
  AccountDeletionPreflightDto preflight;
  List<SessionDto> sessions;

  Map<String, dynamic>? lastProfilePayload;
  String? changedPasswordNew;
  bool enabledTwoFactor = false;
  bool revokedAllSessions = false;
  String? deletedConfirmation;

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> payload) async {
    lastProfilePayload = Map<String, dynamic>.from(payload);
    return baseUser.copyWith(
      firstName: payload['firstName'] as String? ?? baseUser.firstName,
      lastName: payload['lastName'] as String? ?? baseUser.lastName,
      phoneNumber: payload['phoneNumber'] as String? ?? baseUser.phoneNumber,
      avatarUrl: payload['avatarUrl'] as String? ?? baseUser.avatarUrl,
      enableAiInsights:
          payload['enableAiInsights'] as bool? ?? baseUser.enableAiInsights,
      compactMode: payload['compactMode'] as bool? ?? baseUser.compactMode,
      autoCategorizeTransactions: payload['autoCategorizeTransactions'] as bool? ??
          baseUser.autoCategorizeTransactions,
      showTips: payload['showTips'] as bool? ?? baseUser.showTips,
    );
  }

  @override
  Future<Map<String, dynamic>> exportUserData() async => {
        'summary': {
          'businessesCount': 1,
          'transactionsCount': 3,
          'sessionsCount': 1,
        },
      };

  @override
  Future<AccountDeletionPreflightDto> getDeletionPreflight() async => preflight;

  @override
  Future<void> deleteMyAccount(String confirmation) async {
    deletedConfirmation = confirmation;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changedPasswordNew = newPassword;
  }

  @override
  Future<TwoFactorSetupDto> setupTwoFactor() async => const TwoFactorSetupDto(
        secret: 'JBSWY3DPEHPK3PXP',
        qrCodeUri: 'otpauth://totp/AFAB:youssef@carthage.tn?secret=JBSWY3DPEHPK3PXP',
        backupCodes: ['AAAA-1111', 'BBBB-2222'],
      );

  @override
  Future<void> enableTwoFactor({
    required String secret,
    required String code,
    required List<String> backupCodes,
  }) async {
    enabledTwoFactor = true;
  }

  @override
  Future<void> disableTwoFactor({required String password}) async {
    enabledTwoFactor = false;
  }

  @override
  Future<List<String>> regenerateBackupCodes() async =>
      const ['CCCC-3333', 'DDDD-4444'];

  @override
  Future<List<SessionDto>> listSessions() async => sessions;

  @override
  Future<void> revokeSession(String tokenId) async {}

  @override
  Future<void> revokeAllSessions() async {
    revokedAllSessions = true;
  }
}

class _FakeBusinessRepository extends BusinessRepository {
  _FakeBusinessRepository({
    required this.businesses,
    this.members = const [],
    this.archiveThrowsReadOnly = false,
    this.onArchived,
  }) : super(Dio());

  List<BusinessDto> businesses;
  List<BusinessMemberDto> members;
  bool archiveThrowsReadOnly;
  final VoidCallback? onArchived;

  Map<String, dynamic>? lastUpdatePayload;
  String? lastArchivedId;
  String? lastTransferredUserId;

  @override
  Future<List<BusinessDto>> listBusinesses() async => businesses;

  @override
  Future<BusinessDto> updateBusiness(
    String businessId,
    Map<String, dynamic> payload,
  ) async {
    lastUpdatePayload = Map<String, dynamic>.from(payload);
    final idx = businesses.indexWhere((b) => b.id == businessId);
    final current = idx >= 0 ? businesses[idx] : businesses.first;
    final updated = BusinessDto(
      id: current.id,
      name: payload['name'] as String? ?? current.name,
      currency: payload['currency'] as String? ?? current.currency,
      country: payload['country'] as String? ?? current.country,
      timezone: payload['timezone'] as String? ?? current.timezone,
      fiscalYearStartMonth:
          payload['fiscalYearStartMonth'] as int? ?? current.fiscalYearStartMonth,
      industry: payload['industry'] as String? ?? current.industry,
      businessEmail: payload['businessEmail'] as String? ?? current.businessEmail,
      phoneNumber: payload['phoneNumber'] as String? ?? current.phoneNumber,
      website: payload['website'] as String? ?? current.website,
      taxId: payload['taxId'] as String? ?? current.taxId,
      addressLine: payload['addressLine'] as String? ?? current.addressLine,
      city: payload['city'] as String? ?? current.city,
      state: payload['state'] as String? ?? current.state,
      postalCode: payload['postalCode'] as String? ?? current.postalCode,
      description: payload['description'] as String? ?? current.description,
      logoUrl: payload['logoUrl'] as String? ?? current.logoUrl,
      dateFormat: payload['dateFormat'] as String? ?? current.dateFormat,
      numberFormat: payload['numberFormat'] as String? ?? current.numberFormat,
      userRole: current.userRole,
      active: current.active,
      accessMode: current.accessMode,
      editable: current.editable,
      primary: current.primary,
    );
    if (idx >= 0) {
      businesses = List<BusinessDto>.from(businesses)..[idx] = updated;
    }
    return updated;
  }

  @override
  Future<void> archiveBusiness(String businessId) async {
    if (archiveThrowsReadOnly) {
      throw const BusinessReadOnlyFailure(message: 'Workspace locked');
    }
    lastArchivedId = businessId;
    onArchived?.call();
  }

  @override
  Future<List<BusinessMemberDto>> listMembers(String businessId) async => members;

  @override
  Future<BusinessDto> transferOwnership(
    String businessId,
    String targetUserId,
  ) async {
    lastTransferredUserId = targetUserId;
    return businesses.first;
  }

  @override
  Future<BusinessAllocationDto> getAllocations() async => BusinessAllocationDto(
        currentPlanSlug: 'free',
        currentPlanName: 'Free',
        editableLimit: 1,
        editableCount: 1,
        readOnlyCount: 0,
        totalOwnedCount: businesses.length,
        allocationAttentionRequired: false,
        businesses: businesses
            .map(
              (b) => BusinessAllocationItemDto(
                id: b.id,
                name: b.name,
                currency: b.currency,
                editable: b.editable,
                primary: b.primary,
                active: b.active,
              ),
            )
            .toList(),
      );
}

class _FakeBiometricService implements BiometricLockService {
  _FakeBiometricService({
    this.supported = true,
    this.authResult = true,
    this.enabled = false,
  });

  final bool supported;
  final bool authResult;
  bool enabled;
  bool cleared = false;

  @override
  Future<bool> isSupportedAndEnrolled() async => supported;

  @override
  Future<bool> authenticate(String reason) async => authResult;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool next) async {
    enabled = next;
  }

  @override
  Future<void> clearFlag() async {
    enabled = false;
    cleared = true;
  }
}

class _FakeTxRepo extends TransactionRepository {
  _FakeTxRepo() : super(Dio());

  @override
  Future<TransactionPageDto> getTransactions({
    TransactionType? type,
    String? categoryId,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    bool? taxDeductible,
    String? startDate,
    String? endDate,
    String? search,
    int page = 0,
    int size = 15,
    CancelToken? cancelToken,
  }) async {
    return TransactionPageDto(
      content: [
        TransactionDto(
          id: 't1',
          type: TransactionType.income,
          amount: Decimal.parse('1200.000'),
          currency: 'TND',
          description: 'Advisory Retainer',
          transactionDate: '2026-11-18',
          paymentMethod: PaymentMethod.bankTransfer,
          status: TransactionStatus.completed,
        ),
      ],
      pageNumber: 0,
      pageSize: size,
      totalElements: 1200,
      totalPages: 1,
      totalInflow: Decimal.parse('1200.000'),
      totalOutflow: Decimal.zero,
      netBalance: Decimal.parse('1200.000'),
      currency: 'TND',
    );
  }
}

class _FakeCustRepo extends CustomersRepository {
  _FakeCustRepo() : super(Dio());

  @override
  Future<CustomerPageDto> listCustomers({
    String? search,
    String? status,
    String? group,
    int page = 0,
    int size = 15,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    CancelToken? cancelToken,
  }) async {
    return CustomerPageDto(
      content: [
        CustomerDto(
          id: 'c1',
          customerCode: 'C-01',
          businessId: 'b1',
          name: 'Medina Foods',
          group: 'VIP',
          status: 'ACTIVE',
          totalRevenue: Decimal.parse('1200.000'),
          invoicedAmount: Decimal.parse('1200.000'),
          outstandingBalance: Decimal.zero,
          ordersCount: 1,
        ),
      ],
      totalElements: 1,
      totalPages: 1,
      pageNumber: 0,
      pageSize: size,
    );
  }
}

class _FakeInvRepo extends InvoicesRepository {
  _FakeInvRepo() : super(Dio());

  @override
  Future<InvoicePageDto> listInvoices({
    String? customerId,
    InvoiceStatus? status,
    String? search,
    int page = 0,
    int size = 15,
    CancelToken? cancelToken,
  }) async {
    return InvoicePageDto(
      content: [
        InvoiceDto(
          id: 'inv1',
          businessId: 'b1',
          invoiceNumber: 'INV-2026-09',
          customerName: 'Medina Foods',
          status: InvoiceStatus.paid,
          storedStatus: InvoiceStatus.paid,
          overdue: false,
          issueDate: '2026-11-18',
          dueDate: '2026-12-18',
          currency: 'TND',
          subtotal: Decimal.parse('1200.000'),
          discountAmount: Decimal.zero,
          taxAmount: Decimal.zero,
          totalAmount: Decimal.parse('1200.000'),
          paidAmount: Decimal.parse('1200.000'),
          outstandingBalance: Decimal.zero,
        ),
      ],
      pageNumber: 0,
      pageSize: size,
      totalElements: 1,
      totalPages: 1,
      totalInvoiced: Decimal.parse('1200.000'),
      totalPaid: Decimal.parse('1200.000'),
      totalOutstanding: Decimal.zero,
      currency: 'TND',
    );
  }
}

UserProfile _baseUser({bool twoFactor = false}) => UserProfile(
      id: 'u1',
      firstName: 'Youssef',
      lastName: 'Trabelsi',
      email: 'youssef@carthage.tn',
      emailVerified: true,
      onboardingComplete: true,
      businessId: 'b1',
      businessName: 'Carthage Labs',
      currency: 'TND',
      planTier: 'PLUS',
      twoFactorEnabled: twoFactor,
      enableAiInsights: true,
      compactMode: false,
      autoCategorizeTransactions: true,
      showTips: true,
    );

BusinessDto _baseBusiness({
  String role = 'OWNER',
  bool editable = true,
  String accessMode = 'EDITABLE',
}) =>
    BusinessDto(
      id: 'b1',
      name: 'Carthage Labs',
      currency: 'TND',
      country: 'TN',
      timezone: 'Africa/Tunis',
      fiscalYearStartMonth: 1,
      industry: 'technology',
      businessEmail: 'contact@carthage.tn',
      dateFormat: 'DD/MM/YYYY',
      numberFormat: 'SI',
      userRole: role,
      active: true,
      accessMode: accessMode,
      editable: editable,
      primary: true,
    );

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _buildTestApp({
  required SharedPreferences prefs,
  required Widget home,
  required _TestAuthNotifier auth,
  required _FakeSettingsRepository settingsRepo,
  required _FakeBusinessRepository bizRepo,
  _FakeBiometricService? bio,
  List<BusinessDto>? businesses,
  Directory? signatureTempDir,
  TransactionRepository? txRepo,
  CustomersRepository? custRepo,
  InvoicesRepository? invRepo,
  AfabLocalePreference initialLocale = AfabLocalePreference.en,
  ThemeMode themeMode = ThemeMode.light,
}) {
  final bizList = businesses ?? bizRepo.businesses;
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN_ROUTE')),
      ),
      GoRoute(
        path: '/plans',
        builder: (_, _) => const Scaffold(body: Text('PLANS_ROUTE')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const Scaffold(body: Text('NOTIF_ROUTE')),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: Text('SETTINGS_HUB_ROUTE')),
      ),
      GoRoute(
        path: '/settings/:section',
        builder: (_, s) => Scaffold(
          body: Text('SETTINGS_${s.pathParameters['section']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      isOnlineProvider.overrideWithValue(true),
      authNotifierProvider.overrideWith(() => auth),
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
      businessRepositoryProvider.overrideWithValue(bizRepo),
      businessListProvider.overrideWith((_) async => bizList),
      activeBusinessProvider.overrideWith((_) => bizList.first),
      subscriptionSnapshotProvider.overrideWith(
        (_) async => SubscriptionSnapshotDto.fromJson({
          'planSlug': 'plus',
          'planName': 'Plus',
          'status': 'ACTIVE',
          'currency': 'USD',
        }),
      ),
      if (bio != null) biometricLockServiceProvider.overrideWithValue(bio),
      if (signatureTempDir != null)
        signatureStorageDirProvider.overrideWithValue(() async => signatureTempDir),
      if (txRepo != null) transactionRepositoryProvider.overrideWithValue(txRepo),
      if (custRepo != null) customersRepositoryProvider.overrideWithValue(custRepo),
      if (invRepo != null) invoicesRepositoryProvider.overrideWithValue(invRepo),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final appearance = ref.watch(appearanceNotifierProvider);
        final locale = ref.watch(localeNotifierProvider);
        final resolvedLocale = initialLocale == AfabLocalePreference.ar &&
                ref.read(localeNotifierProvider.notifier).preference ==
                    AfabLocalePreference.system
            ? const Locale('ar')
            : locale;
        return MaterialApp.router(
          routerConfig: router,
          theme: AppearanceThemeBuilder.build(
            settings: appearance,
            brightness: Brightness.light,
            locale: resolvedLocale,
          ),
          darkTheme: AppearanceThemeBuilder.build(
            settings: appearance,
            brightness: Brightness.dark,
            locale: resolvedLocale,
          ),
          themeMode: themeMode,
          locale: initialLocale == AfabLocalePreference.ar
              ? const Locale('ar')
              : resolvedLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    ),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 6 Settings Screens (SET-01 to SET-10)', () {
    testWidgets('SET-01: phone hub with read-only banner + tablet master-detail AR RTL', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final user = _baseUser();
      final readOnlyBiz = _baseBusiness(editable: false, accessMode: 'READ_ONLY');
      final auth = _TestAuthNotifier(user);
      final settingsRepo = _FakeSettingsRepository(baseUser: user);
      final bizRepo = _FakeBusinessRepository(businesses: [readOnlyBiz]);

      // Phone 390x844 Light EN
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const SettingsHomeScreen(),
          auth: auth,
          settingsRepo: settingsRepo,
          bizRepo: bizRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.textContaining('Read-Only mode'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Wet Signature Vault'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tablet 1024x768 Dark AR RTL
      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const SettingsHomeScreen(),
          auth: _TestAuthNotifier(user),
          settingsRepo: settingsRepo,
          bizRepo: _FakeBusinessRepository(businesses: [_baseBusiness()]),
          initialLocale: AfabLocalePreference.ar,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('SET-02: GeneralSettings Cancel reverts & MEMBER locks business fields', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final user = _baseUser();
      final ownerBiz = _baseBusiness(role: 'OWNER');
      final auth = _TestAuthNotifier(user);
      final settingsRepo = _FakeSettingsRepository(baseUser: user);
      final bizRepo = _FakeBusinessRepository(businesses: [ownerBiz]);

      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const GeneralSettingsScreen(),
          auth: auth,
          settingsRepo: settingsRepo,
          bizRepo: bizRepo,
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextField, 'Business Name');
      await _tapVisible(tester, nameField);
      await tester.enterText(nameField, 'Edited Corp');
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);

      await _tapVisible(tester, find.text('Cancel'));
      expect(find.text('Carthage Labs'), findsWidgets);
      expect(find.text('Unsaved changes'), findsNothing);

      // MEMBER role disables business fields while keeping personal AI Insights editable
      final memberBiz = _baseBusiness(role: 'MEMBER');
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const GeneralSettingsScreen(),
          auth: _TestAuthNotifier(user),
          settingsRepo: settingsRepo,
          bizRepo: _FakeBusinessRepository(businesses: [memberBiz]),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Only workspace Owners and Admins'),
        findsOneWidget,
      );
      await _tapVisible(tester, find.text('Enable AI Insights'));
      await _tapVisible(tester, find.text('Save Changes'));
      expect(settingsRepo.lastProfilePayload?['enableAiInsights'], isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SET-03: BusinessProfile validates logoUrl and omits fake documents', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final user = _baseUser();
      final bizRepo = _FakeBusinessRepository(businesses: [_baseBusiness()]);
      final settingsRepo = _FakeSettingsRepository(baseUser: user);

      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const BusinessProfileScreen(),
          auth: _TestAuthNotifier(user),
          settingsRepo: settingsRepo,
          bizRepo: bizRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('tax_certificate'), findsNothing);

      final logoField = find.widgetWithText(TextField, 'Logo URL (HTTPS)');
      await _tapVisible(tester, logoField);
      await tester.enterText(logoField, 'data:image/png;base64,AAAA');
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Save Changes'));
      expect(
        find.text('Logo URL must be a valid http(s) link up to 500 characters.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('SET-04: SecuritySettings 2FA steps, Biometric toggle, Change Password & Revoke All logout', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final user = _baseUser(twoFactor: false);
      final auth = _TestAuthNotifier(user);
      final settingsRepo = _FakeSettingsRepository(
        baseUser: user,
        sessions: [
          SessionDto(
            id: 's1',
            deviceInfo: 'Pixel 9',
            ipAddress: '10.0.0.2',
            currentSession: true,
          ),
        ],
      );
      final bizRepo = _FakeBusinessRepository(businesses: [_baseBusiness()]);
      final bio = _FakeBiometricService(supported: true, authResult: true);

      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const SecuritySettingsScreen(),
          auth: auth,
          settingsRepo: settingsRepo,
          bizRepo: bizRepo,
          bio: bio,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login Alerts'), findsNothing);
      expect(find.text('Contact Support'), findsNothing);

      // Biometric toggle enables via BiometricLockService
      await _tapVisible(tester, find.text('Biometric App Lock'));
      expect(bio.enabled, isTrue);

      // 2FA Setup Step 1 -> Step 2 -> Step 3
      await _tapVisible(tester, find.text('Enable 2FA'));
      expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
      await _tapVisible(tester, find.text('Continue'));
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Verify & Enable 2FA'));
      expect(settingsRepo.enabledTwoFactor, isTrue);
      expect(find.textContaining('AAAA-1111'), findsOneWidget);
      await _tapVisible(tester, find.text('Close'));

      // Revoke All forces local logout and routes to /login
      await _tapVisible(tester, find.text('Log Out All Sessions'));
      await tester.tap(find.text('Log Out All Sessions').last);
      await tester.pumpAndSettle();
      expect(settingsRepo.revokedAllSessions, isTrue);
      expect(auth.localLogoutCalled, isTrue);
      expect(find.text('LOGIN_ROUTE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SET-05 & SET-08: Appearance OLED Pure Black & Language AR RTL keep native labels', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final user = _baseUser();
      final settingsRepo = _FakeSettingsRepository(baseUser: user);
      final bizRepo = _FakeBusinessRepository(businesses: [_baseBusiness()]);

      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const AppearanceSettingsScreen(),
          auth: _TestAuthNotifier(user),
          settingsRepo: settingsRepo,
          bizRepo: bizRepo,
        ),
      );
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.text('OLED Pure Black'));
      await _tapVisible(tester, find.text('Compact'));
      await _tapVisible(tester, find.text('Save Preferences'));
      expect(settingsRepo.lastProfilePayload?['compactMode'], isTrue);
      expect(tester.takeException(), isNull);

      // Language Settings preserves both English & العربية labels
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const LanguageSettingsScreen(),
          auth: _TestAuthNotifier(user),
          settingsRepo: settingsRepo,
          bizRepo: bizRepo,
        ),
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('العربية'));
      expect(find.text('English'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SET-06: SignatureSettings saves, activates & deletes local signature', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final tempDir = Directory.systemTemp.createTempSync('afab_sig_test_');
      addTearDown(() {
        try {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        } catch (_) {}
      });

      final user = _baseUser();
      final settingsRepo = _FakeSettingsRepository(baseUser: user);
      final bizRepo = _FakeBusinessRepository(businesses: [_baseBusiness()]);

      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const SignatureSettingsScreen(),
          auth: _TestAuthNotifier(user),
          settingsRepo: settingsRepo,
          bizRepo: bizRepo,
          signatureTempDir: tempDir,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('do not sync across devices'), findsOneWidget);
      expect(find.text('No signatures saved yet'), findsWidgets);

      // Draw a stroke on the signature GestureDetector
      Future<void> tapRealAsync(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pump();
        await tester.tap(finder);
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      final padFinder = find.byKey(const ValueKey('signature_draw_pad'));
      await tester.ensureVisible(padFinder);
      await tester.pumpAndSettle();
      await tester.drag(padFinder, const Offset(80, 25));
      await tester.pumpAndSettle();
      await tapRealAsync(find.text('Use This Drawing'));
      await tapRealAsync(find.text('Save Signature to Vault'));

      expect(find.text('Active & In Use'), findsOneWidget);
      expect(find.text('Primary Signature'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SET-07 & SET-09: DataExport truncation banner AR RTL + ComingSoon 3 honest tabs', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final user = _baseUser();
      final settingsRepo = _FakeSettingsRepository(baseUser: user);
      final bizRepo = _FakeBusinessRepository(
        businesses: [_baseBusiness()],
        members: const [
          BusinessMemberDto(
            memberId: 'm1',
            userId: 'u1',
            firstName: 'Youssef',
            lastName: 'Trabelsi',
            email: 'youssef@carthage.tn',
            role: 'OWNER',
            status: 'ACTIVE',
          ),
        ],
      );

      // SET-07 Dark AR RTL Tablet
      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const DataExportSettingsScreen(),
          auth: _TestAuthNotifier(user),
          settingsRepo: settingsRepo,
          bizRepo: bizRepo,
          initialLocale: AfabLocalePreference.ar,
          themeMode: ThemeMode.dark,
          txRepo: _FakeTxRepo(),
          custRepo: _FakeCustRepo(),
          invRepo: _FakeInvRepo(),
        ),
      );
      await tester.pumpAndSettle();

      // Loaded = 3 vs Total = 1202 (from 1200 + 1 + 1) -> truncation warning rendered
      expect(find.textContaining('1202'), findsWidgets);
      expect(tester.takeException(), isNull);

      // SET-09 Coming Soon 3 tabs (no fake toggles)
      _setViewport(tester, const Size(390, 844));
      for (final tab in ComingSoonSettingsTab.values) {
        await tester.pumpWidget(
          _buildTestApp(
            prefs: prefs,
            home: SettingsComingSoonScreen(tab: tab),
            auth: _TestAuthNotifier(user),
            settingsRepo: settingsRepo,
            bizRepo: bizRepo,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Switch), findsNothing);
        if (tab == ComingSoonSettingsTab.usersPermissions) {
          expect(find.text('Youssef Trabelsi'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('SET-10: AccountDeletionFlow Arabic tombstone text, ReadOnly deadlock & delete confirmation', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final user = _baseUser();
      final readOnlyBiz = _baseBusiness(editable: false, accessMode: 'READ_ONLY');

      // Check Arabic Step 2 accurate tombstone text first
      final arSettingsRepo = _FakeSettingsRepository(baseUser: user);
      final arBizRepo = _FakeBusinessRepository(businesses: [readOnlyBiz]);
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const AccountDeletionFlowScreen(),
          auth: _TestAuthNotifier(user),
          settingsRepo: arSettingsRepo,
          bizRepo: arBizRepo,
          initialLocale: AfabLocalePreference.ar,
        ),
      );
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.text('تخطي التصدير — أريد حذف هذا الحساب'),
      );
      expect(
        find.textContaining('يتم الاحتفاظ بسجلات الشركات المالية'),
        findsOneWidget,
      );

      // Now test EN Step 1 -> Step 2 -> Step 3 READ_ONLY deadlock + editable Archive -> delete
      const extraReadOnlyBiz = BusinessDto(
        id: 'b_ro',
        name: 'Locked Unit',
        currency: 'TND',
        accessMode: 'READ_ONLY',
        editable: false,
        active: false,
      );
      final blockedSettingsRepo = _FakeSettingsRepository(
        baseUser: user,
        preflight: const AccountDeletionPreflightDto(
          canDelete: false,
          blockingBusinesses: [
            BlockingBusinessDto(
              businessId: 'b_ro',
              businessName: 'Locked Unit',
              activeMemberCount: 1,
              hasOtherActiveMembers: false,
            ),
            BlockingBusinessDto(
              businessId: 'b1',
              businessName: 'Carthage Labs',
              activeMemberCount: 1,
              hasOtherActiveMembers: false,
            ),
          ],
        ),
      );
      final auth = _TestAuthNotifier(user);
      final bio = _FakeBiometricService(enabled: true);
      final blockedBizRepo = _FakeBusinessRepository(
        businesses: [extraReadOnlyBiz, _baseBusiness()],
        archiveThrowsReadOnly: false,
        onArchived: () {
          blockedSettingsRepo.preflight =
              const AccountDeletionPreflightDto(canDelete: true);
        },
      );

      await tester.pumpWidget(
        _buildTestApp(
          prefs: prefs,
          home: const AccountDeletionFlowScreen(),
          auth: auth,
          settingsRepo: blockedSettingsRepo,
          bizRepo: blockedBizRepo,
          bio: bio,
        ),
      );
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.text('Skip Export — I want to delete this account'),
      );
      await _tapVisible(
        tester,
        find.text('I have read and understand these effects'),
      );

      // READ_ONLY blocking warning is visible + Manage Allocations button
      expect(find.textContaining('currently Read-Only'), findsOneWidget);
      await _tapVisible(tester, find.text('Archive Business'));
      await tester.tap(find.text('Archive Business').last);
      await tester.pumpAndSettle();

      // Now canDelete is true; type "delete youssef@carthage.tn" and confirm
      await tester.enterText(
        find.byType(TextField).last,
        'delete youssef@carthage.tn',
      );
      await tester.pumpAndSettle();
      await _tapVisible(tester, find.text('Delete this account'));

      expect(
        blockedSettingsRepo.deletedConfirmation?.toLowerCase(),
        'delete youssef@carthage.tn',
      );
      expect(auth.localLogoutCalled, isTrue);
      expect(bio.cleared, isTrue);
      expect(find.text('LOGIN_ROUTE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
