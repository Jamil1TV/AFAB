import 'package:afab_mobile/core/config/business_constants.dart';
import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/data/business_repository.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `DASH-03`: Multi-tenant workspace switcher, workspace creator,
/// plan capacity guard (OWNER-only count), and READ_ONLY locked prompt.
Future<void> showBusinessSwitcherSheet(BuildContext context) {
  return showAfabBottomSheet<void>(
    context: context,
    title: context.l10n.businessSwitcherTitle,
    builder: (sheetCtx) => _BusinessSwitcherBody(parentContext: context),
  );
}

class _BusinessSwitcherBody extends ConsumerStatefulWidget {
  const _BusinessSwitcherBody({required this.parentContext});

  final BuildContext parentContext;

  @override
  ConsumerState<_BusinessSwitcherBody> createState() =>
      _BusinessSwitcherBodyState();
}

class _BusinessSwitcherBodyState extends ConsumerState<_BusinessSwitcherBody> {
  bool _switching = false;

  Future<void> _switchTo(BusinessDto biz) async {
    final l10n = context.l10n;
    if (biz.isReadOnly) {
      await _showLockedDialog(biz);
      return;
    }
    setState(() => _switching = true);
    try {
      await ref.read(businessRepositoryProvider).switchBusiness(biz.id);
      await ref.read(activeBusinessIdProvider.notifier).setBusinessId(biz.id);
      if (biz.numberFormat != null && biz.numberFormat!.isNotEmpty) {
        await ref.read(prefsStoreProvider).setNumberFormat(biz.numberFormat!);
      }
      if (biz.dateFormat != null && biz.dateFormat!.isNotEmpty) {
        await ref.read(prefsStoreProvider).setDateFormat(biz.dateFormat!);
      }
      ref.invalidate(businessListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(aiPulseProvider);
      ref.invalidate(subscriptionSnapshotProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.parentContext.mounted) {
        AfabToast.showSuccess(
          widget.parentContext,
          l10n.businessSwitcherSwitched(biz.name),
        );
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _showLockedDialog(BusinessDto biz) async {
    final l10n = context.l10n;
    final colors = context.afabColors;
    await showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.lock, size: 20, color: colors.warning),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.businessSwitcherLockedTitle)),
          ],
        ),
        content: Text(l10n.businessSwitcherLockedDesc(biz.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: Text(l10n.commonClose),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dlgCtx).pop();
              Navigator.of(context).pop();
              widget.parentContext.go('/plans');
            },
            child: Text(l10n.businessSwitcherManagePlans),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddBusiness({
    required int ownedEditableCount,
    required int limit,
  }) async {
    final l10n = context.l10n;
    if (ownedEditableCount >= limit) {
      await showDialog<void>(
        context: context,
        builder: (dlgCtx) => AlertDialog(
          title: Text(l10n.businessSwitcherLimitTitle),
          content: Text(l10n.businessSwitcherLimitDesc(limit)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(),
              child: Text(l10n.commonClose),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dlgCtx).pop();
                Navigator.of(context).pop();
                widget.parentContext.go('/plans');
              },
              child: Text(l10n.dashboardUpgradeBtn),
            ),
          ],
        ),
      );
      return;
    }

    await _showCreateBusinessDialog();
  }

  Future<void> _showCreateBusinessDialog() async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    var currency = 'USD';
    var creating = false;
    String? errorMsg;

    await showDialog<void>(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final colors = ctx.afabColors;
          return AlertDialog(
            title: Text(l10n.businessSwitcherCreateTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMsg != null) ...[
                    Text(
                      errorMsg!,
                      style: Theme.of(ctx)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.danger),
                    ),
                    const SizedBox(height: 10),
                  ],
                  AfabTextField(
                    label: l10n.businessSwitcherNameLabel,
                    controller: nameCtrl,
                    hintText: l10n.businessSwitcherNamePlaceholder,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.businessSwitcherCurrencyLabel,
                    style: Theme.of(ctx)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    items: BusinessConstants.switcherCurrencies
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.code,
                            child: Text('${c.code} (${c.symbol})'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => currency = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: creating ? null : () => Navigator.of(dlgCtx).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: creating
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          setDlgState(
                            () => errorMsg = l10n.authFieldRequired,
                          );
                          return;
                        }
                        setDlgState(() {
                          creating = true;
                          errorMsg = null;
                        });
                        try {
                          final created = await ref
                              .read(businessRepositoryProvider)
                              .createBusiness(
                                name: nameCtrl.text,
                                currency: currency,
                              );
                          await ref
                              .read(activeBusinessIdProvider.notifier)
                              .setBusinessId(created.id);
                          ref.invalidate(businessListProvider);
                          ref.invalidate(dashboardSummaryProvider);
                          ref.invalidate(aiPulseProvider);
                          ref.invalidate(subscriptionSnapshotProvider);
                          if (!mounted || !dlgCtx.mounted) return;
                          Navigator.of(dlgCtx).pop();
                          Navigator.of(context).pop();
                          AfabToast.showSuccess(
                            widget.parentContext,
                            l10n.businessSwitcherCreateSuccess,
                          );
                        } on AppFailure catch (e) {
                          setDlgState(() {
                            creating = false;
                            errorMsg = e.message;
                          });
                        }
                      },
                child: Text(l10n.businessSwitcherCreateBtn),
              ),
            ],
          );
        },
      ),
    );
    nameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final businessesAsync = ref.watch(businessListProvider);
    final activeId = ref.watch(activeBusinessIdProvider);
    final sub = ref.watch(subscriptionSnapshotProvider).value;

    return businessesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(err.toString()),
      ),
      data: (businesses) {
        final ownedEditableCount = businesses
            .where((b) => b.isOwner && !b.isReadOnly)
            .length;
        final limit = sub?.editableBusinessLimit ??
            switch ((sub?.planSlug ?? 'free').toLowerCase()) {
              'pro' => 5,
              'plus' => 3,
              _ => 1,
            };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AfabStatusBadge(
                  label: l10n.businessSwitcherCapacity(
                    ownedEditableCount,
                    limit,
                  ),
                  variant: ownedEditableCount >= limit
                      ? AfabBadgeVariant.warning
                      : AfabBadgeVariant.primary,
                ),
                if (_switching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            for (final biz in businesses) ...[
              _WorkspaceTile(
                biz: biz,
                isSelected: biz.id == activeId,
                onTap: _switching ? null : () => _switchTo(biz),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            AfabButton(
              label: l10n.businessSwitcherAddNew,
              icon: LucideIcons.plus,
              variant: AfabButtonVariant.soft,
              expand: true,
              onPressed: _switching
                  ? null
                  : () => _handleAddBusiness(
                        ownedEditableCount: ownedEditableCount,
                        limit: limit,
                      ),
            ),
            const SizedBox(height: 8),
            AfabButton(
              label: l10n.businessSwitcherManagePlans,
              icon: LucideIcons.crown,
              variant: AfabButtonVariant.secondary,
              expand: true,
              onPressed: () {
                Navigator.of(context).pop();
                widget.parentContext.go('/plans');
              },
            ),
            SizedBox(height: colors.isDark ? 4 : 4),
          ],
        );
      },
    );
  }
}

