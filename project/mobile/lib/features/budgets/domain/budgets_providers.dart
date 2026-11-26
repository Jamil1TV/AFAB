import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/budgets/data/budget_dtos.dart';
import 'package:afab_mobile/features/budgets/data/budgets_repository.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncludeArchivedBudgetsNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(activeBusinessIdProvider);
    return false;
  }

  void setIncludeArchived(bool value) => state = value;
}

final includeArchivedBudgetsProvider =
    NotifierProvider<IncludeArchivedBudgetsNotifier, bool>(
  IncludeArchivedBudgetsNotifier.new,
);

final budgetOverviewSummaryProvider =
    FutureProvider<BudgetOverviewSummaryDto>((ref) async {
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
      .read(budgetsRepositoryProvider)
      .getSummary(cancelToken: cancelToken);
});

final budgetListProvider = FutureProvider<List<BudgetDto>>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final includeArchived = ref.watch(includeArchivedBudgetsProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .read(budgetsRepositoryProvider)
      .listBudgets(includeArchived: includeArchived, cancelToken: cancelToken);
});

void invalidateBudgetProviders(WidgetRef ref) {
  ref.invalidate(budgetListProvider);
  ref.invalidate(budgetOverviewSummaryProvider);
  ref.invalidate(dashboardSummaryProvider);
}
