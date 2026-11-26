import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

@immutable
class CalendarMonth {
  const CalendarMonth({required this.year, required this.month});

  factory CalendarMonth.fromDateTime(DateTime dt) =>
      CalendarMonth(year: dt.year, month: dt.month);

  final int year;
  final int month;

  int get daysInMonth => DateUtils.getDaysInMonth(year, month);

  /// Leading empty slots before day 1 in a Sunday-first (Sun..Sat) grid.
  int get firstWeekdayOffset => DateTime.utc(year, month, 1).weekday % 7;

  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  String get firstDayIso => '$monthKey-01';

  String get lastDayIso => '$monthKey-${daysInMonth.toString().padLeft(2, '0')}';

  String dayIso(int day) => '$monthKey-${day.toString().padLeft(2, '0')}';

  CalendarMonth previous() => month == 1
      ? CalendarMonth(year: year - 1, month: 12)
      : CalendarMonth(year: year, month: month - 1);

  CalendarMonth next() => month == 12
      ? CalendarMonth(year: year + 1, month: 1)
      : CalendarMonth(year: year, month: month + 1);

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

@immutable
class CalendarDayMetrics {
  CalendarDayMetrics({
    required this.isoDate,
    this.transactions = const [],
    Decimal? completedIncome,
    Decimal? completedExpense,
    this.pendingCount = 0,
  })  : completedIncome = completedIncome ?? Decimal.zero,
        completedExpense = completedExpense ?? Decimal.zero;

  final String isoDate;
  final List<TransactionDto> transactions;
  final Decimal completedIncome;
  final Decimal completedExpense;
  final int pendingCount;
}

@immutable
class CalendarMonthSummary {
  const CalendarMonthSummary({
    required this.month,
    required this.transactions,
    required this.byDate,
    required this.monthlyInflow,
    required this.monthlyOutflow,
    required this.pendingCount,
    required this.totalCount,
    this.truncated = false,
  });

  final CalendarMonth month;
  final List<TransactionDto> transactions;
  final Map<String, CalendarDayMetrics> byDate;
  final Decimal monthlyInflow;
  final Decimal monthlyOutflow;
  final int pendingCount;
  final int totalCount;
  final bool truncated;
}

CalendarMonthSummary buildCalendarMonthSummary({
  required CalendarMonth month,
  required List<TransactionDto> transactions,
  bool truncated = false,
}) {
  final grouped = <String, List<TransactionDto>>{};
  var monthlyInflow = Decimal.zero;
  var monthlyOutflow = Decimal.zero;
  var pendingCount = 0;

  for (final tx in transactions) {
    final key = tx.transactionDate.length >= 10
        ? tx.transactionDate.substring(0, 10)
        : tx.transactionDate;
    grouped.putIfAbsent(key, () => []).add(tx);

    final baseAmount = tx.convertedAmount ?? tx.amount;
    if (tx.status == TransactionStatus.pending) {
      pendingCount++;
    } else if (tx.status == TransactionStatus.completed) {
      if (tx.type == TransactionType.income) {
        monthlyInflow += baseAmount;
      } else {
        monthlyOutflow += baseAmount;
      }
    }
  }

  final byDate = <String, CalendarDayMetrics>{};
  for (final entry in grouped.entries) {
    var dayIn = Decimal.zero;
    var dayOut = Decimal.zero;
    var dayPending = 0;
    for (final tx in entry.value) {
      final baseAmount = tx.convertedAmount ?? tx.amount;
      if (tx.status == TransactionStatus.pending) {
        dayPending++;
      } else if (tx.status == TransactionStatus.completed) {
        if (tx.type == TransactionType.income) {
          dayIn += baseAmount;
        } else {
          dayOut += baseAmount;
        }
      }
    }
    byDate[entry.key] = CalendarDayMetrics(
      isoDate: entry.key,
      transactions: entry.value,
      completedIncome: dayIn,
      completedExpense: dayOut,
      pendingCount: dayPending,
    );
  }

  return CalendarMonthSummary(
    month: month,
    transactions: transactions,
    byDate: byDate,
    monthlyInflow: monthlyInflow,
    monthlyOutflow: monthlyOutflow,
    pendingCount: pendingCount,
    totalCount: transactions.length,
    truncated: truncated,
  );
}
