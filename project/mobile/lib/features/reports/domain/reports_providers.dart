import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/reports/data/report_dtos.dart';
import 'package:afab_mobile/features/reports/data/reports_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReportsTab { pnl, cashflow, comparison }

@immutable
class ReportsFilterState {
  const ReportsFilterState({
    this.tab = ReportsTab.pnl,
    this.period = 'this_month',
    this.comparisonPeriod = 'last_month',
    this.customStart,
    this.customEnd,
  });

  final ReportsTab tab;
  final String period;
  final String comparisonPeriod;
  final String? customStart;
  final String? customEnd;

  ReportsFilterState copyWith({
    ReportsTab? tab,
    String? period,
    String? comparisonPeriod,
    String? customStart,
    bool clearCustomStart = false,
    String? customEnd,
    bool clearCustomEnd = false,
  }) {
    return ReportsFilterState(
      tab: tab ?? this.tab,
      period: period ?? this.period,
      comparisonPeriod: comparisonPeriod ?? this.comparisonPeriod,
      customStart: clearCustomStart ? null : (customStart ?? this.customStart),
      customEnd: clearCustomEnd ? null : (customEnd ?? this.customEnd),
    );
  }
}

class ReportsFilterNotifier extends Notifier<ReportsFilterState> {
  @override
  ReportsFilterState build() {
    ref.watch(activeBusinessIdProvider);
    return const ReportsFilterState();
  }

  void setTab(ReportsTab tab) => state = state.copyWith(tab: tab);

  void setPeriod(String period) {
    state = state.copyWith(
      period: period,
      clearCustomStart: period != 'custom',
      clearCustomEnd: period != 'custom',
    );
  }

  void setCustomRange(String start, String end) {
    state = state.copyWith(
      period: 'custom',
      customStart: start,
      customEnd: end,
    );
  }

  void setComparisonPeriod(String period) =>
      state = state.copyWith(comparisonPeriod: period);
}

final reportsFilterProvider =
    NotifierProvider<ReportsFilterNotifier, ReportsFilterState>(
  ReportsFilterNotifier.new,
);

sealed class ReportFetchResult<T> {
  const ReportFetchResult();
}

final class ReportLoaded<T> extends ReportFetchResult<T> {
  const ReportLoaded(this.data);
  final T data;
}

final class ReportPlanGated<T> extends ReportFetchResult<T> {
  const ReportPlanGated(this.failure);
  final PlanLimitReachedFailure failure;
}

final pnlReportProvider =
    FutureProvider<ReportFetchResult<ProfitAndLossReportDto>>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final filter = ref.watch(reportsFilterProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  try {
    final data = await ref.read(reportsRepositoryProvider).getProfitAndLoss(
          period: filter.period,
          startDate: filter.customStart,
          endDate: filter.customEnd,
          cancelToken: cancelToken,
        );
    return ReportLoaded(data);
  } on PlanLimitReachedFailure catch (e) {
    return ReportPlanGated(e);
  }
});

final cashFlowReportProvider =
    FutureProvider<ReportFetchResult<CashFlowReportDto>>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final filter = ref.watch(reportsFilterProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  try {
    final data = await ref.read(reportsRepositoryProvider).getCashFlow(
          period: filter.period,
          startDate: filter.customStart,
          endDate: filter.customEnd,
          cancelToken: cancelToken,
        );
    return ReportLoaded(data);
  } on PlanLimitReachedFailure catch (e) {
    return ReportPlanGated(e);
  }
});

final comparisonReportProvider =
    FutureProvider<ReportFetchResult<ComparisonReportDto>>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final filter = ref.watch(reportsFilterProvider);
  final primary = filter.period == 'custom' ? 'this_month' : filter.period;
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  try {
    final data = await ref.read(reportsRepositoryProvider).getComparison(
          primaryPeriod: primary,
          comparisonPeriod: filter.comparisonPeriod,
          cancelToken: cancelToken,
        );
    return ReportLoaded(data);
  } on PlanLimitReachedFailure catch (e) {
    return ReportPlanGated(e);
  }
});
