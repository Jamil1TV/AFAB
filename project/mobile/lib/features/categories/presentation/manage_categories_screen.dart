import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/category_icon_mapper.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/categories/presentation/widgets/category_editor_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `FIN-05`: Manage Categories (`EXPENSE` / `INCOME`) with real
/// icon mapping, pure-hex color swatches, system-default lock, and `PUT`/`DELETE`.
class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState
    extends ConsumerState<ManageCategoriesScreen> {
  String _activeType = 'EXPENSE';
  String? _deletingId;
  String? _errorBanner;

  Future<void> _confirmDelete(CategoryDto cat) async {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(l10n.commonDelete),
        content: Text(l10n.txCatDeleteConfirm(cat.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingId = cat.id;
      _errorBanner = null;
    });

    try {
      await ref.read(categoryListProvider.notifier).deleteCategory(cat.id);
      if (!mounted) return;
      AfabToast.showSuccess(context, l10n.txCatDeletedToast);
    } on AppFailure catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        final match = RegExp(r'used by (\d+) transaction').firstMatch(e.message);
        final count = int.tryParse(match?.group(1) ?? '');
        setState(() {
          _errorBanner = count != null
              ? l10n.txCatInUseWithCount(count)
              : l10n.txCatInUseGeneric;
        });
      } else {
        setState(() => _errorBanner = e.message);
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final isEditable = !(ref.watch(activeBusinessProvider)?.isReadOnly ?? false);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.txCatTitle),
        actions: [
          if (isEditable)
            IconButton(
              tooltip: l10n.txCatNewBtn,
              onPressed: () => showCategoryEditorSheet(
                context,
                activeType: _activeType,
              ),
              icon: const Icon(LucideIcons.plus),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoryListProvider);
          await ref.read(categoryListProvider.future);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AfabSegmentedBar<String>(
                  items: [
                    AfabSegmentItem(
                      value: 'EXPENSE',
                      label: l10n.txCatExpenseTab,
                    ),
                    AfabSegmentItem(
                      value: 'INCOME',
                      label: l10n.txCatIncomeTab,
                    ),
                  ],
                  selectedValue: _activeType,
                  onSelected: (t) => setState(() {
                    _activeType = t;
                    _errorBanner = null;
                  }),
                ),
                if (!isEditable) ...[
                  const SizedBox(height: 12),
                  AfabInsetPanel(
                    borderColor: colors.warning.withValues(alpha: 0.45),
                    child: Text(
                      l10n.commonReadOnlyNotice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
                if (_errorBanner != null) ...[
                  const SizedBox(height: 12),
                  AfabInsetPanel(
                    borderColor: colors.danger.withValues(alpha: 0.45),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          size: 18,
                          color: colors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorBanner!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isEditable) ...[
                  const SizedBox(height: 14),
                  AfabButton(
                    label: l10n.txCatNewBtn,
                    icon: LucideIcons.plus,
                    variant: AfabButtonVariant.soft,
                    expand: true,
                    onPressed: () => showCategoryEditorSheet(
                      context,
                      activeType: _activeType,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                categoriesAsync.when(
                  loading: () => const AfabListSkeleton(count: 6),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(categoryListProvider),
                  ),
                  data: (all) {
                    final filtered = all
                        .where((c) => c.type.toUpperCase() == _activeType)
                        .toList();
                    if (filtered.isEmpty) {
                      return AfabEmptyState(
                        icon: LucideIcons.tag,
                        title: l10n.commonNoData,
                        description: l10n.txCatNewBtn,
                      );
                    }
                    return Column(
                      children: [
                        for (final cat in filtered) ...[
                          _CategoryTile(
                            category: cat,
                            isEditableWorkspace: isEditable,
                            isDeleting: _deletingId == cat.id,
                            onEdit: () => showCategoryEditorSheet(
                              context,
                              activeType: _activeType,
                              categoryToEdit: cat,
                            ),
                            onDelete: () => _confirmDelete(cat),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isEditableWorkspace,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryDto category;
  final bool isEditableWorkspace;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final resolvedColor = ColorParser.parseHex(category.color, colors.primary);
    final iconData = CategoryIconMapper.resolve(category.icon);

    return AfabCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: resolvedColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (category.systemDefault)
                      AfabStatusBadge(
                        label: l10n.txCatSystemBadge,
                        variant: AfabBadgeVariant.neutral,
                        icon: LucideIcons.lock,
                      )
                    else
                      AfabStatusBadge(
                        label: l10n.txCatCustomBadge,
                        variant: AfabBadgeVariant.primary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!category.systemDefault && isEditableWorkspace) ...[
            IconButton(
              tooltip: l10n.commonEdit,
              onPressed: isDeleting ? null : onEdit,
              icon: Icon(LucideIcons.pencil, size: 18, color: colors.textMuted),
            ),
            if (isDeleting)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: l10n.commonDelete,
                onPressed: onDelete,
                icon: Icon(LucideIcons.trash2, size: 18, color: colors.danger),
              ),
          ],
        ],
      ),
    );
  }
}
