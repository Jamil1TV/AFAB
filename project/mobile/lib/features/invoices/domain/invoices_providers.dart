import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/domain/customers_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class InvoicesFilterState {
  const InvoicesFilterState({
    this.status,
    this.search = '',
    this.customerId,
    this.page = 0,
  });

  final InvoiceStatus? status;
  final String search;
  final String? customerId;
  final int page;

  InvoicesFilterState copyWith({
    InvoiceStatus? status,
    bool clearStatus = false,
    String? search,
    String? customerId,
    bool clearCustomerId = false,
    int? page,
  }) {
    return InvoicesFilterState(
      status: clearStatus ? null : (status ?? this.status),
      search: search ?? this.search,
      customerId: clearCustomerId ? null : (customerId ?? this.customerId),
      page: page ?? this.page,
    );
  }
}

class InvoicesFilterNotifier extends Notifier<InvoicesFilterState> {
  @override
  InvoicesFilterState build() {
    ref.watch(activeBusinessIdProvider);
    return const InvoicesFilterState();
  }

  void setStatus(InvoiceStatus? status) => state = state.copyWith(
        status: status,
        clearStatus: status == null,
        page: 0,
      );

  void setSearch(String query) =>
      state = state.copyWith(search: query, page: 0);

  void setPage(int page) => state = state.copyWith(page: page);
}

final invoicesFilterProvider =
    NotifierProvider<InvoicesFilterNotifier, InvoicesFilterState>(
  InvoicesFilterNotifier.new,
);

final invoiceSummaryProvider = FutureProvider<InvoiceSummaryDto>((ref) async {
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
      .read(invoicesRepositoryProvider)
      .getSummary(cancelToken: cancelToken);
});

final invoicesListProvider = FutureProvider<InvoicePageDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final filter = ref.watch(invoicesFilterProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref.read(invoicesRepositoryProvider).listInvoices(
        customerId: filter.customerId,
        status: filter.status,
        search: filter.search,
        page: filter.page,
        size: 15,
        cancelToken: cancelToken,
      );
});

final invoiceDetailProvider = FutureProvider.autoDispose
    .family<InvoiceDto, String>((ref, id) async {
  ref.watch(activeBusinessIdProvider);
  return ref.read(invoicesRepositoryProvider).getInvoiceById(id);
});

class SelectedInvoiceIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(activeBusinessIdProvider);
    return null;
  }

  void select(String? id) => state = id;
}

final selectedInvoiceIdProvider =
    NotifierProvider<SelectedInvoiceIdNotifier, String?>(
  SelectedInvoiceIdNotifier.new,
);

/// Resolves an `UpcomingInvoiceItemDto` (`invoiceId` actually holds `invoiceNumber`)
/// into a real UUID either from loaded invoices or via `GET /invoices?search=<num>&size=1`.
Future<String?> resolveInvoiceUuidByNumber(
  WidgetRef ref,
  String invoiceNumberOrId,
) async {
  final loaded = ref.read(invoicesListProvider).value?.content ?? const [];
  for (final inv in loaded) {
    if (inv.id == invoiceNumberOrId || inv.invoiceNumber == invoiceNumberOrId) {
      return inv.id;
    }
  }
  final page = await ref.read(invoicesRepositoryProvider).listInvoices(
        search: invoiceNumberOrId,
        page: 0,
        size: 5,
      );
  final exact = page.content
      .where(
        (i) => i.invoiceNumber == invoiceNumberOrId || i.id == invoiceNumberOrId,
      )
      .firstOrNull;
  return exact?.id ?? page.content.firstOrNull?.id;
}

void invalidateInvoiceProviders(
  WidgetRef ref, {
  String? invoiceId,
  String? customerId,
  bool includeLedgers = false,
}) {
  ref.invalidate(invoicesListProvider);
  ref.invalidate(invoiceSummaryProvider);
  if (invoiceId != null && invoiceId.isNotEmpty) {
    ref.invalidate(invoiceDetailProvider(invoiceId));
  }
  if (customerId != null && customerId.isNotEmpty) {
    ref.invalidate(customerDetailProvider(customerId));
  }
  ref.invalidate(customersListProvider);
  ref.invalidate(customerSummaryProvider);
  if (includeLedgers) {
    ref.invalidate(transactionListProvider);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(revenueListProvider);
    ref.invalidate(revenueSummaryProvider);
    ref.invalidate(expenseSummaryProvider);
  }
}
