import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class CustomersFilterState {
  const CustomersFilterState({
    this.period = 'month',
    this.search = '',
    this.status,
    this.group,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.page = 0,
  });

  final String period; // today | week | month | year
  final String search;
  final String? status;
  final String? group;
  final String sortBy; // createdAt | name | totalRevenue | ordersCount
  final String sortOrder; // asc | desc
  final int page;

  CustomersFilterState copyWith({
    String? period,
    String? search,
    String? status,
    bool clearStatus = false,
    String? group,
    bool clearGroup = false,
    String? sortBy,
    String? sortOrder,
    int? page,
  }) {
    return CustomersFilterState(
      period: period ?? this.period,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      group: clearGroup ? null : (group ?? this.group),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
    );
  }
}

class CustomersFilterNotifier extends Notifier<CustomersFilterState> {
  @override
  CustomersFilterState build() {
    ref.watch(activeBusinessIdProvider);
    return const CustomersFilterState();
  }

  void setPeriod(String period) => state = state.copyWith(period: period);
  void setSearch(String search) =>
      state = state.copyWith(search: search, page: 0);

  void setStatus(String? status) => state = state.copyWith(
        status: status,
        clearStatus: status == null || status.isEmpty,
        page: 0,
      );

  void setGroup(String? group) => state = state.copyWith(
        group: group,
        clearGroup: group == null || group.isEmpty,
        page: 0,
      );

  void setSort(String sortBy) {
    if (state.sortBy == sortBy) {
      state = state.copyWith(
        sortOrder: state.sortOrder == 'desc' ? 'asc' : 'desc',
        page: 0,
      );
    } else {
      state = state.copyWith(
        sortBy: sortBy,
        sortOrder: sortBy == 'name' ? 'asc' : 'desc',
        page: 0,
      );
    }
  }

  void setPage(int page) => state = state.copyWith(page: page);
}

final customersFilterProvider =
    NotifierProvider<CustomersFilterNotifier, CustomersFilterState>(
  CustomersFilterNotifier.new,
);

final customerSummaryProvider = FutureProvider<CustomerSummaryDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final period = ref.watch(customersFilterProvider.select((f) => f.period));
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref
      .read(customersRepositoryProvider)
      .getSummary(period: period, cancelToken: cancelToken);
});

final customersListProvider = FutureProvider<CustomerPageDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final filter = ref.watch(customersFilterProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  return ref.read(customersRepositoryProvider).listCustomers(
        search: filter.search,
        status: filter.status,
        group: filter.group,
        page: filter.page,
        size: 15,
        sortBy: filter.sortBy,
        sortOrder: filter.sortOrder,
        cancelToken: cancelToken,
      );
});

final customerDetailProvider = FutureProvider.autoDispose
    .family<CustomerDto, String>((ref, id) async {
  ref.watch(activeBusinessIdProvider);
  return ref.read(customersRepositoryProvider).getCustomerById(id);
});

class SelectedCustomerIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(activeBusinessIdProvider);
    return null;
  }

  void select(String? id) => state = id;
}

final selectedCustomerIdProvider =
    NotifierProvider<SelectedCustomerIdNotifier, String?>(
  SelectedCustomerIdNotifier.new,
);

void invalidateCustomerProviders(WidgetRef ref, {String? customerId}) {
  ref.invalidate(customersListProvider);
  ref.invalidate(customerSummaryProvider);
  ref.invalidate(dashboardSummaryProvider);
  if (customerId != null && customerId.isNotEmpty) {
    ref.invalidate(customerDetailProvider(customerId));
  }
}
