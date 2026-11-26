import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

/// Screen `AI-03`: Business Memory Manager (`BusinessMemoryScreen` + reusable
/// `BusinessMemoryBody` for tablet inline side pane).
class BusinessMemoryScreen extends ConsumerWidget {
  const BusinessMemoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final biz = ref.watch(activeBusinessProvider);
    final isReadOnly = biz?.isReadOnly ?? false;
    final statusFilter = ref.watch(aiMemoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiMemoryTitle),
        actions: [
          if (!isReadOnly)
            IconButton(
              tooltip: l10n.aiMemoryAddTitle,
              icon: const Icon(LucideIcons.plus),
              onPressed: () => _openMemoryFormSheet(
                context,
                ref,
                statusFilter: statusFilter,
              ),
            ),
        ],
      ),
      body: BusinessMemoryBody(
        isSidePane: false,
        onOpenCreateSheet: isReadOnly
            ? null
            : () => _openMemoryFormSheet(
                  context,
                  ref,
                  statusFilter: statusFilter,
                ),
      ),
    );
  }
}

class BusinessMemoryBody extends ConsumerStatefulWidget {
  const BusinessMemoryBody({
    super.key,
    required this.isSidePane,
    this.onClosePane,
    this.onOpenCreateSheet,
  });

  final bool isSidePane;
  final VoidCallback? onClosePane;
  final VoidCallback? onOpenCreateSheet;

  @override
  ConsumerState<BusinessMemoryBody> createState() => _BusinessMemoryBodyState();
}

class _BusinessMemoryBodyState extends ConsumerState<BusinessMemoryBody> {
  String? _busyItemId;
  bool _showInlineAddForm = false;
  BusinessMemoryType _inlineType = BusinessMemoryType.supplierPattern;
  final _inlineTitleCtrl = TextEditingController();
  final _inlineContentCtrl = TextEditingController();
  bool _inlineSaving = false;

  @override
  void dispose() {
    _inlineTitleCtrl.dispose();
    _inlineContentCtrl.dispose();
    super.dispose();
  }

  String _localizedTypeLabel(BuildContext context, BusinessMemoryType type) {
    final l10n = context.l10n;
    return switch (type) {
      BusinessMemoryType.businessProfile => l10n.aiMemoryTypeBusinessProfile,
      BusinessMemoryType.transactionContext =>
        l10n.aiMemoryTypeTransactionContext,
      BusinessMemoryType.supplierPattern => l10n.aiMemoryTypeSupplierPattern,
      BusinessMemoryType.categorizationPreference =>
        l10n.aiMemoryTypeCategorizationPreference,
      BusinessMemoryType.decisionHistory => l10n.aiMemoryTypeDecisionHistory,
      BusinessMemoryType.operationalConstraint =>
        l10n.aiMemoryTypeOperationalConstraint,
    };
  }

