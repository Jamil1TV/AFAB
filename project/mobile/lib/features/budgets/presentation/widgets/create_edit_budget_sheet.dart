import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/budgets/data/budget_dtos.dart';
import 'package:afab_mobile/features/budgets/data/budgets_repository.dart';
import 'package:afab_mobile/features/budgets/domain/budgets_providers.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/invoices/domain/invoice_calculator.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<BudgetDto?> showCreateEditBudgetSheet(
  BuildContext context, {
  BudgetDto? editingBudget,
}) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<BudgetDto>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _CreateEditBudgetForm(
              editingBudget: editingBudget,
              showDialogHeader: true,
            ),
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<BudgetDto>(
    context: context,
    title: editingBudget == null
        ? context.l10n.budgetsNewBtn
        : context.l10n.budgetsEditTitle,
    builder: (ctx) => _CreateEditBudgetForm(
      editingBudget: editingBudget,
      showDialogHeader: false,
    ),
  );
}

class _CreateEditBudgetForm extends ConsumerStatefulWidget {
  const _CreateEditBudgetForm({
    this.editingBudget,
    required this.showDialogHeader,
  });

  final BudgetDto? editingBudget;
  final bool showDialogHeader;

  @override
  ConsumerState<_CreateEditBudgetForm> createState() =>
      _CreateEditBudgetFormState();
}

