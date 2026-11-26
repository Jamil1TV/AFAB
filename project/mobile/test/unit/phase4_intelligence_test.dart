import 'package:afab_mobile/features/calendar/domain/calendar_helpers.dart';
import 'package:afab_mobile/features/currencies/data/currency_dtos.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/reports/data/report_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4 Unit Tests — Calendar, Currencies & Reports', () {
    test('CalendarMonth handles 28, 29 (leap Feb 2024 & 2028), 30, and 31-day bounds',
        () {
      const feb2024 = CalendarMonth(year: 2024, month: 2);
      const feb2025 = CalendarMonth(year: 2025, month: 2);
      const feb2028 = CalendarMonth(year: 2028, month: 2);
      const apr2026 = CalendarMonth(year: 2026, month: 4);
      const dec2026 = CalendarMonth(year: 2026, month: 12);

      expect(feb2024.firstDayIso, '2024-02-01');
      expect(feb2024.lastDayIso, '2024-02-29');
      expect(feb2025.lastDayIso, '2025-02-28');
      expect(feb2028.lastDayIso, '2028-02-29');
      expect(apr2026.lastDayIso, '2026-04-30');
      expect(dec2026.lastDayIso, '2026-12-31');
      expect(dec2026.next(), const CalendarMonth(year: 2027, month: 1));
      expect(
        const CalendarMonth(year: 2026, month: 1).previous(),
        const CalendarMonth(year: 2025, month: 12),
      );
    });

    test('buildCalendarMonthSummary sums COMPLETED converted amounts and counts PENDING',
        () {
      const month = CalendarMonth(year: 2026, month: 11);
      final txs = [
        TransactionDto(
          id: '1',
          type: TransactionType.income,
          amount: Decimal.parse('100.00'),
          currency: 'EUR',
          convertedAmount: Decimal.parse('330.000'),
          description: 'EU Retainer',
          transactionDate: '2026-11-10',
          paymentMethod: PaymentMethod.bankTransfer,
          status: TransactionStatus.completed,
        ),
        TransactionDto(
          id: '2',
          type: TransactionType.expense,
          amount: Decimal.parse('80.500'),
          currency: 'TND',
          description: 'Cloud',
          transactionDate: '2026-11-10',
          paymentMethod: PaymentMethod.card,
          status: TransactionStatus.completed,
        ),
        TransactionDto(
          id: '3',
          type: TransactionType.expense,
          amount: Decimal.parse('50.000'),
          currency: 'TND',
          description: 'Pending Bill',
          transactionDate: '2026-11-12',
          paymentMethod: PaymentMethod.cash,
          status: TransactionStatus.pending,
        ),
      ];

      final summary = buildCalendarMonthSummary(month: month, transactions: txs);
      expect(summary.monthlyInflow, Decimal.parse('330.000'));
      expect(summary.monthlyOutflow, Decimal.parse('80.500'));
      expect(summary.pendingCount, 1);
      expect(summary.totalCount, 3);
      expect(summary.byDate['2026-11-10']?.transactions.length, 2);
    });

    test('FxRateAlert JSON round-trip and trigger condition evaluation', () {
      final alert = FxRateAlert(
        id: 'a-1',
        pair: 'USD/TND',
        base: 'USD',
        target: 'TND',
        condition: 'above',
        targetRate: Decimal.parse('3.1000'),
        active: true,
        createdAt: '2026-11-26T00:00:00Z',
      );
      final roundTrip = FxRateAlert.fromJson(alert.toJson());
      expect(roundTrip.pair, 'USD/TND');
      expect(roundTrip.targetRate, Decimal.parse('3.1000'));
      expect(roundTrip.isTriggered(Decimal.parse('3.1000')), isTrue);
      expect(roundTrip.isTriggered(Decimal.parse('2.9900')), isFalse);
      expect(
        roundTrip.copyWith(active: false).isTriggered(Decimal.parse('3.20')),
        isFalse,
      );
    });

    test('FxRiskCalculator computes exact 5 sensitivity scenarios', () {
      final scenarios = FxRiskCalculator.calculate(
        foreignAmount: Decimal.fromInt(1000),
        spotRate: Decimal.parse('3.0000'),
        paymentTermsDays: 30,
      );
      expect(scenarios.length, 5);
      expect(scenarios[2].shiftPct, 0.0);
      expect(scenarios[2].projectedValue, Decimal.parse('3000.0000'));
      expect(scenarios[0].projectedValue, Decimal.parse('3090.0000'));
      expect(scenarios[4].deltaValue, Decimal.parse('-90.0000'));
    });

    test('Report DTOs and SubscriptionSnapshotDto entitlements/usage parse accurately',
        () {
      final pnl = ProfitAndLossReportDto.fromJson({
        'period': 'November 2026',
        'currency': 'TND',
        'totalRevenue': '8500.000',
        'totalExpenses': '2200.000',
        'grossProfit': '8500.000',
        'netOperatingIncome': '6300.000',
        'profitMarginPct': 74.12,
        'revenueBreakdown': [
          {
            'categoryName': 'Consulting',
            'amount': '8500.000',
            'percentage': 100.0,
            'transactionCount': 4,
          },
        ],
      });
      expect(pnl.netOperatingIncome, Decimal.parse('6300.000'));
      expect(pnl.revenueBreakdown.single.categoryName, 'Consulting');

      final sub = SubscriptionSnapshotDto.fromJson({
        'planSlug': 'plus',
        'planName': 'Plus',
        'status': 'ACTIVE',
        'entitlements': {'reports.level': 'advanced', 'export.per_month': 15},
        'usage': {'export.per_month': 3},
      });
      expect(sub.reportsLevel, 'advanced');
      expect(sub.monthlyExportLimit, 15);
      expect(sub.monthlyExportUsed, 3);
    });
  });
}
