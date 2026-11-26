import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveBusinessIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final session = ref.watch(authNotifierProvider);
    final stored = ref.read(prefsStoreProvider).getActiveBusinessId();
    final id = (stored != null && stored.isNotEmpty)
        ? stored
        : session.user?.businessId;
    ref.read(activeBusinessHolderProvider).setBusinessId(id);
    return id;
  }

  Future<void> setBusinessId(String? id) async {
    ref.read(activeBusinessHolderProvider).setBusinessId(id);
    await ref.read(prefsStoreProvider).setActiveBusinessId(id);
    state = id;
  }
}

final activeBusinessIdProvider =
    NotifierProvider<ActiveBusinessIdNotifier, String?>(
  ActiveBusinessIdNotifier.new,
);

final businessListProvider = FutureProvider<List<BusinessDto>>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    return const [];
  }
  final businesses = await ref.read(businessRepositoryProvider).listBusinesses();
  if (businesses.isNotEmpty) {
    final currentId = ref.read(activeBusinessIdProvider);
    final activeMatch = businesses.where((b) => b.id == currentId).firstOrNull;
    if (activeMatch == null || activeMatch.isReadOnly) {
      final fallback = businesses.where((b) => !b.isReadOnly).firstOrNull;
      if (fallback != null && fallback.id != currentId) {
        Future.microtask(
          () => ref
              .read(activeBusinessIdProvider.notifier)
              .setBusinessId(fallback.id),
        );
      }
    }
  }
  return businesses;
});

final activeBusinessProvider = Provider<BusinessDto?>((ref) {
  final list = ref.watch(businessListProvider).value ?? const [];
  if (list.isEmpty) return null;
  final activeId = ref.watch(activeBusinessIdProvider);
  return list.where((b) => b.id == activeId).firstOrNull ??
      list.where((b) => b.active).firstOrNull ??
      list.first;
});
