import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/expenses/data/expense_dtos.dart';
import 'package:afab_mobile/features/expenses/data/expense_repository.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensePeriodNotifier extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() => DashboardPeriod.month;

  void select(DashboardPeriod period) => state = period;
}

final expensePeriodProvider =
    NotifierProvider<ExpensePeriodNotifier, DashboardPeriod>(
  ExpensePeriodNotifier.new,
);

@immutable
class ExpenseFilterState {
  const ExpenseFilterState({
    this.categoryId,
    this.search = '',
    this.page = 0,
  });

  final String? categoryId;
  final String search;
  final int page;

  ExpenseFilterState copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? search,
    int? page,
  }) {
    return ExpenseFilterState(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }
}

class ExpenseFilterNotifier extends Notifier<ExpenseFilterState> {
  @override
  ExpenseFilterState build() {
    ref.watch(activeBusinessIdProvider);
    return const ExpenseFilterState();
  }

  void setCategory(String? id) {
    state = id == null || id.isEmpty
        ? state.copyWith(clearCategory: true, page: 0)
        : state.copyWith(categoryId: id, page: 0);
  }

  void setSearch(String query) => state = state.copyWith(search: query, page: 0);

  void setPage(int page) => state = state.copyWith(page: page);

  void reset() => state = const ExpenseFilterState();
}

final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilterState>(
  ExpenseFilterNotifier.new,
);

final expenseSummaryProvider = FutureProvider<ExpenseSummaryDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final period = ref.watch(expensePeriodProvider);
  return ref.read(expenseRepositoryProvider).getSummary(period);
});

final expenseListProvider = FutureProvider<TransactionPageDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final filter = ref.watch(expenseFilterProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  return ref.read(expenseRepositoryProvider).getExpenses(
        categoryId: filter.categoryId,
        search: filter.search,
        page: filter.page,
        size: 15,
        cancelToken: cancelToken,
      );
});