class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({
    required this.biz,
    required this.isSelected,
    this.onTap,
  });

  final BusinessDto biz;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final roleLabel = switch (biz.userRole.toUpperCase()) {
      'ADMIN' => l10n.businessRoleAdmin,
      'MEMBER' => l10n.businessRoleMember,
      _ => l10n.businessRoleOwner,
    };

    return AfabCard(
      padding: const EdgeInsets.all(14),
      borderColor: isSelected ? colors.primary : colors.border,
      backgroundColor: isSelected ? colors.secondaryBg.withValues(alpha: 0.4) : null,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: biz.isReadOnly
                  ? colors.warningBg
                  : colors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              biz.isReadOnly ? LucideIcons.lock : LucideIcons.building2,
              size: 18,
              color: biz.isReadOnly ? colors.warning : colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biz.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    AfabStatusBadge(
                      label: biz.currency,
                      variant: AfabBadgeVariant.neutral,
                    ),
                    AfabStatusBadge(
                      label: roleLabel,
                      variant: AfabBadgeVariant.info,
                    ),
                    AfabStatusBadge(
                      label: biz.isReadOnly
                          ? l10n.commonLocked
                          : l10n.commonActive,
                      variant: biz.isReadOnly
                          ? AfabBadgeVariant.warning
                          : AfabBadgeVariant.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(LucideIcons.circleCheck, size: 20, color: colors.primary),
        ],
      ),
    );
  }
}
