import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:afab_mobile/features/recurring/data/recurring_repository.dart';
import 'package:afab_mobile/features/recurring/domain/recurring_providers.dart';
import 'package:afab_mobile/features/recurring/presentation/widgets/create_edit_recurring_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `BIZ-08`: Recurring Transactions Management & Manual Due Runner.
class RecurringTransactionsScreen extends ConsumerStatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  ConsumerState<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends ConsumerState<RecurringTransactionsScreen> {
  String? _runningRuleId;
  String? _togglingRuleId;

  Future<void> _runDue(RecurringTransactionDto rule) async {
    setState(() => _runningRuleId = rule.id);
    try {
      final result =
          await ref.read(recurringRepositoryProvider).runDue(rule.id);
      if (!mounted) return;
      invalidateAfterRecurringRun(
        ref,
        generatedAny: result.generatedCount > 0,
      );
      if (result.generatedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.recurringGeneratedToast(result.generatedCount),
            ),
            action: SnackBarAction(
              label: context.l10n.commonView,
              onPressed: () => context.go('/transactions'),
            ),
          ),
        );
      } else {
        AfabToast.showInfo(context, context.l10n.recurringNoneDueToast);
      }
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _runningRuleId = null);
    }
  }

  Future<void> _toggleStatus(RecurringTransactionDto rule) async {
    setState(() => _togglingRuleId = rule.id);
    try {
      await ref
          .read(recurringRepositoryProvider)
          .updateStatus(rule.id, active: !rule.active);
      if (!mounted) return;
      invalidateAfterRecurringRun(ref);
      AfabToast.showSuccess(
        context,
        rule.active
            ? context.l10n.recurringPausedToast
            : context.l10n.recurringResumedToast,
      );
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _togglingRuleId = null);
    }
  }

  Future<void> _deleteRule(RecurringTransactionDto rule) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recurringDeleteTitle),
        content: Text(l10n.recurringDeleteDesc(rule.description)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final hadExecutions = rule.lastExecutedAt != null;
    try {
      await ref.read(recurringRepositoryProvider).deleteRule(rule.id);
      if (!mounted) return;
      invalidateAfterRecurringRun(ref);
      AfabToast.showSuccess(
        context,
        hadExecutions ? l10n.recurringDeactivatedToast : l10n.recurringDeletedToast,
      );
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    }
  }

  String _freqLabel(BuildContext context, String raw) {
    final l10n = context.l10n;
    return switch (raw.toUpperCase()) {
      'WEEKLY' => l10n.recurringFreqWeekly,
      'QUARTERLY' => l10n.recurringFreqQuarterly,
      'YEARLY' => l10n.recurringFreqYearly,
      _ => l10n.recurringFreqMonthly,
    };
  }

  String _methodLabel(BuildContext context, String raw) {
    final l10n = context.l10n;
    return switch (raw.toUpperCase()) {
      'CARD' => l10n.txMethodCard,
      'CREDIT_CARD' => l10n.txMethodCreditCard,
      'CASH' => l10n.txMethodCash,
      'OTHER' => l10n.txMethodOther,
      _ => l10n.txMethodBankTransfer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final statusFilter = ref.watch(recurringStatusFilterProvider);
    final listAsync = ref.watch(recurringListProvider);

    return Scaffold(
      floatingActionButton: isEditable
          ? FloatingActionButton.extended(
              heroTag: 'recurring_new_fab',
              onPressed: () => showCreateEditRecurringSheet(context),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.recurringNewBtn),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);

          return RefreshIndicator(
            onRefresh: () => ref.refresh(recurringListProvider.future),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 24 : 16,
                16,
                isExpanded ? 24 : 16,
                96,
              ),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.recurringTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.recurringSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    AfabSegmentedBar<RecurringStatusFilter>(
                      items: [
                        AfabSegmentItem(
                          value: RecurringStatusFilter.all,
                          label: l10n.commonAll,
                        ),
                        AfabSegmentItem(
                          value: RecurringStatusFilter.active,
                          label: l10n.recurringFilterActive,
                        ),
                        AfabSegmentItem(
                          value: RecurringStatusFilter.paused,
                          label: l10n.recurringFilterPaused,
                        ),
                      ],
                      selectedValue: statusFilter,
                      onSelected: (f) => ref
                          .read(recurringStatusFilterProvider.notifier)
                          .select(f),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                listAsync.when(
                  loading: () => const AfabListSkeleton(count: 3),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(recurringListProvider),
                  ),
                  data: (allRules) {
                    final rules = switch (statusFilter) {
                      RecurringStatusFilter.all => allRules,
                      RecurringStatusFilter.active =>
                        allRules.where((r) => r.active).toList(),
                      RecurringStatusFilter.paused =>
                        allRules.where((r) => !r.active).toList(),
                    };

                    if (rules.isEmpty) {
                      return AfabEmptyState(
                        icon: LucideIcons.repeat,
                        title: l10n.recurringEmptyTitle,
                        description: l10n.recurringEmptyDesc,
                        actionLabel:
                            isEditable ? l10n.recurringCreateFirstBtn : null,
                        onAction: isEditable
                            ? () => showCreateEditRecurringSheet(context)
                            : null,
                      );
                    }

                    if (isExpanded) {
                      return AfabCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text(l10n.txFormDescriptionLabel)),
                              DataColumn(label: Text(l10n.txFilterType)),
                              DataColumn(label: Text(l10n.txFormAmountLabel)),
                              DataColumn(label: Text(l10n.recurringFieldFrequency)),
                              DataColumn(label: Text(l10n.txSortDate)),
                              DataColumn(label: Text(l10n.txFilterStatus)),
                              DataColumn(label: Text(l10n.commonEdit)),
                            ],
                            rows: [
                              for (final r in rules)
                                DataRow(
                                  cells: [
                                    DataCell(Text(r.description)),
                                    DataCell(
                                      AfabStatusBadge(
                                        label: r.isIncome
                                            ? l10n.txTypeIncome
                                            : l10n.txTypeExpense,
                                        variant: r.isIncome
                                            ? AfabBadgeVariant.success
                                            : AfabBadgeVariant.danger,
                                      ),
                                    ),
                                    DataCell(
                                      MoneyText(
                                        amount: r.amount,
                                        currency: r.currency,
                                      ),
                                    ),
                                    DataCell(Text(_freqLabel(context, r.frequency))),
                                    DataCell(
                                      Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          AfabDateFormatter.formatIsoDate(
                                            r.nextExecutionDate,
                                            dateFormat: dateFmt,
                                            locale: locale,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      AfabStatusBadge(
                                        label: r.active
                                            ? l10n.recurringFilterActive
                                            : l10n.recurringFilterPaused,
                                        variant: r.active
                                            ? AfabBadgeVariant.success
                                            : AfabBadgeVariant.neutral,
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: l10n.recurringRunDueBtn,
                                            icon: _runningRuleId == r.id
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : Icon(
                                                    LucideIcons.refreshCw,
                                                    size: 16,
                                                    color: r.active && isEditable
                                                        ? colors.primary
                                                        : colors.textMuted,
                                                  ),
                                            onPressed: (r.active &&
                                                    isEditable &&
                                                    _runningRuleId != r.id)
                                                ? () => _runDue(r)
                                                : null,
                                          ),
                                          IconButton(
                                            tooltip: r.active
                                                ? l10n.recurringPauseBtn
                                                : l10n.recurringResumeBtn,
                                            icon: Icon(
                                              r.active
                                                  ? LucideIcons.pause
                                                  : LucideIcons.play,
                                              size: 16,
                                              color: colors.warning,
                                            ),
                                            onPressed: (isEditable &&
                                                    _togglingRuleId != r.id)
                                                ? () => _toggleStatus(r)
                                                : null,
                                          ),
                                          IconButton(
                                            tooltip: l10n.commonEdit,
                                            icon: const Icon(
                                              LucideIcons.pencil,
                                              size: 16,
                                            ),
                                            onPressed: isEditable
                                                ? () =>
                                                    showCreateEditRecurringSheet(
                                                      context,
                                                      editingRule: r,
                                                    )
                                                : null,
                                          ),
                                          IconButton(
                                            tooltip: l10n.commonDelete,
                                            icon: Icon(
                                              LucideIcons.trash2,
                                              size: 16,
                                              color: colors.danger,
                                            ),
                                            onPressed: isEditable
                                                ? () => _deleteRule(r)
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final r in rules) ...[
                          _RecurringRuleCard(
                            rule: r,
                            frequencyLabel: _freqLabel(context, r.frequency),
                            methodLabel: _methodLabel(context, r.paymentMethod),
                            dateFormat: dateFmt,
                            locale: locale,
                            isEditable: isEditable,
                            isRunning: _runningRuleId == r.id,
                            isToggling: _togglingRuleId == r.id,
                            onRunDue: () => _runDue(r),
                            onToggleStatus: () => _toggleStatus(r),
                            onEdit: () => showCreateEditRecurringSheet(
                              context,
                              editingRule: r,
                            ),
                            onDelete: () => _deleteRule(r),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecurringRuleCard extends StatelessWidget {
  const _RecurringRuleCard({
    required this.rule,
    required this.frequencyLabel,
    required this.methodLabel,
    required this.dateFormat,
    required this.locale,
    required this.isEditable,
    required this.isRunning,
    required this.isToggling,
    required this.onRunDue,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTransactionDto rule;
  final String frequencyLabel;
  final String methodLabel;
  final String dateFormat;
  final String locale;
  final bool isEditable;
  final bool isRunning;
  final bool isToggling;
  final VoidCallback onRunDue;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final nextStr = AfabDateFormatter.formatIsoDate(
      rule.nextExecutionDate,
      dateFormat: dateFormat,
      locale: locale,
    );

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                rule.description,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              AfabStatusBadge(
                label: rule.isIncome ? l10n.txTypeIncome : l10n.txTypeExpense,
                variant: rule.isIncome
                    ? AfabBadgeVariant.success
                    : AfabBadgeVariant.danger,
              ),
              AfabStatusBadge(
                label: rule.active
                    ? l10n.recurringFilterActive
                    : l10n.recurringFilterPaused,
                variant: rule.active
                    ? AfabBadgeVariant.success
                    : AfabBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${rule.categoryName ?? l10n.txDetailsUncategorized} · $methodLabel',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          AfabInsetPanel(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MoneyText(
                      amount: rule.amount,
                      currency: rule.currency,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    AfabStatusBadge(
                      label: frequencyLabel,
                      variant: AfabBadgeVariant.primary,
                    ),
                  ],
                ),
                Text(
                  l10n.recurringNextRun(nextStr),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (rule.lastExecutedAt != null || rule.endDate != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (rule.lastExecutedAt != null)
                  Text(
                    l10n.recurringLastRun(
                      AfabDateFormatter.formatRelativeTimestamp(
                        rule.lastExecutedAt,
                        locale,
                      ),
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (rule.endDate != null && rule.endDate!.isNotEmpty)
                  Text(
                    l10n.recurringEndDate(
                      AfabDateFormatter.formatIsoDate(
                        rule.endDate!,
                        dateFormat: dateFmtOrDefault(dateFormat),
                        locale: locale,
                      ),
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ],
          if (isEditable) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: (rule.active && !isRunning) ? onRunDue : null,
                  icon: isRunning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.refreshCw, size: 15),
                  label: Text(l10n.recurringRunDueBtn),
                ),
                IconButton(
                  tooltip:
                      rule.active ? l10n.recurringPauseBtn : l10n.recurringResumeBtn,
                  icon: isToggling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          rule.active ? LucideIcons.pause : LucideIcons.play,
                          size: 18,
                          color: colors.warning,
                        ),
                  onPressed: isToggling ? null : onToggleStatus,
                ),
                IconButton(
                  tooltip: l10n.commonEdit,
                  icon: Icon(
                    LucideIcons.pencil,
                    size: 18,
                    color: colors.primary,
                  ),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: l10n.commonDelete,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: colors.danger,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String dateFmtOrDefault(String df) => df.isEmpty ? 'YYYY-MM-DD' : df;
}
