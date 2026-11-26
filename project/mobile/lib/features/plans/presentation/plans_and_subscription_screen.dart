import 'dart:async';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/connectivity_provider.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/plans/data/plan_catalog.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:afab_mobile/features/plans/data/plans_repository.dart';
import 'package:afab_mobile/features/plans/domain/plans_providers.dart';
import 'package:afab_mobile/features/plans/presentation/widgets/business_allocation_sheet.dart';
import 'package:afab_mobile/features/plans/presentation/widgets/cancel_subscription_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `PLAN-01`: Plans, Entitlements, Allocation & Stripe Billing Hub.
class PlansAndSubscriptionScreen extends ConsumerStatefulWidget {
  const PlansAndSubscriptionScreen({
    super.key,
    this.checkoutStatus,
    this.sessionId,
    this.changePlan = false,
  });

  final String? checkoutStatus;
  final String? sessionId;
  final bool changePlan;

  @override
  ConsumerState<PlansAndSubscriptionScreen> createState() =>
      _PlansAndSubscriptionScreenState();
}

class _PlansAndSubscriptionScreenState
    extends ConsumerState<PlansAndSubscriptionScreen>
    with WidgetsBindingObserver {
  String? _handledDeepLinkKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLinkParams());
  }

  @override
  void didUpdateWidget(covariant PlansAndSubscriptionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checkoutStatus != oldWidget.checkoutStatus ||
        widget.sessionId != oldWidget.sessionId ||
        widget.changePlan != oldWidget.changePlan) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLinkParams());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final ui = ref.read(plansUiControllerProvider);
      if (ui.pendingExternalBillingReturn) {
        ref
            .read(plansUiControllerProvider.notifier)
            .setPendingExternalBillingReturn(false);
        refreshAllBillingData(ref);
      }
    }
  }

  Future<void> _handleDeepLinkParams() async {
    if (!mounted) return;
    final key =
        '${widget.checkoutStatus ?? ''}:${widget.sessionId ?? ''}:${widget.changePlan}';
    if (_handledDeepLinkKey == key) return;
    _handledDeepLinkKey = key;

    final uiCtrl = ref.read(plansUiControllerProvider.notifier);
    if (widget.changePlan) {
      uiCtrl.setShowPlanCardsOverride(true);
    }

    if (widget.checkoutStatus == 'canceled') {
      AfabToast.showInfo(context, context.l10n.plansCheckoutCanceled);
      return;
    }

    if (widget.checkoutStatus == 'success' &&
        widget.sessionId != null &&
        widget.sessionId!.isNotEmpty) {
      uiCtrl.setVerifyingCheckout(true);
      try {
        final verified = await ref
            .read(plansRepositoryProvider)
            .verifyCheckout(widget.sessionId!);
        await refreshAllBillingData(ref);
        if (mounted) {
          AfabToast.showSuccess(
            context,
            context.l10n.plansCheckoutVerified(verified.planName),
          );
        }
      } on AppFailure catch (e) {
        if (mounted) AfabToast.showError(context, e.message);
      } finally {
        if (mounted) uiCtrl.setVerifyingCheckout(false);
      }
    }
  }

  Future<void> _launchBillingUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    ref
        .read(plansUiControllerProvider.notifier)
        .setPendingExternalBillingReturn(true);
    final launched = await ref.read(billingUrlLauncherProvider).launchExternal(uri);
    if (!launched && mounted) {
      ref
          .read(plansUiControllerProvider.notifier)
          .setPendingExternalBillingReturn(false);
      AfabToast.showError(context, context.l10n.plansBillingNotConfigured);
    }
  }

  Future<void> _handleUpgradeOrCheckout({
    required SubscriptionSnapshotDto snapshot,
    required String targetSlug,
  }) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final ui = ref.read(plansUiControllerProvider);
    final uiCtrl = ref.read(plansUiControllerProvider.notifier);
    uiCtrl.setSubmittingAction(targetSlug);

    try {
      if (snapshot.hasActiveStripeSubscription) {
        final res = await ref.read(plansRepositoryProvider).upgradeSubscription(
              planSlug: targetSlug,
              billingInterval: ui.billingInterval,
              locale: locale,
            );
        if (res.mode == 'DIRECT_UPGRADE') {
          await refreshAllBillingData(ref);
          if (mounted) {
            final targetName =
                res.snapshotJson?['planName']?.toString() ?? targetSlug.toUpperCase();
            AfabToast.showSuccess(
              context,
              l10n.plansDirectUpgradeSuccess(targetName),
            );
          }
        } else if (res.url != null && res.url!.isNotEmpty) {
          await _launchBillingUrl(res.url!);
        }
      } else {
        final res = await ref.read(plansRepositoryProvider).createCheckout(
              planSlug: targetSlug,
              billingInterval: ui.billingInterval,
              locale: locale,
            );
        if (res.url != null && res.url!.isNotEmpty) {
          await _launchBillingUrl(res.url!);
        }
      }
    } on AppFailure catch (e) {
      if (mounted) {
        final msg = e.statusCode == 503
            ? l10n.plansBillingNotConfigured
            : e.message;
        AfabToast.showError(context, msg);
      }
    } finally {
      if (mounted) uiCtrl.setSubmittingAction(null);
    }
  }

  Future<void> _handleOpenPortal() async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final uiCtrl = ref.read(plansUiControllerProvider.notifier);
    uiCtrl.setSubmittingAction('portal');
    try {
      final res =
          await ref.read(plansRepositoryProvider).createPortal(locale: locale);
      if (res.url.isNotEmpty) {
        await _launchBillingUrl(res.url);
      }
    } on AppFailure catch (e) {
      if (mounted) {
        AfabToast.showError(
          context,
          e.statusCode == 503 ? l10n.plansBillingNotConfigured : e.message,
        );
      }
    } finally {
      if (mounted) uiCtrl.setSubmittingAction(null);
    }
  }

  Future<void> _handleResume() async {
    final uiCtrl = ref.read(plansUiControllerProvider.notifier);
    uiCtrl.setSubmittingAction('resume');
    try {
      await ref.read(plansRepositoryProvider).resumeSubscription();
      await refreshAllBillingData(ref);
      if (mounted) {
        AfabToast.showSuccess(context, context.l10n.plansResumedSuccess);
      }
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) uiCtrl.setSubmittingAction(null);
    }
  }

  Future<void> _handlePlanSelection({
    required SubscriptionSnapshotDto snapshot,
    required BusinessAllocationDto? allocation,
    required PlanTierDefinition tier,
  }) async {
    final currentSlug = snapshot.planSlug.toLowerCase();
    final targetSlug = tier.slug.toLowerCase();
    if (currentSlug == targetSlug) return;

    final rank = {'free': 0, 'plus': 1, 'pro': 2};
    final currentRank = rank[currentSlug] ?? 0;
    final targetRank = rank[targetSlug] ?? 0;

    if (targetRank > currentRank) {
      await _handleUpgradeOrCheckout(
        snapshot: snapshot,
        targetSlug: targetSlug,
      );
      return;
    }

    final owned = allocation?.businesses ?? const <BusinessAllocationItemDto>[];
    if (targetSlug == 'free') {
      await showCancelSubscriptionSheet(
        context,
        snapshot: snapshot,
        businesses: owned,
      );
      return;
    }

    final ui = ref.read(plansUiControllerProvider);
    if (owned.length > tier.editableBusinessLimit) {
      await showBusinessAllocationSheet(
        context,
        mode: BusinessAllocationMode.downgrade,
        businesses: owned,
        maxAllowed: tier.editableBusinessLimit,
        targetPlanSlug: targetSlug,
        targetPlanName: tier.name,
        billingInterval: ui.billingInterval,
      );
    } else {
      final uiCtrl = ref.read(plansUiControllerProvider.notifier);
      uiCtrl.setSubmittingAction(targetSlug);
      try {
        final updated =
            await ref.read(plansRepositoryProvider).scheduleDowngrade(
                  targetPlanSlug: targetSlug,
                  billingInterval: ui.billingInterval,
                  selectedBusinessIds: owned.map((b) => b.id).toList(),
                );
        await refreshAllBillingData(ref);
        if (mounted) {
          final isImmediate = updated.planSlug.toLowerCase() == targetSlug;
          AfabToast.showSuccess(
            context,
            isImmediate
                ? context.l10n.plansImmediateDowngradeSuccess(tier.name)
                : context.l10n.plansScheduledDowngradeSuccess(tier.name),
          );
        }
      } on AppFailure catch (e) {
        if (mounted) AfabToast.showError(context, e.message);
      } finally {
        if (mounted) uiCtrl.setSubmittingAction(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';
    final isOnline = ref.watch(isOnlineProvider);

    final subAsync = ref.watch(subscriptionSnapshotProvider);
    final allocAsync = ref.watch(businessAllocationProvider);
    final historyAsync = ref.watch(billingHistoryProvider);
    final ui = ref.watch(plansUiControllerProvider);

    final snapshot = subAsync.value;
    if (snapshot != null && !ui.intervalSyncedFromSub) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(plansUiControllerProvider.notifier)
              .syncIntervalFromSubscription(snapshot.billingInterval);
        }
      });
    }

    if (subAsync.isLoading && snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.plansPageTitle)),
        body: Center(child: AfabLoader(size: 56, label: l10n.plansLoading)),
      );
    }

    if (subAsync.hasError && snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.plansPageTitle)),
        body: AfabErrorState(
          title: l10n.errorGenericTitle,
          message: subAsync.error.toString(),
          retryLabel: l10n.commonRetry,
          onRetry: () => refreshAllBillingData(ref),
        ),
      );
    }

    final sub = snapshot ??
        const SubscriptionSnapshotDto(
          planSlug: 'free',
          planName: 'Free',
          status: 'ACTIVE',
          isTrial: false,
          allocationAttentionRequired: false,
          editableBusinessLimit: 1,
          editableBusinessCount: 1,
          totalBusinessCount: 1,
        );
    final allocation = allocAsync.value;
    final history = historyAsync.value ?? const BillingHistoryResponseDto();
    final owned = allocation?.businesses ?? const <BusinessAllocationItemDto>[];
    final tiers = PlanCatalog.tiers(isAr);
    final compareRows = PlanCatalog.comparisonRows(isAr);
    final shouldShowPlanCards =
        !sub.hasActivePaidSubscription || ui.showPlanCardsOverride;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plansPageTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonReload,
            icon: const Icon(LucideIcons.refreshCw, size: 19),
            onPressed: () => refreshAllBillingData(ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => refreshAllBillingData(ref),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Header + Active Businesses Pill
                          _HeaderSection(
                            sub: sub,
                            editableCount: allocation?.editableCount ??
                                sub.editableBusinessCount,
                            editableLimit: allocation?.editableLimit ??
                                sub.editableBusinessLimit,
                          ),
                          const SizedBox(height: 16),

                          // 2. Current Subscription Overview Card
                          _CurrentSubscriptionCard(
                            sub: sub,
                            allocation: allocation,
                            owned: owned,
                            isOnline: isOnline,
                            ui: ui,
                            locale: locale,
                            onUpgradeToPro: () => _handleUpgradeOrCheckout(
                              snapshot: sub,
                              targetSlug: 'pro',
                            ),
                            onTogglePlanCards: () => ref
                                .read(plansUiControllerProvider.notifier)
                                .togglePlanCardsOverride(),
                            onResume: _handleResume,
                            onOpenPortal: _handleOpenPortal,
                            onOpenCancel: () => showCancelSubscriptionSheet(
                              context,
                              snapshot: sub,
                              businesses: owned,
                            ),
                            onOpenPendingAllocation: () {
                              if (allocation == null) return;
                              showBusinessAllocationSheet(
                                context,
                                mode: BusinessAllocationMode.pendingEdit,
                                businesses: owned,
                                maxAllowed:
                                    allocation.pendingEditableLimit ?? 1,
                                targetPlanSlug:
                                    allocation.pendingPlanSlug ?? 'free',
                                targetPlanName:
                                    allocation.pendingPlanName ?? 'Free',
                                initialSelectedIds:
                                    allocation.pendingBusinessIds,
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3. Owned Businesses Allocation Summary
                          if (owned.isNotEmpty) ...[
                            _OwnedBusinessesCard(
                              owned: owned,
                              isOnline: isOnline,
                              limit: allocation?.editableLimit ??
                                  sub.editableBusinessLimit,
                              maxWidth: width,
                              onManage: () => showBusinessAllocationSheet(
                                context,
                                mode: BusinessAllocationMode.manage,
                                businesses: owned,
                                maxAllowed: allocation?.editableLimit ??
                                    sub.editableBusinessLimit,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 4. Billing Toggle, Trial Banner & Plan Cards
                          if (shouldShowPlanCards) ...[
                            _BillingToggleAndTrial(
                              sub: sub,
                              billingInterval: ui.billingInterval,
                              onChanged: (v) => ref
                                  .read(plansUiControllerProvider.notifier)
                                  .setBillingInterval(v),
                            ),
                            const SizedBox(height: 16),
                            _PlanCardsGrid(
                              width: width,
                              tiers: tiers,
                              sub: sub,
                              billingInterval: ui.billingInterval,
                              isOnline: isOnline,
                              submittingAction: ui.submittingAction,
                              onSelectTier: (tier) => _handlePlanSelection(
                                snapshot: sub,
                                allocation: allocation,
                                tier: tier,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 5. Compare Plans Matrix (11 Rows)
                          _ComparePlansSection(
                            width: width,
                            rows: compareRows,
                          ),
                          const SizedBox(height: 20),

                          // 6. Subscription & Payment History
                          if (history.subscriptionHistory.isNotEmpty ||
                              history.paymentHistory.isNotEmpty)
                            _HistorySection(
                              width: width,
                              history: history,
                              locale: locale,
                              onOpenInvoiceUrl: _launchBillingUrl,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Full-screen verify overlay
          if (ui.verifyingCheckout)
            Positioned.fill(
              child: Container(
                color: colors.background.withValues(alpha: 0.78),
                alignment: Alignment.center,
                child: AfabCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AfabLoader(size: 56),
                      const SizedBox(height: 14),
                      Text(
                        l10n.plansCheckoutVerifying,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.sub,
    required this.editableCount,
    required this.editableLimit,
  });

  final SubscriptionSnapshotDto sub;
  final int editableCount;
  final int editableLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            l10n.plansHeaderManage,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        AfabCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.building2, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.plansActiveBusinesses(editableCount, editableLimit),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      l10n.plansActiveBusinessesHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrentSubscriptionCard extends StatelessWidget {
  const _CurrentSubscriptionCard({
    required this.sub,
    required this.allocation,
    required this.owned,
    required this.isOnline,
    required this.ui,
    required this.locale,
    required this.onUpgradeToPro,
    required this.onTogglePlanCards,
    required this.onResume,
    required this.onOpenPortal,
    required this.onOpenCancel,
    required this.onOpenPendingAllocation,
  });

  final SubscriptionSnapshotDto sub;
  final BusinessAllocationDto? allocation;
  final List<BusinessAllocationItemDto> owned;
  final bool isOnline;
  final PlansUiState ui;
  final String locale;
  final VoidCallback onUpgradeToPro;
  final VoidCallback onTogglePlanCards;
  final VoidCallback onResume;
  final VoidCallback onOpenPortal;
  final VoidCallback onOpenCancel;
  final VoidCallback onOpenPendingAllocation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    final statusUpper = sub.status.toUpperCase();
    final (statusLabel, statusVariant) = switch (statusUpper) {
      'TRIALING' => (l10n.plansStatusTrialing, AfabBadgeVariant.primary),
      'PAST_DUE' => (l10n.plansStatusPastDue, AfabBadgeVariant.danger),
      'CANCELED' || 'EXPIRED' => (
          l10n.plansStatusCanceled,
          AfabBadgeVariant.neutral,
        ),
      _ => (l10n.plansStatusActive, AfabBadgeVariant.success),
    };

    final endDt = sub.effectiveEndDate;
    final endDateStr = endDt != null
        ? AfabDateFormatter.formatDateTime(endDt, locale: locale)
        : '';

    final tokensLimit = sub.aiTokensLimit;
    final tokensUsed = sub.aiTokensUsed;
    final queriesLimit = sub.aiQueriesLimit;
    final queriesUsed = sub.aiQueriesUsed;
    final isUnlimited = tokensLimit < 0 || sub.isPro;
    final tokenRatio =
        isUnlimited || tokensLimit <= 0 ? 0.1 : (tokensUsed / tokensLimit).clamp(0.0, 1.0);
    final meterColor = tokenRatio >= 0.90
        ? colors.danger
        : (tokenRatio >= 0.75 ? colors.warning : colors.primary);
    final tokenLimitLabel = isUnlimited ? '∞' : '$tokensLimit';
    final queryLimitLabel = queriesLimit < 0 || sub.isPro ? '∞' : '$queriesLimit';

    return AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.creditCard,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.plansCurrentPlanLabel(sub.planName),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AfabStatusBadge(
                          label: statusLabel,
                          variant: statusVariant,
                        ),
                        if (sub.hasActivePaidSubscription)
                          AfabStatusBadge(
                            label: sub.billingInterval == 'yearly'
                                ? l10n.plansIntervalYearly
                                : l10n.plansIntervalMonthly,
                            variant: AfabBadgeVariant.neutral,
                          ),
                        if (sub.cancelAtPeriodEnd)
                          AfabStatusBadge(
                            label: l10n.plansScheduledCancelBadge,
                            variant: AfabBadgeVariant.warning,
                          )
                        else if (sub.pendingPlanSlug != null &&
                            sub.pendingPlanSlug!.isNotEmpty)
                          AfabStatusBadge(
                            label: l10n.plansScheduledDowngradeBadge(
                              sub.pendingPlanName ??
                                  sub.pendingPlanSlug!.toUpperCase(),
                            ),
                            variant: AfabBadgeVariant.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sub.isTrialActive && sub.trialDaysRemaining != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.plansTrialCountdown(sub.trialDaysRemaining!, endDateStr),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ] else if (endDateStr.isNotEmpty && sub.hasActivePaidSubscription) ...[
            const SizedBox(height: 10),
            Text(
              sub.hasPendingChange
                  ? l10n.plansEndsOn(endDateStr)
                  : l10n.plansRenewsOn(endDateStr),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          // Action Buttons Wrap
          if (sub.hasActivePaidSubscription ||
              sub.hasPendingChange ||
              sub.hasStripeCustomer) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                if (sub.isPlus && sub.hasActivePaidSubscription) ...[
                  AfabButton(
                    label: l10n.plansUpgradeToPro,
                    icon: LucideIcons.sparkles,
                    variant: AfabButtonVariant.premium,
                    compact: true,
                    isLoading: ui.submittingAction == 'pro',
                    onPressed:
                        (!isOnline || ui.isBusy) ? null : onUpgradeToPro,
                  ),
                  AfabButton(
                    label: ui.showPlanCardsOverride
                        ? l10n.plansHideOptions
                        : l10n.plansChangePlan,
                    variant: AfabButtonVariant.secondary,
                    compact: true,
                    onPressed: onTogglePlanCards,
                  ),
                ],
                if (sub.isPro && sub.hasActivePaidSubscription)
                  AfabButton(
                    label: ui.showPlanCardsOverride
                        ? l10n.plansHideOptions
                        : l10n.plansChangePlan,
                    variant: AfabButtonVariant.secondary,
                    compact: true,
                    onPressed: onTogglePlanCards,
                  ),
                if (sub.hasPendingChange)
                  AfabButton(
                    label: sub.cancelAtPeriodEnd
                        ? l10n.plansKeepResume
                        : l10n.plansCancelScheduledDowngrade,
                    variant: AfabButtonVariant.primary,
                    compact: true,
                    isLoading: ui.submittingAction == 'resume',
                    onPressed: (!isOnline || ui.isBusy) ? null : onResume,
                  ),
                if (sub.hasStripeCustomer)
                  AfabButton(
                    label: l10n.plansManageBilling,
                    icon: LucideIcons.externalLink,
                    variant: AfabButtonVariant.secondary,
                    compact: true,
                    isLoading: ui.submittingAction == 'portal',
                    onPressed: (!isOnline || ui.isBusy) ? null : onOpenPortal,
                  ),
                if (sub.hasActiveStripeSubscription && !sub.cancelAtPeriodEnd)
                  AfabButton(
                    label: sub.isTrialActive
                        ? l10n.plansCancelTrial
                        : l10n.plansCancelSubscription,
                    variant: AfabButtonVariant.danger,
                    compact: true,
                    onPressed: (!isOnline || ui.isBusy) ? null : onOpenCancel,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          // AI Token & Query Meter
          AfabInsetPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.plansAiMeterTitle,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        l10n.plansAiMeterSummary(
                          '$tokensUsed',
                          tokenLimitLabel,
                          '$queriesUsed',
                          queryLimitLabel,
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: tokenRatio,
                    minHeight: 8,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(meterColor),
                  ),
                ),
              ],
            ),
          ),

          // Pending Downgrade / Cancel Alert Box
          if (sub.hasPendingChange) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warningBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 16, color: colors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.plansPendingChangeDesc(
                            endDateStr.isEmpty ? 'period end' : endDateStr,
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  if (owned.length > (allocation?.pendingEditableLimit ?? 1)) ...[
                    const SizedBox(height: 8),
                    AfabButton(
                      label: l10n.plansConfigureFutureBusinesses,
                      variant: AfabButtonVariant.secondary,
                      compact: true,
                      onPressed: (!isOnline || ui.isBusy)
                          ? null
                          : onOpenPendingAllocation,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // 3-Day Grace Period Banner (PAST_DUE)
          if (sub.isPastDue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.dangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.danger.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.triangleAlert,
                        size: 16,
                        color: colors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.plansGracePeriodTitle(
                            sub.gracePeriodHoursRemaining ?? 72,
                          ),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: colors.danger,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.plansGracePeriodDesc,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  AfabButton(
                    label: l10n.plansUpdatePaymentMethod,
                    variant: AfabButtonVariant.danger,
                    compact: true,
                    onPressed: (!isOnline || ui.isBusy) ? null : onOpenPortal,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnedBusinessesCard extends StatelessWidget {
  const _OwnedBusinessesCard({
    required this.owned,
    required this.isOnline,
    required this.limit,
    required this.maxWidth,
    required this.onManage,
  });

  final List<BusinessAllocationItemDto> owned;
  final bool isOnline;
  final int limit;
  final double maxWidth;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final cols = maxWidth >= 900 ? 3 : (maxWidth >= 600 ? 2 : 1);

    return AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.plansOwnedWorkspacesTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (owned.length > 1)
                AfabButton(
                  label: l10n.plansChangeEditableBusinesses,
                  icon: LucideIcons.slidersHorizontal,
                  variant: AfabButtonVariant.secondary,
                  compact: true,
                  onPressed: isOnline ? onManage : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, inner) {
              const gap = 10.0;
              final tileW = cols == 1
                  ? inner.maxWidth
                  : (inner.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final biz in owned)
                    SizedBox(
                      width: tileW,
                      child: AfabInsetPanel(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: biz.editable
                                    ? colors.successBg
                                    : colors.warningBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                biz.editable
                                    ? LucideIcons.building2
                                    : LucideIcons.lock,
                                size: 16,
                                color: biz.editable
                                    ? colors.success
                                    : colors.warning,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    biz.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      biz.currency,
                                      if (biz.industry != null &&
                                          biz.industry!.isNotEmpty)
                                        biz.industry!,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AfabStatusBadge(
                                  label: biz.editable
                                      ? l10n.plansStatusUnlocked
                                      : l10n.plansStatusLocked,
                                  variant: biz.editable
                                      ? AfabBadgeVariant.success
                                      : AfabBadgeVariant.warning,
                                ),
                                if (biz.primary) ...[
                                  const SizedBox(height: 4),
                                  AfabStatusBadge(
                                    label: l10n.plansPrimaryBadge,
                                    variant: AfabBadgeVariant.primary,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BillingToggleAndTrial extends StatelessWidget {
  const _BillingToggleAndTrial({
    required this.sub,
    required this.billingInterval,
    required this.onChanged,
  });

  final SubscriptionSnapshotDto sub;
  final String billingInterval;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AfabSegmentedBar<String>(
              items: [
                AfabSegmentItem(
                  value: 'monthly',
                  label: l10n.plansBillingToggleMonthly,
                ),
                AfabSegmentItem(
                  value: 'yearly',
                  label: l10n.plansBillingToggleYearly,
                ),
              ],
              selectedValue: billingInterval,
              onSelected: onChanged,
            ),
            AfabStatusBadge(
              label: l10n.plansSave20Badge,
              variant: AfabBadgeVariant.success,
            ),
          ],
        ),
        if (sub.isTrialActive || sub.isPlusTrialEligible) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.sparkles, size: 20, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.plansTrialBannerTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.plansTrialBannerDesc,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanCardsGrid extends StatelessWidget {
  const _PlanCardsGrid({
    required this.width,
    required this.tiers,
    required this.sub,
    required this.billingInterval,
    required this.isOnline,
    required this.submittingAction,
    required this.onSelectTier,
  });

  final double width;
  final List<PlanTierDefinition> tiers;
  final SubscriptionSnapshotDto sub;
  final String billingInterval;
  final bool isOnline;
  final String? submittingAction;
  final ValueChanged<PlanTierDefinition> onSelectTier;

  @override
  Widget build(BuildContext context) {
    if (width >= 900) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tiers.length; i++) ...[
            Expanded(
              child: _PlanTierCard(
                tier: tiers[i],
                sub: sub,
                billingInterval: billingInterval,
                isOnline: isOnline,
                isLoading: submittingAction == tiers[i].slug,
                anyBusy: submittingAction != null,
                onPressed: () => onSelectTier(tiers[i]),
              ),
            ),
            if (i < tiers.length - 1) const SizedBox(width: 14),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < tiers.length; i++) ...[
          _PlanTierCard(
            tier: tiers[i],
            sub: sub,
            billingInterval: billingInterval,
            isOnline: isOnline,
            isLoading: submittingAction == tiers[i].slug,
            anyBusy: submittingAction != null,
            onPressed: () => onSelectTier(tiers[i]),
          ),
          if (i < tiers.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _PlanTierCard extends StatelessWidget {
  const _PlanTierCard({
    required this.tier,
    required this.sub,
    required this.billingInterval,
    required this.isOnline,
    required this.isLoading,
    required this.anyBusy,
    required this.onPressed,
  });

  final PlanTierDefinition tier;
  final SubscriptionSnapshotDto sub;
  final String billingInterval;
  final bool isOnline;
  final bool isLoading;
  final bool anyBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final isCurrent = sub.planSlug.toLowerCase() == tier.slug;
    final rank = {'free': 0, 'plus': 1, 'pro': 2};
    final currentRank = rank[sub.planSlug.toLowerCase()] ?? 0;
    final targetRank = rank[tier.slug] ?? 0;

    final price = tier.priceForInterval(billingInterval);
    final curr = sub.currency;

    String ctaLabel;
    AfabButtonVariant variant;
    if (isCurrent) {
      ctaLabel = l10n.plansCurrentPlanBtn;
      variant = AfabButtonVariant.secondary;
    } else if (targetRank > currentRank) {
      ctaLabel = tier.slug == 'plus' && sub.isPlusTrialEligible
          ? l10n.plansStartTrialBtn
          : l10n.plansUpgradeToBtn(tier.name);
      variant =
          tier.highlighted ? AfabButtonVariant.premium : AfabButtonVariant.primary;
    } else {
      ctaLabel = l10n.plansDowngradeToBtn(tier.name);
      variant = AfabButtonVariant.secondary;
    }

    final borderColor = tier.highlighted
        ? colors.primary
        : (tier.isVip
            ? colors.warning.withValues(alpha: 0.5)
            : colors.border);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: tier.highlighted ? 2 : 1,
        ),
        boxShadow: tier.highlighted
            ? [
                BoxShadow(
                  color: colors.glowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (tier.isVip ? colors.warning : colors.primary)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      tier.isVip
                          ? LucideIcons.crown
                          : (tier.highlighted
                              ? LucideIcons.sparkles
                              : LucideIcons.layers),
                      size: 18,
                      color: tier.isVip ? colors.warning : colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(tier.name, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              if (tier.highlighted)
                AfabStatusBadge(
                  label: l10n.plansMostPopularTrial,
                  variant: AfabBadgeVariant.primary,
                )
              else if (tier.isVip)
                AfabStatusBadge(
                  label: l10n.plansVipBadge,
                  variant: AfabBadgeVariant.warning,
                ),
              if (isCurrent)
                AfabStatusBadge(
                  label: l10n.plansStatusUnlocked,
                  variant: AfabBadgeVariant.success,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tier.subtitle,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textMuted,
                ),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                MoneyText(
                  amount: price,
                  currency: curr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    l10n.plansPerMonth,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (billingInterval == 'yearly' && price > Decimal.zero)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '(${l10n.plansBilledAnnually})',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(tier.description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          AfabButton(
            label: ctaLabel,
            variant: variant,
            expand: true,
            isLoading: isLoading,
            onPressed: (isCurrent || !isOnline || anyBusy) ? null : onPressed,
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 12),
          Text(
            tier.featuresHeader,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          for (final feat in tier.features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    feat.included ? LucideIcons.check : LucideIcons.x,
                    size: 15,
                    color: feat.included ? colors.success : colors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feat.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: feat.included
                                ? colors.textPrimary
                                : colors.textMuted,
                          ),
                    ),
                  ),
                  if (feat.tooltip != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                      icon: Icon(
                        LucideIcons.info,
                        size: 13,
                        color: colors.textMuted,
                      ),
                      onPressed: () =>
                          AfabToast.showInfo(context, feat.tooltip!),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ComparePlansSection extends StatelessWidget {
  const _ComparePlansSection({
    required this.width,
    required this.rows,
  });

  final double width;
  final List<PlanComparisonRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.plansCompareTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (width >= 720)
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.1),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: colors.border),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colors.surfaceInset),
                  children: [
                    _hdrCell(context, l10n.plansCompareTitle),
                    _hdrCell(context, 'Free'),
                    _hdrCell(context, 'Plus', highlight: true),
                    _hdrCell(context, 'Pro'),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Text(
                          row.feature,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                        ),
                      ),
                      _valCell(context, row.freeValue),
                      _valCell(context, row.plusValue, highlight: true),
                      _valCell(context, row.proValue),
                    ],
                  ),
              ],
            )
          else
            Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].feature,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniTierVal(
                                tier: 'Free',
                                value: rows[i].freeValue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MiniTierVal(
                                tier: 'Plus',
                                value: rows[i].plusValue,
                                highlight: true,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _MiniTierVal(
                                tier: 'Pro',
                                value: rows[i].proValue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (i < rows.length - 1) Divider(height: 1, color: colors.border),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _hdrCell(BuildContext context, String label, {bool highlight = false}) {
    final colors = context.afabColors;
    return Container(
      color: highlight ? colors.primary.withValues(alpha: 0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: highlight ? colors.primary : colors.textPrimary,
            ),
      ),
    );
  }

  Widget _valCell(BuildContext context, String value, {bool highlight = false}) {
    final colors = context.afabColors;
    return Container(
      color: highlight ? colors.primary.withValues(alpha: 0.04) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
            ),
      ),
    );
  }
}

class _MiniTierVal extends StatelessWidget {
  const _MiniTierVal({
    required this.tier,
    required this.value,
    this.highlight = false,
  });

  final String tier;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? colors.primary.withValues(alpha: 0.08)
            : colors.surfaceInset,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? colors.primary.withValues(alpha: 0.3) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tier,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: highlight ? colors.primary : colors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.width,
    required this.history,
    required this.locale,
    required this.onOpenInvoiceUrl,
  });

  final double width;
  final BillingHistoryResponseDto history;
  final String locale;
  final ValueChanged<String> onOpenInvoiceUrl;

  @override
  Widget build(BuildContext context) {
    final subCard = _SubscriptionHistoryCard(
      items: history.subscriptionHistory,
      locale: locale,
    );
    final payCard = _PaymentHistoryCard(
      items: history.paymentHistory,
      locale: locale,
      onOpenInvoiceUrl: onOpenInvoiceUrl,
    );

    if (width >= 840) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: payCard),
          const SizedBox(width: 14),
          Expanded(child: subCard),
        ],
      );
    }

    return Column(
      children: [
        payCard,
        const SizedBox(height: 14),
        subCard,
      ],
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({
    required this.items,
    required this.locale,
    required this.onOpenInvoiceUrl,
  });

  final List<PaymentHistoryItemDto> items;
  final String locale;
  final ValueChanged<String> onOpenInvoiceUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.plansHistoryPayTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              l10n.plansNoPaymentsYet,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: MoneyText(
                                  amount: items[i].amountDecimal,
                                  currency: items[i].currency,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              AfabStatusBadge(
                                label: items[i].status,
                                variant: items[i].status == 'PAID'
                                    ? AfabBadgeVariant.success
                                    : (items[i].status == 'FAILED'
                                        ? AfabBadgeVariant.danger
                                        : AfabBadgeVariant.neutral),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AfabDateFormatter.formatRelativeTimestamp(
                              items[i].paidAt ??
                                  items[i].failedAt ??
                                  items[i].createdAt,
                              locale,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (items[i].failureReason != null &&
                              items[i].failureReason!.isNotEmpty)
                            Text(
                              items[i].failureReason!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.danger),
                            ),
                        ],
                      ),
                    ),
                    if (items[i].hostedInvoiceUrl != null &&
                        items[i].hostedInvoiceUrl!.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () =>
                            onOpenInvoiceUrl(items[i].hostedInvoiceUrl!),
                        icon: const Icon(LucideIcons.externalLink, size: 13),
                        label: Text(l10n.plansViewInvoice),
                      ),
                  ],
                ),
              ),
              if (i < items.length - 1) Divider(height: 1, color: colors.border),
            ],
        ],
      ),
    );
  }
}

class _SubscriptionHistoryCard extends StatelessWidget {
  const _SubscriptionHistoryCard({
    required this.items,
    required this.locale,
  });

  final List<SubscriptionHistoryItemDto> items;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.plansHistorySubTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              l10n.plansNoSubHistory,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AfabStatusBadge(
                          label: items[i].eventType,
                          variant: AfabBadgeVariant.primary,
                        ),
                        if (items[i].createdAt != null)
                          Text(
                            AfabDateFormatter.formatRelativeTimestamp(
                              items[i].createdAt,
                              locale,
                            ),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                    if (items[i].details != null &&
                        items[i].details!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        items[i].details!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (i < items.length - 1) Divider(height: 1, color: colors.border),
            ],
        ],
      ),
    );
  }
}
