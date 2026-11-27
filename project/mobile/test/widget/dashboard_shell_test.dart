import 'dart:convert';

import 'package:afab_mobile/app/afab_app.dart';
import 'package:afab_mobile/app/shell/afab_floating_nav_dock.dart';
import 'package:afab_mobile/core/network/connectivity_provider.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/notifications/data/notification_dto.dart';
import 'package:afab_mobile/features/notifications/domain/notifications_provider.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  SessionState build() => const SessionState(
        status: SessionStatus.authenticated,
        user: UserProfile(
          id: 'user-1',
          firstName: 'Youssef',
          lastName: 'Trabelsi',
          email: 'youssef@carthage.tn',
          emailVerified: true,
          onboardingComplete: true,
          businessId: 'biz-1',
          businessName: 'Carthage Labs',
          currency: 'USD',
        ),
      );
}

class _TestNotificationsNotifier extends NotificationsNotifier {
  @override
  Future<NotificationsResponseDto> build() async =>
      const NotificationsResponseDto(
        unreadCount: 2,
        notifications: [
          NotificationItemDto(
            id: 'n-1',
            type: 'BUDGET',
            severity: 'WARNING',
            title: 'Cloud budget at 80%',
            message: 'Monthly infrastructure spending reached 80%.',
            read: false,
          ),
        ],
      );
}

DashboardSummaryDto _sampleSummary() {
  return DashboardSummaryDto(
    revenue: KpiMetricDto(
      formattedValue: r'$12,450.00',
      change: '+14.2%',
      isPositive: true,
      rawValue: Decimal.parse('12450'),
      rawChange: Decimal.parse('14.2'),
    ),
    expenses: KpiMetricDto(
      formattedValue: r'$3,250.00',
      change: '-4.0%',
      isPositive: false,
      rawValue: Decimal.parse('3250'),
      rawChange: Decimal.parse('-4.0'),
    ),
    profit: KpiMetricDto(
      formattedValue: r'$9,200.00',
      change: '+18.1%',
      isPositive: true,
      rawValue: Decimal.parse('9200'),
      rawChange: Decimal.parse('18.1'),
    ),
    cashFlow: KpiMetricDto(
      formattedValue: r'$8,800.00',
      change: '+9.5%',
      isPositive: true,
      rawValue: Decimal.parse('8800'),
      rawChange: Decimal.parse('9.5'),
    ),
    revenueData: const [
      RevenueDataPointDto(month: 'Jun', name: 'Jun', revenue: 4200, expenses: 1100),
      RevenueDataPointDto(month: 'Jul', name: 'Jul', revenue: 5100, expenses: 1300),
      RevenueDataPointDto(month: 'Aug', name: 'Aug', revenue: 6800, expenses: 1600),
      RevenueDataPointDto(month: 'Sep', name: 'Sep', revenue: 7900, expenses: 1850),
      RevenueDataPointDto(month: 'Oct', name: 'Oct', revenue: 9400, expenses: 2400),
      RevenueDataPointDto(month: 'Nov', name: 'Nov', revenue: 12450, expenses: 3250),
    ],
    transactions: [
      RecentTransactionItemDto(
        id: 'tx-1',
        name: 'Stripe Payout',
        description: 'SaaS Subscriptions',
        rawAmount: Decimal.parse('4500'),
        date: '2026-11-22',
        type: 'INCOME',
        status: 'COMPLETED',
        initials: 'SP',
        isCredit: true,
      ),
    ],
    expenseCategories: [
      ExpenseCategorySliceDto(
        name: 'Cloud',
        numericValue: Decimal.parse('1450'),
        percentage: 44.6,
        colorHex: '#8b5cf6',
      ),
      ExpenseCategorySliceDto(
        name: 'Payroll',
        numericValue: Decimal.parse('1800'),
        percentage: 55.4,
        colorHex: '#10b981',
      ),
    ],
    reminders: const [
      ReminderItemDto(
        id: 'rem-1',
        title: 'Cloud Budget Cap',
        date: '2026-11-30',
        priority: 'high',
        type: 'budget',
      ),
    ],
    customers: [
      TopCustomerItemDto(
        id: 'c-1',
        name: 'MedTech Partners',
        revenue: Decimal.parse('7200'),
        avatar: 'MP',
      ),
    ],
    currency: 'USD',
    businessName: 'Carthage Labs',
    budgets: BudgetSummaryDto(
      currency: 'USD',
      activeBudgetCount: 2,
      approachingCount: 1,
      overBudgetCount: 0,
      budgets: [
        BudgetProgressDto(
          id: 'b-1',
          name: 'Cloud Budget',
          budgetAmount: Decimal.parse('2000'),
          currency: 'USD',
          categoryName: 'Cloud',
          categoryColor: '#8b5cf6',
          actualSpending: Decimal.parse('1450'),
          remainingAmount: Decimal.parse('550'),
          overBudgetAmount: Decimal.zero,
          percentageConsumed: 72.5,
          alertLevel: 'APPROACHING',
        ),
      ],
    ),
  );
}