class _CreateEditBudgetFormState extends ConsumerState<_CreateEditBudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _thresholdCtrl;
  late final TextEditingController _descCtrl;

  String? _categoryId;
  late String _periodType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  String? _serverError;

  static const _periods = ['MONTHLY', 'QUARTERLY', 'YEARLY', 'CUSTOM'];

  @override
  void initState() {
    super.initState();
    final b = widget.editingBudget;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _amountCtrl = TextEditingController(
      text: b != null ? b.budgetAmount.toString() : '',
    );
    _thresholdCtrl = TextEditingController(
      text: (b?.alertThresholdPercent ?? 80).toString(),
    );
    _descCtrl = TextEditingController(text: b?.description ?? '');
    _categoryId = b?.categoryId;
    _periodType = _periods.contains(b?.periodType) ? b!.periodType : 'MONTHLY';
    if (b != null) {
      _startDate = DateTime.tryParse(b.startDate);
      _endDate = DateTime.tryParse(b.endDate);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _thresholdCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onPeriodChanged(String nextPeriod) {
    setState(() {
      if (nextPeriod != _periodType && nextPeriod != 'CUSTOM') {
        // Clear old dates so backend auto-calculates the new window cleanly.
        _startDate = null;
        _endDate = null;
      }
      _periodType = nextPeriod;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = context.l10n;
    if (_periodType == 'CUSTOM' && (_startDate == null || _endDate == null)) {
      setState(() => _serverError = l10n.budgetsCustomDatesRequired);
      return;
    }
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(() => _serverError = l10n.budgetsEndBeforeStart);
      return;
    }

    final amount = InvoiceCalculator.parseNormalized(_amountCtrl.text);
    final threshold = int.tryParse(_thresholdCtrl.text.trim());
    if (amount == null || threshold == null) return;

    setState(() {
      _submitting = true;
      _serverError = null;
    });

    final bizCurrency = widget.editingBudget?.currency ??
        ref.read(activeBusinessProvider)?.currency ??
        'USD';
    final fmt = DateFormat('yyyy-MM-dd', 'en_US');

    final request = BudgetRequestDto(
      name: _nameCtrl.text,
      amount: amount,
      currency: bizCurrency,
      categoryId: _categoryId,
      periodType: _periodType,
      startDate: _startDate != null ? fmt.format(_startDate!) : null,
      endDate: _endDate != null ? fmt.format(_endDate!) : null,
      alertThresholdPercent: threshold,
      description: _descCtrl.text,
    );

    try {
      final repo = ref.read(budgetsRepositoryProvider);
      final saved = widget.editingBudget == null
          ? await repo.createBudget(request)
          : await repo.updateBudget(widget.editingBudget!.id, request);
      if (!mounted) return;
      invalidateBudgetProviders(ref);
      AfabToast.showSuccess(context, l10n.budgetsSavedToast);
      Navigator.of(context).pop(saved);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _serverError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final currency = widget.editingBudget?.currency ?? biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;
    final expenseCategories = ref.watch(expenseCategoriesProvider);

    String periodLabel(String p) => switch (p) {
          'QUARTERLY' => l10n.budgetsPeriodQuarterly,
          'YEARLY' => l10n.budgetsPeriodYearly,
          'CUSTOM' => l10n.budgetsPeriodCustom,
          _ => l10n.budgetsPeriodMonthly,
        };

    final validCat = expenseCategories.any((c) => c.id == _categoryId)
        ? _categoryId
        : null;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showDialogHeader) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.editingBudget == null
                        ? l10n.budgetsNewBtn
                        : l10n.budgetsEditTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, color: colors.textMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_serverError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                _serverError!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.danger),
              ),
            ),
            const SizedBox(height: 12),
          ],
          AfabTextField(
            label: l10n.budgetsFieldName,
            hintText: l10n.budgetsFieldNameHint,
            controller: _nameCtrl,
            maxLength: 150,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.authFieldRequired : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AfabTextField(
                  label: l10n.budgetsFieldAmount(currency),
                  controller: _amountCtrl,
                  forceLtr: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final d = InvoiceCalculator.parseNormalized(v ?? '');
                    if (d == null || d < InvoiceCalculator.minPositive) {
                      return l10n.txFormAmountInvalid;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AfabTextField(
                  label: l10n.budgetsFieldThreshold,
                  controller: _thresholdCtrl,
                  forceLtr: true,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final pct = int.tryParse((v ?? '').trim());
                    if (pct == null || pct < 1 || pct > 100) {
                      return l10n.budgetsThresholdInvalid;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: validCat,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.budgetsFieldCategory,
              isDense: true,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(l10n.budgetsAllBusinessExpenses),
              ),
              for (final c in expenseCategories)
                DropdownMenuItem<String?>(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _periodType,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.budgetsFieldPeriod,
              isDense: true,
            ),
            items: [
              for (final p in _periods)
                DropdownMenuItem(value: p, child: Text(periodLabel(p))),
            ],
            onChanged: (v) {
              if (v != null) _onPeriodChanged(v);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isStart: true),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _periodType == 'CUSTOM'
                          ? '${l10n.txFilterStartDate} *'
                          : l10n.txFilterStartDate,
                      isDense: true,
                      suffixIcon: _startDate != null
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 14),
                              onPressed: () =>
                                  setState(() => _startDate = null),
                            )
                          : const Icon(LucideIcons.calendar, size: 16),
                    ),
                    child: Text(
                      _startDate != null
                          ? AfabDateFormatter.formatDateTime(
                              _startDate!,
                              dateFormat: dateFmt,
                              locale: locale,
                            )
                          : '—',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(isStart: false),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _periodType == 'CUSTOM'
                          ? '${l10n.txFilterEndDate} *'
                          : l10n.txFilterEndDate,
                      isDense: true,
                      suffixIcon: _endDate != null
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 14),
                              onPressed: () => setState(() => _endDate = null),
                            )
                          : const Icon(LucideIcons.calendar, size: 16),
                    ),
                    child: Text(
                      _endDate != null
                          ? AfabDateFormatter.formatDateTime(
                              _endDate!,
                              dateFormat: dateFmt,
                              locale: locale,
                            )
                          : '—',
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_periodType != 'CUSTOM') ...[
            const SizedBox(height: 4),
            Text(
              l10n.budgetsAutoDateHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          AfabTextField(
            label: l10n.txFormNotesLabel,
            controller: _descCtrl,
            maxLength: 1000,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AfabButton(
                  label: l10n.commonCancel,
                  variant: AfabButtonVariant.secondary,
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AfabButton(
                  label: l10n.commonSave,
                  isLoading: _submitting,
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