  Future<void> _submitInlineCreate(String currentFilter) async {
    final title = _inlineTitleCtrl.text.trim();
    final content = _inlineContentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty || _inlineSaving) return;
    setState(() => _inlineSaving = true);
    try {
      await ref.read(aiMemoryProvider(currentFilter).notifier).createMemory(
            memoryType: _inlineType,
            title: title,
            content: content,
          );
      if (!mounted) return;
      _inlineTitleCtrl.clear();
      _inlineContentCtrl.clear();
      setState(() {
        _inlineSaving = false;
        _showInlineAddForm = false;
      });
      AfabToast.showSuccess(context, context.l10n.aiMemoryProposalSaved);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() => _inlineSaving = false);
        AfabToast.showError(context, e.message);
      }
    }
  }

  Future<void> _approveItem(String currentFilter, BusinessMemoryDto item) async {
    if (_busyItemId != null) return;
    setState(() => _busyItemId = item.id);
    try {
      await ref
          .read(aiMemoryProvider(currentFilter).notifier)
          .approveMemory(item.id);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busyItemId = null);
    }
  }

  Future<void> _deleteItem(String currentFilter, BusinessMemoryDto item) async {
    if (_busyItemId != null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiMemoryDeleteConfirmTitle),
        content: Text(l10n.aiMemoryDeleteConfirmDesc(item.title)),
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
    setState(() => _busyItemId = item.id);
    try {
      await ref
          .read(aiMemoryProvider(currentFilter).notifier)
          .deleteMemory(item.id);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busyItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isReadOnly = biz?.isReadOnly ?? false;
    final statusFilter = ref.watch(aiMemoryFilterProvider);
    final memAsync = ref.watch(aiMemoryProvider(statusFilter));
    final uiLocale = Localizations.localeOf(context).languageCode;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(aiMemoryProvider(statusFilter));
        await ref
            .read(aiMemoryProvider(statusFilter).future)
            .catchError((_) => <BusinessMemoryDto>[]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (widget.isSidePane) ...[
            Row(
              children: [
                Icon(LucideIcons.brain, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.aiMemoryTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!isReadOnly)
                  IconButton(
                    tooltip: l10n.aiMemoryAddTitle,
                    icon: const Icon(LucideIcons.plus, size: 18),
                    onPressed: () => setState(
                      () => _showInlineAddForm = !_showInlineAddForm,
                    ),
                  ),
                if (widget.onClosePane != null)
                  IconButton(
                    tooltip: l10n.commonClose,
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: widget.onClosePane,
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Text(
            l10n.aiMemorySubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          if (isReadOnly) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warningBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.lock, size: 16, color: colors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.planReadOnlyTitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/plans'),
                    child: Text(l10n.aiUpgradeCta),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (widget.isSidePane && _showInlineAddForm && !isReadOnly) ...[
            AfabCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.aiMemoryAddTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<BusinessMemoryType>(
                    initialValue: _inlineType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.aiMemoryTypeLabel,
                      isDense: true,
                    ),
                    items: [
                      for (final t in BusinessMemoryType.values)
                        DropdownMenuItem(
                          value: t,
                          child: Text(_localizedTypeLabel(context, t)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _inlineType = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inlineTitleCtrl,
                    maxLength: 160,
                    textDirection: MessageDirectionResolver.resolveForComposer(
                      _inlineTitleCtrl.text,
                      uiLocale,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.aiMemoryTitleLabel,
                      hintText: l10n.aiMemoryTitlePlaceholder,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inlineContentCtrl,
                    maxLength: 2000,
                    minLines: 3,
                    maxLines: 5,
                    textDirection: MessageDirectionResolver.resolveForComposer(
                      _inlineContentCtrl.text,
                      uiLocale,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.aiMemoryContentLabel,
                      hintText: l10n.aiMemoryContentPlaceholder,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AfabButton(
                    label:
                        _inlineSaving ? l10n.aiMemorySaving : l10n.aiMemorySaveButton,
                    isLoading: _inlineSaving,
                    expand: true,
                    onPressed: _inlineSaving
                        ? null
                        : () => _submitInlineCreate(statusFilter),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AfabSegmentedBar<String>(
              items: [
                AfabSegmentItem(value: 'ALL', label: l10n.aiMemoryFilterAll),
                AfabSegmentItem(
                  value: 'PROPOSED',
                  label: l10n.aiMemoryFilterProposed,
                ),
                AfabSegmentItem(
                  value: 'APPROVED',
                  label: l10n.aiMemoryFilterApproved,
                ),
                AfabSegmentItem(
                  value: 'EXPIRED',
                  label: l10n.aiMemoryFilterExpired,
                ),
              ],
              selectedValue: statusFilter,
              onSelected: (s) =>
                  ref.read(aiMemoryFilterProvider.notifier).setStatus(s),
            ),
          ),
          const SizedBox(height: 14),

          memAsync.when(
            loading: () => Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Shimmer.fromColors(
                      baseColor: colors.border,
                      highlightColor: colors.surface,
                      child: const AfabCard(
                        child: SizedBox(height: 76, width: double.infinity),
                      ),
                    ),
                  ),
              ],
            ),
            error: (err, _) => AfabErrorState(
              title: l10n.errorGenericTitle,
              message: err.toString(),
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(aiMemoryProvider(statusFilter)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return AfabEmptyState(
                  icon: LucideIcons.brain,
                  title: statusFilter == 'ALL'
                      ? l10n.aiMemoryEmpty
                      : l10n.aiMemoryFilteredEmpty,
                  description: l10n.aiMemorySubtitle,
                  actionLabel: statusFilter == 'ALL' && !isReadOnly
                      ? l10n.aiMemoryAddTitle
                      : (statusFilter != 'ALL' ? l10n.aiMemoryFilterAll : null),
                  onAction: statusFilter == 'ALL' && !isReadOnly
                      ? (widget.onOpenCreateSheet ??
                          () => setState(() => _showInlineAddForm = true))
                      : (statusFilter != 'ALL'
                          ? () => ref
                              .read(aiMemoryFilterProvider.notifier)
                              .setStatus('ALL')
                          : null),
                );
              }
              return Column(
                children: [
                  for (final item in items) ...[
                    _BusinessMemoryCard(
                      item: item,
                      typeLabel: _localizedTypeLabel(context, item.memoryType),
                      isReadOnly: isReadOnly,
                      busy: _busyItemId == item.id,
                      onApprove: () => _approveItem(statusFilter, item),
                      onEdit: () => _openMemoryFormSheet(
                        context,
                        ref,
                        statusFilter: statusFilter,
                        existing: item,
                      ),
                      onDelete: () => _deleteItem(statusFilter, item),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BusinessMemoryCard extends StatelessWidget {
  const _BusinessMemoryCard({
    required this.item,
    required this.typeLabel,
    required this.isReadOnly,
    required this.busy,
    required this.onApprove,
    required this.onEdit,
    required this.onDelete,
  });

  final BusinessMemoryDto item;
  final String typeLabel;
  final bool isReadOnly;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final updatedStr = item.updatedAt != null
        ? DateFormat.yMMMd().format(item.updatedAt!.toLocal())
        : '';

    return AfabCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AfabStatusBadge(
                label: typeLabel,
                variant: AfabBadgeVariant.primary,
              ),
              AfabStatusBadge(
                label: item.hasVector
                    ? l10n.aiMemoryVectorReady
                    : l10n.aiMemoryLexicalOnly,
                variant: item.hasVector
                    ? AfabBadgeVariant.success
                    : AfabBadgeVariant.warning,
              ),
              if (!item.isApproved)
                AfabStatusBadge(
                  label: item.isProposed
                      ? l10n.aiMemoryFilterProposed
                      : l10n.aiMemoryFilterExpired,
                  variant: item.isProposed
                      ? AfabBadgeVariant.warning
                      : AfabBadgeVariant.neutral,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection:
                MessageDirectionResolver.resolveForMessage(item.title),
            child: Text(
              item.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection:
                MessageDirectionResolver.resolveForMessage(item.content),
            child: SelectableText(
              item.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                    height: 1.45,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.sourceType}${updatedStr.isNotEmpty ? ' · $updatedStr' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textMuted,
                      ),
                ),
              ),
              if (!isReadOnly) ...[
                if (item.isProposed)
                  IconButton(
                    tooltip: l10n.aiMemoryApprove,
                    icon: Icon(
                      LucideIcons.check,
                      size: 17,
                      color: colors.success,
                    ),
                    onPressed: busy ? null : onApprove,
                  ),
                IconButton(
                  tooltip: l10n.aiMemoryEditTitle,
                  icon: Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: colors.textMuted,
                  ),
                  onPressed: busy ? null : onEdit,
                ),
                IconButton(
                  tooltip: l10n.aiMemoryDelete,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: colors.danger,
                  ),
                  onPressed: busy ? null : onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openMemoryFormSheet(
  BuildContext context,
  WidgetRef ref, {
  required String statusFilter,
  BusinessMemoryDto? existing,
}) {
  final l10n = context.l10n;
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  final body = _MemoryFormBody(statusFilter: statusFilter, existing: existing);

  if (isTablet) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: body,
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<void>(
    context: context,
    title: existing == null ? l10n.aiMemoryAddTitle : l10n.aiMemoryEditTitle,
    builder: (_) => body,
  );
}

class _MemoryFormBody extends ConsumerStatefulWidget {
  const _MemoryFormBody({
    required this.statusFilter,
    this.existing,
  });

  final String statusFilter;
  final BusinessMemoryDto? existing;

  @override
  ConsumerState<_MemoryFormBody> createState() => _MemoryFormBodyState();
}

class _MemoryFormBodyState extends ConsumerState<_MemoryFormBody> {
  final _formKey = GlobalKey<FormState>();
  late BusinessMemoryType _type;
  late String _status;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type =
        widget.existing?.memoryType ?? BusinessMemoryType.supplierPattern;
    _status = widget.existing?.status ?? 'APPROVED';
    if (!const ['APPROVED', 'PROPOSED', 'EXPIRED'].contains(_status)) {
      _status = 'APPROVED';
    }
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.existing?.content ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  String _typeLabel(BuildContext context, BusinessMemoryType t) {
    final l10n = context.l10n;
    return switch (t) {
      BusinessMemoryType.businessProfile => l10n.aiMemoryTypeBusinessProfile,
      BusinessMemoryType.transactionContext =>
        l10n.aiMemoryTypeTransactionContext,
      BusinessMemoryType.supplierPattern => l10n.aiMemoryTypeSupplierPattern,
      BusinessMemoryType.categorizationPreference =>
        l10n.aiMemoryTypeCategorizationPreference,
      BusinessMemoryType.decisionHistory => l10n.aiMemoryTypeDecisionHistory,
      BusinessMemoryType.operationalConstraint =>
        l10n.aiMemoryTypeOperationalConstraint,
    };
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() => _saving = true);
    try {
      final notifier =
          ref.read(aiMemoryProvider(widget.statusFilter).notifier);
      if (widget.existing == null) {
        await notifier.createMemory(
          memoryType: _type,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
        );
      } else {
        await notifier.updateMemory(
          id: widget.existing!.id,
          memoryType: _type,
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          status: _status,
        );
      }
      if (!mounted) return;
      AfabToast.showSuccess(context, context.l10n.aiMemoryProposalSaved);
      Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AfabToast.showError(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<BusinessMemoryType>(
            initialValue: _type,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.aiMemoryTypeLabel,
              isDense: true,
            ),
            items: [
              for (final t in BusinessMemoryType.values)
                DropdownMenuItem(value: t, child: Text(_typeLabel(context, t))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _type = v);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleCtrl,
            maxLength: 160,
            decoration: InputDecoration(
              labelText: l10n.aiMemoryTitleLabel,
              hintText: l10n.aiMemoryTitlePlaceholder,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.aiMemoryTitleLabel : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentCtrl,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: l10n.aiMemoryContentLabel,
              hintText: l10n.aiMemoryContentPlaceholder,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.aiMemoryContentLabel
                : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.aiMemoryStatusLabel,
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: 'APPROVED',
                  child: Text(l10n.aiMemoryFilterApproved),
                ),
                DropdownMenuItem(
                  value: 'PROPOSED',
                  child: Text(l10n.aiMemoryFilterProposed),
                ),
                DropdownMenuItem(
                  value: 'EXPIRED',
                  child: Text(l10n.aiMemoryFilterExpired),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
          ],
          const SizedBox(height: 16),
          AfabButton(
            label: _saving
                ? l10n.aiMemorySaving
                : (widget.existing == null
                    ? l10n.aiMemorySaveButton
                    : l10n.aiMemorySaveChanges),
            isLoading: _saving,
            expand: true,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
