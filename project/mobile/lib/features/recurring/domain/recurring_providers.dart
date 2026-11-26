import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/budgets/domain/budgets_providers.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:afab_mobile/features/recurring/data/recurring_repository.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RecurringStatusFilter { all, active, paused }

class RecurringStatusFilterNotifier extends Notifier<RecurringStatusFilter> {
  @override
  RecurringStatusFilter build() {
    ref.watch(activeBusinessIdProvider);
    return RecurringStatusFilter.all;
  }

  void select(RecurringStatusFilter filter) => state = filter;
}

final recurringStatusFilterProvider =
    NotifierProvider<RecurringStatusFilterNotifier, RecurringStatusFilter>(
  RecurringStatusFilterNotifier.new,
);

final recurringListProvider =
    FutureProvider<List<RecurringTransactionDto>>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .read(recurringRepositoryProvider)
      .listRules(cancelToken: cancelToken);
});

void invalidateAfterRecurringRun(WidgetRef ref, {bool generatedAny = false}) {
  ref.invalidate(recurringListProvider);
  if (generatedAny) {
    ref.invalidate(transactionListProvider);
    ref.invalidate(expenseSummaryProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(revenueSummaryProvider);
    ref.invalidate(revenueListProvider);
    ref.invalidate(budgetListProvider);
    ref.invalidate(budgetOverviewSummaryProvider);
    ref.invalidate(dashboardSummaryProvider);
  }
}
