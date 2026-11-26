import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/revenue/data/revenue_dtos.dart';
import 'package:afab_mobile/features/revenue/data/revenue_repository.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RevenuePeriodNotifier extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() => DashboardPeriod.month;

  void select(DashboardPeriod period) => state = period;
}

final revenuePeriodProvider =
    NotifierProvider<RevenuePeriodNotifier, DashboardPeriod>(
  RevenuePeriodNotifier.new,
);

@immutable
class RevenueFilterState {
  const RevenueFilterState({
    this.categoryId,
    this.search = '',
    this.page = 0,
  });

  final String? categoryId;
  final String search;
  final int page;

  RevenueFilterState copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? search,
    int? page,
  }) {
    return RevenueFilterState(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }
}

class RevenueFilterNotifier extends Notifier<RevenueFilterState> {
  @override
  RevenueFilterState build() {
    ref.watch(activeBusinessIdProvider);
    return const RevenueFilterState();
  }

  void setCategory(String? id) {
    state = id == null || id.isEmpty
        ? state.copyWith(clearCategory: true, page: 0)
        : state.copyWith(categoryId: id, page: 0);
  }

  void setSearch(String query) => state = state.copyWith(search: query, page: 0);

  void setPage(int page) => state = state.copyWith(page: page);

  void reset() => state = const RevenueFilterState();
}

final revenueFilterProvider =
    NotifierProvider<RevenueFilterNotifier, RevenueFilterState>(
  RevenueFilterNotifier.new,
);

final revenueSummaryProvider = FutureProvider<RevenueSummaryDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final period = ref.watch(revenuePeriodProvider);
  return ref.read(revenueRepositoryProvider).getSummary(period);
});

final revenueListProvider = FutureProvider<TransactionPageDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final filter = ref.watch(revenueFilterProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  return ref.read(revenueRepositoryProvider).getRevenue(
        categoryId: filter.categoryId,
        search: filter.search,
        page: filter.page,
        size: 15,
        cancelToken: cancelToken,
      );
});
