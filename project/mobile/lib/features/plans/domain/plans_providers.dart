import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:afab_mobile/features/plans/data/plans_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final businessAllocationProvider =
    FutureProvider<BusinessAllocationDto?>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    return null;
  }
  return ref.read(businessRepositoryProvider).getAllocations();
});

final billingHistoryProvider =
    FutureProvider<BillingHistoryResponseDto?>((ref) async {
  final session = ref.watch(authNotifierProvider);
  if (!session.isAuthenticated ||
      session.needsEmailVerification ||
      session.needsOnboarding) {
    return null;
  }
  return ref.read(plansRepositoryProvider).getBillingHistory();
});

@immutable
class PlansUiState {
  const PlansUiState({
    this.billingInterval = 'monthly',
    this.intervalSyncedFromSub = false,
    this.showPlanCardsOverride = false,
    this.submittingAction,
    this.verifyingCheckout = false,
    this.pendingExternalBillingReturn = false,
  });

  final String billingInterval;
  final bool intervalSyncedFromSub;
  final bool showPlanCardsOverride;
  final String? submittingAction;
  final bool verifyingCheckout;
  final bool pendingExternalBillingReturn;

  bool get isBusy => submittingAction != null || verifyingCheckout;

  PlansUiState copyWith({
    String? billingInterval,
    bool? intervalSyncedFromSub,
    bool? showPlanCardsOverride,
    String? submittingAction,
    bool clearSubmitting = false,
    bool? verifyingCheckout,
    bool? pendingExternalBillingReturn,
  }) {
    return PlansUiState(
      billingInterval: billingInterval ?? this.billingInterval,
      intervalSyncedFromSub:
          intervalSyncedFromSub ?? this.intervalSyncedFromSub,
      showPlanCardsOverride:
          showPlanCardsOverride ?? this.showPlanCardsOverride,
      submittingAction:
          clearSubmitting ? null : (submittingAction ?? this.submittingAction),
      verifyingCheckout: verifyingCheckout ?? this.verifyingCheckout,
      pendingExternalBillingReturn:
          pendingExternalBillingReturn ?? this.pendingExternalBillingReturn,
    );
  }
}

class PlansUiController extends Notifier<PlansUiState> {
  @override
  PlansUiState build() => const PlansUiState();

  void syncIntervalFromSubscription(String interval) {
    if (state.intervalSyncedFromSub) return;
    final norm = interval.toLowerCase() == 'yearly' ? 'yearly' : 'monthly';
    state = state.copyWith(billingInterval: norm, intervalSyncedFromSub: true);
  }

  void setBillingInterval(String interval) {
    state = state.copyWith(
      billingInterval: interval == 'yearly' ? 'yearly' : 'monthly',
      intervalSyncedFromSub: true,
    );
  }

  void setShowPlanCardsOverride(bool show) {
    state = state.copyWith(showPlanCardsOverride: show);
  }

  void togglePlanCardsOverride() {
    state = state.copyWith(showPlanCardsOverride: !state.showPlanCardsOverride);
  }

  void setSubmittingAction(String? action) {
    state = state.copyWith(
      submittingAction: action,
      clearSubmitting: action == null,
    );
  }

  void setVerifyingCheckout(bool verifying) {
    state = state.copyWith(verifyingCheckout: verifying);
  }

  void setPendingExternalBillingReturn(bool pending) {
    state = state.copyWith(pendingExternalBillingReturn: pending);
  }
}

final plansUiControllerProvider =
    NotifierProvider<PlansUiController, PlansUiState>(PlansUiController.new);

Future<void> refreshAllBillingData(WidgetRef ref) async {
  ref.invalidate(subscriptionSnapshotProvider);
  ref.invalidate(businessAllocationProvider);
  ref.invalidate(billingHistoryProvider);
  ref.invalidate(businessListProvider);
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(aiStatusProvider);
  try {
    await ref.read(authNotifierProvider.notifier).refreshProfile();
  } catch (_) {
    // Non-fatal: billing providers already invalidated.
  }
}

Future<void> ensureEditableActiveBusinessIfNeeded(
  WidgetRef ref,
  List<String> selectedEditableIds,
) async {
  if (selectedEditableIds.isEmpty) return;
  final currentId = ref.read(activeBusinessIdProvider);
  if (currentId == null || !selectedEditableIds.contains(currentId)) {
    final targetId = selectedEditableIds.first;
    try {
      await ref.read(businessRepositoryProvider).switchBusiness(targetId);
    } catch (_) {
      // Fallback to local selection if backend switch was implicit.
    }
    await ref.read(activeBusinessIdProvider.notifier).setBusinessId(targetId);
  }
}
