import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/budgets/domain/budgets_providers.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/calendar/domain/calendar_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/reports/domain/reports_providers.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

@immutable
class TransactionFilterState {
  const TransactionFilterState({
    this.period = TransactionPeriod.monthly,
    this.startDate,
    this.endDate,
    this.search = '',
    this.type,
    this.categoryId,
    this.status,
    this.paymentMethod,
    this.taxDeductible,
    this.page = 0,
    this.sortField = TransactionSortField.date,
    this.sortAscending = false,
  });

  final TransactionPeriod period;
  final String? startDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD
  final String search;
  final TransactionType? type;
  final String? categoryId;
  final TransactionStatus? status;
  final PaymentMethod? paymentMethod;
  final bool? taxDeductible;
  final int page;
  final TransactionSortField sortField;
  final bool sortAscending;

  int get activeFilterCount {
    var count = 0;
    if (type != null) count++;
    if (categoryId != null && categoryId!.isNotEmpty) count++;
    if (status != null) count++;
    if (paymentMethod != null) count++;
    if (taxDeductible == true) count++;
    if (period == TransactionPeriod.custom &&
        (startDate != null || endDate != null)) {
      count++;
    }
    return count;
  }

  TransactionFilterState copyWith({
    TransactionPeriod? period,
    String? startDate,
    bool clearStartDate = false,
    String? endDate,
    bool clearEndDate = false,
    String? search,
    TransactionType? type,
    bool clearType = false,
    String? categoryId,
    bool clearCategoryId = false,
    TransactionStatus? status,
    bool clearStatus = false,
    PaymentMethod? paymentMethod,
    bool clearPaymentMethod = false,
    bool? taxDeductible,
    bool clearTaxDeductible = false,
    int? page,
    TransactionSortField? sortField,
    bool? sortAscending,
  }) {
    return TransactionFilterState(
      period: period ?? this.period,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      search: search ?? this.search,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      status: clearStatus ? null : (status ?? this.status),
      paymentMethod:
          clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      taxDeductible:
          clearTaxDeductible ? null : (taxDeductible ?? this.taxDeductible),
      page: page ?? this.page,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}

/// Computes `startDate`/`endDate` for `weekly`/`monthly`/`yearly`/`all`
/// aligned with `FinanceStatsService.java:370-386`.
(String?, String?) resolveDatesForPeriod(
  TransactionPeriod period, {
  DateTime? nowOverride,
}) {
  final now = nowOverride ?? DateTime.now();
  final fmt = DateFormat('yyyy-MM-dd', 'en_US');
  return switch (period) {
    TransactionPeriod.weekly => (
        fmt.format(now.subtract(const Duration(days: 6))),
        fmt.format(now),
      ),
    TransactionPeriod.monthly => (
        fmt.format(DateTime(now.year, now.month, 1)),
        fmt.format(DateTime(now.year, now.month + 1, 0)),
      ),
    TransactionPeriod.yearly => (
        fmt.format(DateTime(now.year, 1, 1)),
        fmt.format(DateTime(now.year, 12, 31)),
      ),
    TransactionPeriod.all => (null, null),
    TransactionPeriod.custom => (null, null),
  };
}

class TransactionFilterNotifier extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() {
    ref.watch(activeBusinessIdProvider);
    final (start, end) = resolveDatesForPeriod(TransactionPeriod.monthly);
    return TransactionFilterState(
      period: TransactionPeriod.monthly,
      startDate: start,
      endDate: end,
    );
  }

  void setPeriod(TransactionPeriod period) {
    final (start, end) = resolveDatesForPeriod(period);
    state = state.copyWith(
      period: period,
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
      page: 0,
    );
  }

  void setCustomDateRange(String? start, String? end) {
    state = state.copyWith(
      period: TransactionPeriod.custom,
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
      page: 0,
    );
  }

  void setSearch(String query) {
    state = state.copyWith(search: query, page: 0);
  }

  void setType(TransactionType? type) {
    state = state.copyWith(
      type: type,
      clearType: type == null,
      page: 0,
    );
  }

  void setCategoryId(String? categoryId) {
    final clean = (categoryId != null && categoryId.isNotEmpty) ? categoryId : null;
    state = state.copyWith(
      categoryId: clean,
      clearCategoryId: clean == null,
      page: 0,
    );
  }

  void setStatus(TransactionStatus? status) {
    state = state.copyWith(
      status: status,
      clearStatus: status == null,
      page: 0,
    );
  }

  void setPaymentMethod(PaymentMethod? method) {
    state = state.copyWith(
      paymentMethod: method,
      clearPaymentMethod: method == null,
      page: 0,
    );
  }

  void setTaxDeductible(bool? taxDeductible) {
    state = state.copyWith(
      taxDeductible: taxDeductible == true ? true : null,
      clearTaxDeductible: taxDeductible != true,
      page: 0,
    );
  }

  void applyFilters({
    TransactionType? type,
    String? categoryId,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    bool? taxDeductible,
    String? startDate,
    String? endDate,
    TransactionPeriod? period,
  }) {
    final cleanCat = (categoryId != null && categoryId.isNotEmpty) ? categoryId : null;
    state = TransactionFilterState(
      period: period ??
          ((startDate != null || endDate != null)
              ? TransactionPeriod.custom
              : state.period),
      startDate: startDate,
      endDate: endDate,
      search: state.search,
      type: type,
      categoryId: cleanCat,
      status: status,
      paymentMethod: paymentMethod,
      taxDeductible: taxDeductible == true ? true : null,
      page: 0,
      sortField: state.sortField,
      sortAscending: state.sortAscending,
    );
  }

  void resetFilters() {
    final (start, end) = resolveDatesForPeriod(TransactionPeriod.monthly);
    state = TransactionFilterState(
      period: TransactionPeriod.monthly,
      startDate: start,
      endDate: end,
      search: '',
    );
  }

  void setPage(int page) => state = state.copyWith(page: page);

  void toggleSort(TransactionSortField field) {
    if (state.sortField == field) {
      state = state.copyWith(sortAscending: !state.sortAscending);
    } else {
      state = state.copyWith(sortField: field, sortAscending: false);
    }
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilterState>(
  TransactionFilterNotifier.new,
);

final transactionListProvider = FutureProvider<TransactionPageDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final filter = ref.watch(transactionFilterProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  return ref.read(transactionRepositoryProvider).getTransactions(
        type: filter.type,
        categoryId: filter.categoryId,
        status: filter.status,
        paymentMethod: filter.paymentMethod,
        taxDeductible: filter.taxDeductible,
        startDate: filter.startDate,
        endDate: filter.endDate,
        search: filter.search,
        page: filter.page,
        size: 15,
        cancelToken: cancelToken,
      );
});

final transactionDetailProvider = FutureProvider.autoDispose
    .family<TransactionDto, String>((ref, id) async {
  ref.watch(activeBusinessIdProvider);
  return ref.read(transactionRepositoryProvider).getTransactionById(id);
});

class SelectedTransactionIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(activeBusinessIdProvider);
    return null;
  }

  void select(String? id) => state = id;
}

final selectedTransactionIdProvider =
    NotifierProvider<SelectedTransactionIdNotifier, String?>(
  SelectedTransactionIdNotifier.new,
);

/// Helper to invalidate all dependent ledgers and analytics after any
/// transaction create / edit / split / delete mutation.
void invalidateFinanceLedgers(WidgetRef ref, {String? editedTransactionId}) {
  ref.invalidate(transactionListProvider);
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(aiPulseProvider);
  ref.invalidate(expenseSummaryProvider);
  ref.invalidate(expenseListProvider);
  ref.invalidate(revenueSummaryProvider);
  ref.invalidate(revenueListProvider);
  ref.invalidate(budgetListProvider);
  ref.invalidate(budgetOverviewSummaryProvider);
  ref.invalidate(calendarMonthTransactionsProvider);
  ref.invalidate(pnlReportProvider);
  ref.invalidate(cashFlowReportProvider);
  ref.invalidate(comparisonReportProvider);
  if (editedTransactionId != null && editedTransactionId.isNotEmpty) {
    ref.invalidate(transactionDetailProvider(editedTransactionId));
  }
}
