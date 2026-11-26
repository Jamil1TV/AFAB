import 'dart:math' as math;

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
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

enum BusinessAllocationMode { manage, downgrade, pendingEdit }

Future<bool?> showBusinessAllocationSheet(
  BuildContext context, {
  required BusinessAllocationMode mode,
  required List<BusinessAllocationItemDto> businesses,
  required int maxAllowed,
  String? targetPlanSlug,
  String? targetPlanName,
  String? billingInterval,
  List<String> initialSelectedIds = const [],
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
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 740),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _BusinessAllocationBody(
              mode: mode,
              businesses: businesses,
              maxAllowed: maxAllowed,
              targetPlanSlug: targetPlanSlug,
              targetPlanName: targetPlanName,
              billingInterval: billingInterval,
              initialSelectedIds: initialSelectedIds,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: _BusinessAllocationBody(
            mode: mode,
            businesses: businesses,
            maxAllowed: maxAllowed,
            targetPlanSlug: targetPlanSlug,
            targetPlanName: targetPlanName,
            billingInterval: billingInterval,
            initialSelectedIds: initialSelectedIds,
          ),
        ),
      ),
    ),
  );
}

class _BusinessAllocationBody extends ConsumerStatefulWidget {
  const _BusinessAllocationBody({
    required this.mode,
    required this.businesses,
    required this.maxAllowed,
    this.targetPlanSlug,
    this.targetPlanName,
    this.billingInterval,
    this.initialSelectedIds = const [],
  });

  final BusinessAllocationMode mode;
  final List<BusinessAllocationItemDto> businesses;
  final int maxAllowed;
  final String? targetPlanSlug;
  final String? targetPlanName;
  final String? billingInterval;
  final List<String> initialSelectedIds;

  @override
  ConsumerState<_BusinessAllocationBody> createState() =>
      _BusinessAllocationBodyState();
}

