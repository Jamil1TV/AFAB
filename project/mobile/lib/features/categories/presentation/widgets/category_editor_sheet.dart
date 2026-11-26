import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/category_icon_mapper.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<CategoryDto?> showCategoryEditorSheet(
  BuildContext context, {
  required String activeType,
  CategoryDto? categoryToEdit,
}) {
  final l10n = context.l10n;
  final title = categoryToEdit != null
      ? l10n.txCatEditTitle
      : '${l10n.txCatNewBtn} (${activeType == 'INCOME' ? l10n.txTypeIncome : l10n.txTypeExpense})';
  return showAfabBottomSheet<CategoryDto>(
    context: context,
    title: title,
    builder: (sheetCtx) => _CategoryEditorBody(
      parentContext: context,
      activeType: activeType,
      categoryToEdit: categoryToEdit,
    ),
  );
}

class _CategoryEditorBody extends ConsumerStatefulWidget {
  const _CategoryEditorBody({
    required this.parentContext,
    required this.activeType,
    this.categoryToEdit,
  });

  final BuildContext parentContext;
  final String activeType;
  final CategoryDto? categoryToEdit;

  @override
  ConsumerState<_CategoryEditorBody> createState() =>
      _CategoryEditorBodyState();
}

class _CategoryEditorBodyState extends ConsumerState<_CategoryEditorBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _selectedIcon;
  late String _selectedColorHex;
  bool _saving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final editing = widget.categoryToEdit;
    _nameCtrl = TextEditingController(text: editing?.name ?? '');
    _selectedIcon = editing?.icon?.isNotEmpty == true ? editing!.icon! : 'Tag';
    final rawColor = editing?.color;
    if (rawColor != null &&
        rawColor.isNotEmpty &&
        !rawColor.startsWith('var(')) {
      _selectedColorHex = rawColor.toUpperCase();
    } else {
      _selectedColorHex = widget.activeType == 'INCOME' ? '#10B981' : '#8B5CF6';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final trimmed = _nameCtrl.text.trim();
    final targetType = (widget.categoryToEdit?.type ?? widget.activeType)
        .toUpperCase();

    // Instant client-side duplicate name check within the same type
    final existing = ref.read(categoryListProvider).value ?? const [];
    final duplicate = existing.any(
      (c) =>
          c.type.toUpperCase() == targetType &&
          c.id != widget.categoryToEdit?.id &&
          c.name.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      setState(() => _errorText = l10n.txCatDuplicateError);
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      CategoryDto saved;
      if (widget.categoryToEdit != null) {
        saved = await ref.read(categoryListProvider.notifier).updateCategory(
              id: widget.categoryToEdit!.id,
              name: trimmed,
              icon: _selectedIcon,
              color: _selectedColorHex,
            );
      } else {
        saved = await ref.read(categoryListProvider.notifier).createCategory(
              name: trimmed,
              type: targetType,
              icon: _selectedIcon,
              color: _selectedColorHex,
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop(saved);
      if (widget.parentContext.mounted) {
        AfabToast.showSuccess(
          widget.parentContext,
          widget.categoryToEdit != null
              ? l10n.txCatUpdatedToast
              : l10n.txCatCreatedToast,
        );
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.statusCode == 409 ? l10n.txCatDuplicateError : e.message;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorText != null) ...[
            AfabInsetPanel(
              borderColor: colors.danger.withValues(alpha: 0.45),
              child: Text(
                _errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.danger,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          AfabTextField(
            label: l10n.txCatNameLabel,
            controller: _nameCtrl,
            hintText: l10n.txCatNameHint,
            maxLength: 100,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.authFieldRequired
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.txCatColorLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final swatch in CategoryIconMapper.pickerColorSwatches)
                Semantics(
                  label: swatch.semanticName,
                  selected: _selectedColorHex.toUpperCase() ==
                      swatch.hex.toUpperCase(),
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => setState(() => _selectedColorHex = swatch.hex),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ColorParser.parseHex(swatch.hex, colors.primary),
                        shape: BoxShape.circle,
                        border: _selectedColorHex.toUpperCase() ==
                                swatch.hex.toUpperCase()
                            ? Border.all(color: colors.textPrimary, width: 2.5)
                            : null,
                      ),
                      child: _selectedColorHex.toUpperCase() ==
                              swatch.hex.toUpperCase()
                          ? const Icon(
                              LucideIcons.check,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.txCatIconLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final opt in CategoryIconMapper.pickerIcons)
                Semantics(
                  label: opt.name,
                  selected: _selectedIcon == opt.name,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedIcon = opt.name),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedIcon == opt.name
                            ? ColorParser.parseHex(
                                _selectedColorHex,
                                colors.primary,
                              ).withValues(alpha: 0.16)
                            : colors.surfaceInset,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedIcon == opt.name
                              ? ColorParser.parseHex(
                                  _selectedColorHex,
                                  colors.primary,
                                )
                              : colors.border,
                          width: _selectedIcon == opt.name ? 1.8 : 1,
                        ),
                      ),
                      child: Icon(
                        opt.icon,
                        size: 20,
                        color: _selectedIcon == opt.name
                            ? ColorParser.parseHex(
                                _selectedColorHex,
                                colors.primary,
                              )
                            : colors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: AfabButton(
                  label: l10n.commonCancel,
                  variant: AfabButtonVariant.secondary,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AfabButton(
                  label: widget.categoryToEdit != null
                      ? l10n.txFormSubmitEdit
                      : l10n.commonCreate,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
