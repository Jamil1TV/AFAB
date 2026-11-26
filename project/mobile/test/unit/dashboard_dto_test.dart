import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard & Subscription DTO parsing', () {
    test('parses DashboardSummaryDTO preserving numeric expense slices', () {
      final json = <String, dynamic>{
        'currency': 'TND',
        'businessName': 'Carthage Labs',
        'kpiData': {
          'revenue': {
            'value': 'DT 12,450.000',
            'change': '+14.2%',
            'isPositive': true,
            'rawValue': 12450.0,
            'rawChange': 14.2,
          },
          'expenses': {
            'value': 'DT 3,250.750',
            'change': '-4.5%',
            'isPositive': false,
            'rawValue': 3250.75,
            'rawChange': -4.5,
          },
          'profit': {
            'value': 'DT 9,199.250',
            'change': '+21.0%',
            'isPositive': true,
            'rawValue': 9199.25,
            'rawChange': 21.0,
          },
          'cashFlow': {
            'value': 'DT 8,900.000',
            'change': '+9.1%',
            'isPositive': true,
            'rawValue': 8900.0,
            'rawChange': 9.1,
          },
        },
        'revenueData': [
          {'month': 'Jan', 'name': 'Jan', 'revenue': 4000, 'expenses': 1200},
          {'month': 'Feb', 'name': 'Feb', 'revenue': 8450, 'expenses': 2050.75},
        ],
        'transactions': [
          {
            'id': 'tx-1',
            'name': 'Atlas Cloud',
            'description': 'Hosting',
            'rawAmount': 250.5,
            'date': '2026-11-20',
            'type': 'EXPENSE',
            'status': 'COMPLETED',
            'initials': 'AC',
            'isCredit': false,
          },
        ],
        'expenseCategories': [
          {
            'name': 'Cloud Infrastructure',
            'value': 1450.75,
            'amount': 'USD 1,450.75',
            'percentage': 44.6,
            'color': '#8b5cf6',
          },
          {
            'name': 'Payroll',
            'value': 1800.0,
            'amount': 'USD 1,800.00',
            'percentage': 55.4,
            'color': '#10b981',
          },
        ],
        'reminders': [
          {
            'id': 'rem-1',
            'title': 'Cloud Budget Nearing Cap',
            'date': '2026-11-30',
            'priority': 'high',
            'type': 'budget',
          },
        ],
        'customers': [
          {
            'id': 'cust-1',
            'name': 'MedTech Partners',
            'revenue': 7200.5,
            'avatar': 'MP',
          },
        ],
        'budgets': {
          'currency': 'TND',
          'activeBudgetCount': 2,
          'approachingCount': 1,
          'overBudgetCount': 0,
          'budgets': [
            {
              'id': 'b-1',
              'name': 'Monthly Cloud',
              'budgetAmount': 2000,
              'currency': 'TND',
              'categoryName': 'Cloud Infrastructure',
              'categoryColor': '#8b5cf6',
              'actualSpending': 1450.75,
              'remainingAmount': 549.25,
              'overBudgetAmount': 0,
              'percentageConsumed': 72.5,
              'alertLevel': 'APPROACHING',
            },
          ],
        },
      };

      final dto = DashboardSummaryDto.fromJson(json);

      expect(dto.currency, 'TND');
      expect(dto.businessName, 'Carthage Labs');
      expect(dto.revenue.isPositive, isTrue);
      expect(dto.expenses.isPositive, isFalse);
      expect(dto.transactions.first.isCredit, isFalse);
      // Verifies fix for Web ExpenseCategories $0.00 parsing bug:
      expect(dto.expenseCategories[0].numericValue, Decimal.parse('1450.75'));
      expect(dto.expenseCategories[1].numericValue, Decimal.parse('1800'));
      final totalExpenses = dto.expenseCategories.fold<Decimal>(
        Decimal.zero,
        (acc, slice) => acc + slice.numericValue,
      );
      expect(totalExpenses, Decimal.parse('3250.75'));
      expect(dto.budgets?.approachingCount, 1);
      expect(dto.reminders.first.type, 'budget');
    });

    test('parses SubscriptionSnapshotDto Jackson trial boolean field', () {
      final dto = SubscriptionSnapshotDto.fromJson(const {
        'planSlug': 'plus',
        'planName': 'Plus',
        'status': 'TRIALING',
        'trial': true,
        'trialDaysRemaining': 11,
        'gracePeriodHoursRemaining': 48,
        'allocationAttentionRequired': true,
        'editableBusinessLimit': 1,
        'editableBusinessCount': 1,
        'totalBusinessCount': 3,
      });

      expect(dto.isTrial, isTrue);
      expect(dto.trialDaysRemaining, 11);
      expect(dto.gracePeriodHoursRemaining, 48);
      expect(dto.allocationAttentionRequired, isTrue);
      expect(dto.totalBusinessCount, 3);
    });

    test('parses AiPulseDto alerts', () {
      final pulse = AiPulseDto.fromJson(const {
        'currency': 'USD',
        'alerts': [
          {
            'id': 'alert-1',
            'type': 'CASH_FLOW',
            'severity': 'WARNING',
            'title': 'SaaS spend spiked 18%',
            'description': 'Review recurring cloud subscriptions.',
            'copilotPrompt': 'Analyze SaaS spend this month',
          },
        ],
      });

      expect(pulse.alerts.length, 1);
      expect(pulse.alerts.first.title, 'SaaS spend spiked 18%');
      expect(pulse.alerts.first.severity, 'WARNING');
    });
  });
}
