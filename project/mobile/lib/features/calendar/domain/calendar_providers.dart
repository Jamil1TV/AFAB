import 'dart:math';

import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/calendar/domain/calendar_helpers.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:afab_mobile/features/recurring/data/recurring_repository.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class CalendarOverlaySettings {
  const CalendarOverlaySettings({
    this.showInvoicesDue = false,
    this.showRecurringRuns = false,
  });

  final bool showInvoicesDue;
  final bool showRecurringRuns;

  bool get anyOptionalActive => showInvoicesDue || showRecurringRuns;

  CalendarOverlaySettings copyWith({
    bool? showInvoicesDue,
    bool? showRecurringRuns,
  }) {
    return CalendarOverlaySettings(
      showInvoicesDue: showInvoicesDue ?? this.showInvoicesDue,
      showRecurringRuns: showRecurringRuns ?? this.showRecurringRuns,
    );
  }
}

class VisibleCalendarMonthNotifier extends Notifier<CalendarMonth> {
  @override
  CalendarMonth build() {
    ref.watch(activeBusinessIdProvider);
    return CalendarMonth.fromDateTime(DateTime.now());
  }

  void setMonth(CalendarMonth month) => state = month;
  void previousMonth() => state = state.previous();
  void nextMonth() => state = state.next();
  void jumpToToday() => state = CalendarMonth.fromDateTime(DateTime.now());
}

final visibleCalendarMonthProvider =
    NotifierProvider<VisibleCalendarMonthNotifier, CalendarMonth>(
  VisibleCalendarMonthNotifier.new,
);

class SelectedCalendarDateNotifier extends Notifier<String> {
  @override
  String build() {
    ref.watch(activeBusinessIdProvider);
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void select(String isoDate) => state = isoDate;
}

final selectedCalendarDateProvider =
    NotifierProvider<SelectedCalendarDateNotifier, String>(
  SelectedCalendarDateNotifier.new,
);

class CalendarOverlaysNotifier extends Notifier<CalendarOverlaySettings> {
  @override
  CalendarOverlaySettings build() {
    ref.watch(activeBusinessIdProvider);
    return const CalendarOverlaySettings();
  }

  void toggleInvoicesDue() =>
      state = state.copyWith(showInvoicesDue: !state.showInvoicesDue);

  void toggleRecurringRuns() =>
      state = state.copyWith(showRecurringRuns: !state.showRecurringRuns);
}

final calendarOverlaysProvider =
    NotifierProvider<CalendarOverlaysNotifier, CalendarOverlaySettings>(
  CalendarOverlaysNotifier.new,
);

/// Fetches all transactions for the exact `startDate`..`endDate` window of
/// `month`, automatically looping pages (up to 10 pages / 1,000 rows).
final calendarMonthTransactionsProvider = FutureProvider.autoDispose
    .family<CalendarMonthSummary, CalendarMonth>((ref, month) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);

  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final repo = ref.read(transactionRepositoryProvider);
  final firstPage = await repo.getTransactions(
    startDate: month.firstDayIso,
    endDate: month.lastDayIso,
    page: 0,
    size: 100,
    cancelToken: cancelToken,
  );

  final all = <TransactionDto>[...firstPage.content];
  final truncated = firstPage.totalElements > 1000;
  final extraPages = min(firstPage.totalPages - 1, 9);
  if (extraPages > 0) {
    final rest = await Future.wait([
      for (var p = 1; p <= extraPages; p++)
        repo.getTransactions(
          startDate: month.firstDayIso,
          endDate: month.lastDayIso,
          page: p,
          size: 100,
          cancelToken: cancelToken,
        ),
    ]);
    for (final page in rest) {
      all.addAll(page.content);
    }
  }

  return buildCalendarMonthSummary(
    month: month,
    transactions: all,
    truncated: truncated,
  );
});

/// Lazily loads open invoices for the optional calendar due-date overlay.
final calendarDueInvoicesProvider =
    FutureProvider.autoDispose<List<InvoiceDto>>((ref) async {
  final show = ref.watch(
    calendarOverlaysProvider.select((s) => s.showInvoicesDue),
  );
  if (!show) return const [];
  ref.watch(activeBusinessIdProvider);

  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final page = await ref.read(invoicesRepositoryProvider).listInvoices(
        page: 0,
        size: 100,
        cancelToken: cancelToken,
      );
  return page.content
      .where(
        (i) =>
            i.status != InvoiceStatus.paid &&
            i.status != InvoiceStatus.cancelled &&
            i.status != InvoiceStatus.draft,
      )
      .toList();
});

/// Lazily loads active recurring rules for the optional calendar schedule overlay.
final calendarRecurringRunsProvider =
    FutureProvider.autoDispose<List<RecurringTransactionDto>>((ref) async {
  final show = ref.watch(
    calendarOverlaysProvider.select((s) => s.showRecurringRuns),
  );
  if (!show) return const [];
  ref.watch(activeBusinessIdProvider);

  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  final rules = await ref
      .read(recurringRepositoryProvider)
      .listRules(cancelToken: cancelToken);
  return rules.where((r) => r.active).toList();
});
