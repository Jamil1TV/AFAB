import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:afab_mobile/features/plans/data/plans_repository.dart';
import 'package:afab_mobile/features/plans/domain/plans_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<bool?> showCancelSubscriptionSheet(
  BuildContext context, {
  required SubscriptionSnapshotDto snapshot,
  required List<BusinessAllocationItemDto> businesses,
}) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 512, maxHeight: 740),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _CancelSubscriptionBody(
              snapshot: snapshot,
              businesses: businesses,
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: _CancelSubscriptionBody(
            snapshot: snapshot,
            businesses: businesses,
          ),
        ),
      ),
    ),
  );
}

class _CancelSubscriptionBody extends ConsumerStatefulWidget {
  const _CancelSubscriptionBody({
    required this.snapshot,
    required this.businesses,
  });

  final SubscriptionSnapshotDto snapshot;
  final List<BusinessAllocationItemDto> businesses;

  @override
  ConsumerState<_CancelSubscriptionBody> createState() =>
      _CancelSubscriptionBodyState();
}

class _CancelSubscriptionBodyState
    extends ConsumerState<_CancelSubscriptionBody> {
  String? _selectedBusinessId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.businesses.isNotEmpty) {
      final preferred =
          widget.businesses.where((b) => b.primary).firstOrNull ??
              widget.businesses.where((b) => b.active).firstOrNull ??
              widget.businesses.first;
      _selectedBusinessId = preferred.id;
    }
  }

  Future<void> _confirmCancel() async {
    if (_submitting) return;
    if (widget.businesses.length > 1 &&
        (_selectedBusinessId == null || _selectedBusinessId!.isEmpty)) {
      return;
    }
    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      final ids = _selectedBusinessId != null
          ? <String>[_selectedBusinessId!]
          : <String>[];
      final updated =
          await ref.read(plansRepositoryProvider).cancelSubscription(
                selectedBusinessIds: ids,
              );
      final isImmediateFree = updated.planSlug.toLowerCase() == 'free';
      if (isImmediateFree && ids.isNotEmpty) {
        await ensureEditableActiveBusinessIfNeeded(ref, ids);
      }
      await refreshAllBillingData(ref);
      if (mounted) {
        AfabToast.showSuccess(
          context,
          isImmediateFree
              ? l10n.plansImmediateDowngradeSuccess('Free')
              : l10n.cancelSubScheduledSuccess,
        );
        Navigator.of(context).pop(true);
      }
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final isTrial = widget.snapshot.isTrialActive;
    final planName = widget.snapshot.planName;
    final endDt = widget.snapshot.effectiveEndDate;
    final endDateStr = endDt != null
        ? AfabDateFormatter.formatDateTime(endDt, locale: locale)
        : 'period end';
    final canConfirm = !_submitting &&
        (widget.businesses.length <= 1 ||
            (_selectedBusinessId?.isNotEmpty ?? false));

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.warningBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.triangleAlert,
                  color: colors.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTrial
                          ? l10n.cancelSubTrialTitle(planName)
                          : l10n.cancelSubPaidTitle(planName),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.cancelSubSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Lifecycle Guarantees
          AfabInsetPanel(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _GuaranteeRow(
                  icon: LucideIcons.calendar,
                  color: colors.primary,
                  title: l10n.cancelSubEndAccessLabel,
                  desc: l10n.cancelSubEndAccessDesc(planName, endDateStr),
                ),
                const SizedBox(height: 10),
                _GuaranteeRow(
                  icon: LucideIcons.creditCard,
                  color: colors.success,
                  title: l10n.cancelSubFuturePayLabel,
                  desc: isTrial
                      ? l10n.cancelSubTrialNoCharge
                      : l10n.cancelSubPaidNoRenew,
                ),
                const SizedBox(height: 10),
                _GuaranteeRow(
                  icon: LucideIcons.shieldCheck,
                  color: colors.info,
                  title: l10n.cancelSubBizSafeLabel,
                  desc: l10n.cancelSubBizSafeDesc,
                ),
              ],
            ),
          ),

          if (widget.businesses.length > 1) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.cancelSubSelectOne(widget.businesses.length),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AfabStatusBadge(
                        label: '1 / 1',
                        variant: AfabBadgeVariant.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final biz in widget.businesses) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: _selectedBusinessId == biz.id
                            ? colors.surface
                            : colors.surfaceInset,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedBusinessId == biz.id
                                ? colors.primary
                                : colors.border,
                            width: _selectedBusinessId == biz.id ? 1.5 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _submitting
                              ? null
                              : () =>
                                  setState(() => _selectedBusinessId = biz.id),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedBusinessId == biz.id
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: _selectedBusinessId == biz.id
                                      ? colors.primary
                                      : colors.textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        biz.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      Text(
                                        [
                                          biz.currency,
                                          if (biz.industry != null &&
                                              biz.industry!.isNotEmpty)
                                            biz.industry!,
                                        ].join(' · '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AfabStatusBadge(
                                  label: _selectedBusinessId == biz.id
                                      ? l10n.cancelSubRemainsActive
                                      : l10n.cancelSubBecomesLocked,
                                  variant: _selectedBusinessId == biz.id
                                      ? AfabBadgeVariant.success
                                      : AfabBadgeVariant.warning,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Actions
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              AfabButton(
                label: l10n.cancelSubKeepBtn,
                variant: AfabButtonVariant.primary,
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
              ),
              AfabButton(
                label: l10n.cancelSubConfirmBtn,
                variant: AfabButtonVariant.danger,
                isLoading: _submitting,
                onPressed: canConfirm ? _confirmCancel : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuaranteeRow extends StatelessWidget {
  const _GuaranteeRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(desc, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
