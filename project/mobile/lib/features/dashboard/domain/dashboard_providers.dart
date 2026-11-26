import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPeriodNotifier extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() => DashboardPeriod.month;

  void select(DashboardPeriod period) => state = period;
}

final dashboardPeriodProvider =
    NotifierProvider<DashboardPeriodNotifier, DashboardPeriod>(
  DashboardPeriodNotifier.new,
);

final dashboardSummaryProvider =
    FutureProvider<DashboardSummaryDto>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    throw StateError('Unauthenticated');
  }
  ref.watch(activeBusinessIdProvider);
  final period = ref.watch(dashboardPeriodProvider);
  return ref.read(dashboardRepositoryProvider).getSummary(period);
});

final aiPulseProvider = FutureProvider<AiPulseDto?>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    return null;
  }
  ref.watch(activeBusinessIdProvider);
  try {
    return await ref.read(dashboardRepositoryProvider).getAiPulse();
  } catch (_) {
    // Gracefully fall back to summary insights if AI / Ollama is offline.
    return null;
  }
});

final subscriptionSnapshotProvider =
    FutureProvider<SubscriptionSnapshotDto?>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    return null;
  }
  try {
    return await ref.read(dashboardRepositoryProvider).getMySubscription();
  } catch (_) {
    return null;
  }
});