class _BusinessAllocationBodyState
    extends ConsumerState<_BusinessAllocationBody> {
  late List<String> _selectedIds;
  bool _submitting = false;

  int get _requiredCount => math.min(widget.businesses.length, widget.maxAllowed);

  bool get _isExactSelectionRequired =>
      widget.mode == BusinessAllocationMode.downgrade ||
      widget.mode == BusinessAllocationMode.pendingEdit ||
      widget.businesses.length >= widget.maxAllowed;

  bool get _isValid {
    if (widget.businesses.isEmpty) return true;
    if (_isExactSelectionRequired) {
      return _selectedIds.length == _requiredCount;
    }
    return _selectedIds.isNotEmpty && _selectedIds.length <= widget.maxAllowed;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedIds.isNotEmpty) {
      _selectedIds = widget.initialSelectedIds
          .where((id) => widget.businesses.any((b) => b.id == id))
          .take(widget.maxAllowed)
          .toList();
      if (_selectedIds.isEmpty) {
        _seedDefaults();
      }
    } else {
      final editable = widget.businesses.where((b) => b.editable).toList();
      if (editable.isNotEmpty && editable.length <= widget.maxAllowed) {
        _selectedIds = editable.map((b) => b.id).toList();
      } else {
        _seedDefaults();
      }
    }
  }

  void _seedDefaults() {
    final sorted = List<BusinessAllocationItemDto>.from(widget.businesses)
      ..sort((a, b) {
        if (a.primary != b.primary) return a.primary ? -1 : 1;
        if (a.active != b.active) return a.active ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    _selectedIds = sorted.take(_requiredCount).map((e) => e.id).toList();
  }

  void _toggle(String id) {
    if (_submitting) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds = _selectedIds.where((x) => x != id).toList();
      } else if (widget.maxAllowed == 1) {
        _selectedIds = [id];
      } else if (_selectedIds.length < widget.maxAllowed) {
        _selectedIds = [..._selectedIds, id];
      }
    });
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      switch (widget.mode) {
        case BusinessAllocationMode.manage:
          await ref.read(businessRepositoryProvider).updateAllocations(
                selectedBusinessIds: _selectedIds,
              );
          await ensureEditableActiveBusinessIfNeeded(ref, _selectedIds);
          await refreshAllBillingData(ref);
          if (mounted) {
            AfabToast.showSuccess(context, l10n.allocationUpdatedSuccess);
            Navigator.of(context).pop(true);
          }
        case BusinessAllocationMode.pendingEdit:
          await ref.read(businessRepositoryProvider).savePendingAllocations(
                targetPlanSlug: widget.targetPlanSlug ?? 'free',
                selectedBusinessIds: _selectedIds,
              );
          await refreshAllBillingData(ref);
          if (mounted) {
            AfabToast.showSuccess(context, l10n.allocationUpdatedSuccess);
            Navigator.of(context).pop(true);
          }
        case BusinessAllocationMode.downgrade:
          final targetSlug = widget.targetPlanSlug ?? 'plus';
          final targetName = widget.targetPlanName ?? targetSlug.toUpperCase();
          final updated =
              await ref.read(plansRepositoryProvider).scheduleDowngrade(
                    targetPlanSlug: targetSlug,
                    billingInterval: widget.billingInterval,
                    selectedBusinessIds: _selectedIds,
                  );
          final isImmediate = updated.planSlug.toLowerCase() == targetSlug;
          if (isImmediate) {
            await ensureEditableActiveBusinessIfNeeded(ref, _selectedIds);
          }
          await refreshAllBillingData(ref);
          if (mounted) {
            AfabToast.showSuccess(
              context,
              isImmediate
                  ? l10n.plansImmediateDowngradeSuccess(targetName)
                  : l10n.plansScheduledDowngradeSuccess(targetName),
            );
            Navigator.of(context).pop(true);
          }
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
    final targetName = widget.targetPlanName ??
        (widget.targetPlanSlug?.toUpperCase() ?? 'Plus');

    final title = switch (widget.mode) {
      BusinessAllocationMode.downgrade =>
        l10n.allocationTitleDowngrade(targetName),
      BusinessAllocationMode.pendingEdit =>
        l10n.allocationTitlePending(targetName),
      BusinessAllocationMode.manage => l10n.allocationTitleManage,
    };

    final activeNames = widget.businesses
        .where((b) => _selectedIds.contains(b.id))
        .map((b) => b.name)
        .toList();
    final lockedNames = widget.businesses
        .where((b) => !_selectedIds.contains(b.id))
        .map((b) => b.name)
        .toList();

    final submitLabel = widget.mode == BusinessAllocationMode.downgrade
        ? l10n.allocationSubmitDowngrade(targetName)
        : l10n.allocationSubmitSave;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.building2,
                color: colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    l10n.allocationSubtitle(widget.maxAllowed),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AfabStatusBadge(
              label: l10n.allocationSelectedCounter(
                _selectedIds.length,
                _requiredCount,
              ),
              variant: _isValid
                  ? AfabBadgeVariant.success
                  : AfabBadgeVariant.warning,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Scrollable Businesses List
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.businesses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final biz = widget.businesses[idx];
                final isSelected = _selectedIds.contains(biz.id);
                final capReached = widget.maxAllowed > 1 &&
                    !isSelected &&
                    _selectedIds.length >= widget.maxAllowed;

                return Opacity(
                  opacity: capReached ? 0.65 : 1.0,
                  child: Material(
                    color: isSelected
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surfaceInset,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected ? colors.primary : colors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: capReached || _submitting
                          ? null
                          : () => _toggle(biz.id),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              widget.maxAllowed == 1
                                  ? (isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off)
                                  : (isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank),
                              color: isSelected
                                  ? colors.primary
                                  : colors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        biz.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      if (biz.primary)
                                        AfabStatusBadge(
                                          label: l10n.plansPrimaryBadge,
                                          variant: AfabBadgeVariant.primary,
                                        ),
                                      if (biz.active)
                                        AfabStatusBadge(
                                          label: l10n.plansCurrentBadge,
                                          variant: AfabBadgeVariant.info,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      biz.currency,
                                      if (biz.industry != null &&
                                          biz.industry!.isNotEmpty)
                                        biz.industry!,
                                      biz.editable
                                          ? l10n.allocationCurrentUnlocked
                                          : l10n.allocationCurrentLocked,
                                    ].join(' · '),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AfabStatusBadge(
                              label: isSelected
                                  ? l10n.plansStatusUnlocked
                                  : l10n.plansStatusLocked,
                              variant: isSelected
                                  ? AfabBadgeVariant.success
                                  : AfabBadgeVariant.warning,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Outcome Summary Panel
        AfabInsetPanel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 16,
                    color: colors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.allocationOutcomeActive} ${activeNames.isEmpty ? '—' : activeNames.join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
              if (lockedNames.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.lock, size: 16, color: colors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.allocationOutcomeLocked} ${lockedNames.join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (!_isValid) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      size: 15,
                      color: colors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.allocationExactError(_requiredCount),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Footer
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            AfabButton(
              label: l10n.commonCancel,
              variant: AfabButtonVariant.secondary,
              onPressed:
                  _submitting ? null : () => Navigator.of(context).pop(false),
            ),
            AfabButton(
              label: submitLabel,
              variant: AfabButtonVariant.primary,
              isLoading: _submitting,
              onPressed: (!_isValid || _submitting) ? null : _submit,
            ),
          ],
        ),
      ],
    );
  }
}
