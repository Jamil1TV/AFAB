import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/data/category_repository.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryListNotifier extends AsyncNotifier<List<CategoryDto>> {
  @override
  Future<List<CategoryDto>> build() async {
    final session = ref.watch(authNotifierProvider);
    if (!session.isAuthenticated ||
        session.needsEmailVerification ||
        session.needsOnboarding) {
      return const [];
    }
    ref.watch(activeBusinessIdProvider);
    return ref.read(categoryRepositoryProvider).getCategories();
  }

  Future<CategoryDto> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final created = await ref.read(categoryRepositoryProvider).createCategory(
          name: name,
          type: type,
          icon: icon,
          color: color,
        );
    final current = state.value ?? const [];
    state = AsyncValue.data([...current, created]);
    _invalidateDependents();
    return created;
  }

  Future<CategoryDto> updateCategory({
    required String id,
    required String name,
    String? icon,
    String? color,
  }) async {
    final updated = await ref.read(categoryRepositoryProvider).updateCategory(
          id: id,
          name: name,
          icon: icon,
          color: color,
        );
    final current = state.value ?? const [];
    state = AsyncValue.data([
      for (final c in current)
        if (c.id == id) updated else c,
    ]);
    _invalidateDependents();
    return updated;
  }

  Future<void> deleteCategory(String id) async {
    await ref.read(categoryRepositoryProvider).deleteCategory(id);
    final current = state.value ?? const [];
    state = AsyncValue.data(current.where((c) => c.id != id).toList());
    _invalidateDependents();
  }

  void _invalidateDependents() {
    ref.invalidate(transactionListProvider);
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(expenseSummaryProvider);
    ref.invalidate(expenseListProvider);
    ref.invalidate(revenueSummaryProvider);
    ref.invalidate(revenueListProvider);
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<CategoryDto>>(
  CategoryListNotifier.new,
);

final expenseCategoriesProvider = Provider<List<CategoryDto>>((ref) {
  final all = ref.watch(categoryListProvider).value ?? const [];
  return all.where((c) => c.isExpense).toList();
});

final incomeCategoriesProvider = Provider<List<CategoryDto>>((ref) {
  final all = ref.watch(categoryListProvider).value ?? const [];
  return all.where((c) => c.isIncome).toList();
});
