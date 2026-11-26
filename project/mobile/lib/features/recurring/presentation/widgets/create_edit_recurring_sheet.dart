import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/invoices/domain/invoice_calculator.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:afab_mobile/features/recurring/data/recurring_repository.dart';
import 'package:afab_mobile/features/recurring/domain/recurring_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<RecurringTransactionDto?> showCreateEditRecurringSheet(
  BuildContext context, {
  RecurringTransactionDto? editingRule,
}) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<RecurringTransactionDto>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 740),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _CreateEditRecurringForm(
              editingRule: editingRule,
              showDialogHeader: true,
            ),
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<RecurringTransactionDto>(
    context: context,
    title: editingRule == null
        ? context.l10n.recurringNewBtn
        : context.l10n.recurringEditTitle,
    builder: (ctx) => _CreateEditRecurringForm(
      editingRule: editingRule,
      showDialogHeader: false,
    ),
  );
}

class _CreateEditRecurringForm extends ConsumerStatefulWidget {
  const _CreateEditRecurringForm({
    this.editingRule,
    required this.showDialogHeader,
  });

  final RecurringTransactionDto? editingRule;
  final bool showDialogHeader;

  @override
  ConsumerState<_CreateEditRecurringForm> createState() =>
      _CreateEditRecurringFormState();
}

class _CreateEditRecurringFormState
    extends ConsumerState<_CreateEditRecurringForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;

  late String _type;
  late String _frequency;
  late String _currency;
  String? _categoryId;
  late String _paymentMethod;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  String? _serverError;

  static const _frequencies = ['WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY'];
  static const _methods = [
    'BANK_TRANSFER',
    'CARD',
    'CREDIT_CARD',
    'CASH',
    'OTHER',
  ];
  static const _currencies = [
    'USD',
    'EUR',
    'GBP',
    'TND',
    'CAD',
    'MAD',
    'AED',
    'SAR',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.editingRule;
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _amountCtrl = TextEditingController(
      text: r != null ? r.amount.toString() : '',
    );
    _notesCtrl = TextEditingController(text: r?.notes ?? '');

    _type = r?.type ?? 'EXPENSE';
    _frequency = _frequencies.contains(r?.frequency) ? r!.frequency : 'MONTHLY';
    _currency =
        r?.currency ?? ref.read(activeBusinessProvider)?.currency ?? 'USD';
    _categoryId = r?.categoryId;
    _paymentMethod =
        _methods.contains(r?.paymentMethod) ? r!.paymentMethod : 'BANK_TRANSFER';
    _startDate = (r != null ? DateTime.tryParse(r.startDate) : null) ??
        DateTime.now();
    _endDate = r?.endDate != null ? DateTime.tryParse(r!.endDate!) : null;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? _startDate
        : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isStart ? DateTime(2000) : _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      setState(() => _serverError = context.l10n.budgetsEndBeforeStart);
      return;
    }

    final amount = InvoiceCalculator.parseNormalized(_amountCtrl.text);
    if (amount == null) return;

    setState(() {
      _submitting = true;
      _serverError = null;
    });

    final fmt = DateFormat('yyyy-MM-dd', 'en_US');
    final request = RecurringTransactionRequestDto(
      type: _type,
      description: _descCtrl.text,
      amount: amount,
      currency: _currency,
      categoryId: _categoryId,
      paymentMethod: _paymentMethod,
      frequency: _frequency,
      startDate: fmt.format(_startDate),
      endDate: _endDate != null ? fmt.format(_endDate!) : null,
      active: widget.editingRule?.active ?? true,
      notes: _notesCtrl.text,
    );

    try {
      final repo = ref.read(recurringRepositoryProvider);
      final saved = widget.editingRule == null
          ? await repo.createRule(request)
          : await repo.updateRule(widget.editingRule!.id, request);
      if (!mounted) return;
      ref.invalidate(recurringListProvider);
      AfabToast.showSuccess(context, context.l10n.recurringSavedToast);
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
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final categories = _type == 'INCOME'
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);
    final validCat =
        categories.any((c) => c.id == _categoryId) ? _categoryId : null;

    final currencies = {
      _currency.toUpperCase(),
      if (biz != null) biz.currency.toUpperCase(),
      ..._currencies,
    }.toList();

    String freqLabel(String f) => switch (f) {
          'WEEKLY' => l10n.recurringFreqWeekly,
          'QUARTERLY' => l10n.recurringFreqQuarterly,
          'YEARLY' => l10n.recurringFreqYearly,
          _ => l10n.recurringFreqMonthly,
        };

    String methodLabel(String m) => switch (m) {
          'CARD' => l10n.txMethodCard,
          'CREDIT_CARD' => l10n.txMethodCreditCard,
          'CASH' => l10n.txMethodCash,
          'OTHER' => l10n.txMethodOther,
          _ => l10n.txMethodBankTransfer,
        };

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
                    widget.editingRule == null
                        ? l10n.recurringNewBtn
                        : l10n.recurringEditTitle,
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

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.txFilterType,
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'EXPENSE',
                      child: Text(l10n.txTypeExpense),
                    ),
                    DropdownMenuItem(
                      value: 'INCOME',
                      child: Text(l10n.txTypeIncome),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null && v != _type) {
                      setState(() {
                        _type = v;
                        // Clear mismatched category immediately when type flips.
                        _categoryId = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.recurringFieldFrequency,
                    isDense: true,
                  ),
                  items: [
                    for (final f in _frequencies)
                      DropdownMenuItem(value: f, child: Text(freqLabel(f))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _frequency = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          AfabTextField(
            label: '${l10n.txFormDescriptionLabel} *',
            hintText: l10n.txFormDescriptionHint,
            controller: _descCtrl,
            maxLength: 255,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.authFieldRequired : null,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: AfabTextField(
                  label: '${l10n.txFormAmountLabel} *',
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
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.txFormCurrencyLabel,
                    isDense: true,
                  ),
                  items: [
                    for (final c in currencies)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _currency = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: validCat,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.txFilterCategory,
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.txDetailsUncategorized),
                    ),
                    for (final c in categories)
                      DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.txFilterPaymentMethod,
                    isDense: true,
                  ),
                  items: [
                    for (final m in _methods)
                      DropdownMenuItem(value: m, child: Text(methodLabel(m))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _paymentMethod = v);
                  },
                ),
              ),
            ],
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
                      labelText: '${l10n.txFilterStartDate} *',
                      isDense: true,
                      suffixIcon: const Icon(LucideIcons.calendar, size: 16),
                    ),
                    child: Text(
                      AfabDateFormatter.formatDateTime(
                        _startDate,
                        dateFormat: dateFmt,
                        locale: locale,
                      ),
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
                      labelText: l10n.recurringFieldEndDate,
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
          const SizedBox(height: 12),

          AfabTextField(
            label: l10n.txFormNotesLabel,
            controller: _notesCtrl,
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