Widget _buildTestApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(_TestAuthNotifier.new),
      isOnlineProvider.overrideWithValue(true),
      dashboardSummaryProvider.overrideWith((_) async => _sampleSummary()),
      aiPulseProvider.overrideWith(
        (_) async => const AiPulseDto(
          currency: 'USD',
          alerts: [
            PulseAlertDto(
              id: 'a-1',
              type: 'SPEND',
              severity: 'INFO',
              title: 'Cloud spend steady',
              description: 'Within monthly target.',
              copilotPrompt: 'Review cloud spend',
            ),
          ],
        ),
      ),
      subscriptionSnapshotProvider.overrideWith(
        (_) async => const SubscriptionSnapshotDto(
          planSlug: 'free',
          planName: 'Free',
          status: 'ACTIVE',
          isTrial: true,
          trialDaysRemaining: 9,
          allocationAttentionRequired: false,
          editableBusinessLimit: 1,
          editableBusinessCount: 1,
          totalBusinessCount: 2,
        ),
      ),
      businessListProvider.overrideWith(
        (_) async => const [
          BusinessDto(
            id: 'biz-1',
            name: 'Carthage Labs',
            currency: 'USD',
            active: true,
            editable: true,
            accessMode: 'EDITABLE',
            userRole: 'OWNER',
          ),
          BusinessDto(
            id: 'biz-2',
            name: 'Sahara Studio',
            currency: 'TND',
            active: false,
            editable: false,
            accessMode: 'READ_ONLY',
            userRole: 'OWNER',
          ),
        ],
      ),
      notificationsProvider.overrideWith(_TestNotificationsNotifier.new),
    ],
    child: const AfabApp(),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 2 Adaptive Shell & Dashboard widget tests', () {
    testWidgets(
        'Phone 390x844 Light EN renders NavigationBar, Dashboard cards, and BusinessSwitcherSheet',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(prefs));
      await tester.pumpAndSettle();

      // Adaptive phone floating dock
      expect(find.byType(AfabFloatingNavDock), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Non-zero ExpenseCategories total fixes Web's $0.00 bug
      expect(find.text(r'$3,250.00'), findsWidgets);
      expect(find.text('Carthage Labs'), findsWidgets);

      // Open BusinessSwitcherSheet via ShellAppBar switcher pill
      await tester.tap(find.text('Carthage Labs').first);
      await tester.pumpAndSettle();

      expect(find.text('Workspaces'), findsOneWidget);
      expect(find.text('Sahara Studio'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tablet 1024x768 Dark AR RTL renders NavigationRail without overflow',
        (tester) async {
      _setViewport(tester, const Size(1024, 768));
      SharedPreferences.setMockInitialValues({
        'afab_locale': 'ar',
        'afab_appearance_settings': jsonEncode(
          const AppearanceSettings(themeMode: ThemeMode.dark).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(prefs));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(AfabFloatingNavDock), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
