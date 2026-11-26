import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/transaction_list_card.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<TransactionFilterState?> showTransactionFilterSheet(
  BuildContext context, {
  required TransactionFilterState current,
  required List<CategoryDto> categories,
}) {
  return showAfabBottomSheet<TransactionFilterState>(
    context: context,
    title: context.l10n.txFiltersTitle,
    builder: (sheetCtx) => _FilterSheetBody(
      initial: current,
      categories: categories,
    ),
  );
}

class _FilterSheetBody extends StatefulWidget {
  const _FilterSheetBody({
    required this.initial,
    required this.categories,
  });

  final TransactionFilterState initial;
  final List<CategoryDto> categories;

  @override
  State<_FilterSheetBody> createState() => _FilterSheetBodyState();
}

class _FilterSheetBodyState extends State<_FilterSheetBody> {
  TransactionType? _type;
  String? _categoryId;
  TransactionStatus? _status;
  PaymentMethod? _paymentMethod;
  bool _taxOnly = false;
  String? _startDate;
  String? _endDate;
  late TransactionPeriod _period;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _categoryId = widget.initial.categoryId;
    _status = widget.initial.status;
    _paymentMethod = widget.initial.paymentMethod;
    _taxOnly = widget.initial.taxDeductible == true;
    _startDate = widget.initial.startDate;
    _endDate = widget.initial.endDate;
    _period = widget.initial.period;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialRaw = isStart ? _startDate : _endDate;
    final parsed = initialRaw != null ? DateTime.tryParse(initialRaw) : null;
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
      locale: Localizations.localeOf(context),
    );
    if (picked == null || !mounted) return;
    final iso = DateFormat('yyyy-MM-dd', 'en_US').format(picked);
    setState(() {
      _period = TransactionPeriod.custom;
      if (isStart) {
        _startDate = iso;
      } else {
        _endDate = iso;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredCats = _type == null
        ? widget.categories
        : widget.categories
            .where((c) => c.type.toUpperCase() == _type!.apiValue)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.txFilterType, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.commonAll),
              selected: _type == null,
              onSelected: (_) => setState(() {
                _type = null;
              }),
            ),
            ChoiceChip(
              label: Text(l10n.txTypeIncome),
              selected: _type == TransactionType.income,
              onSelected: (_) => setState(() {
                _type = TransactionType.income;
                _categoryId = null;
              }),
            ),
            ChoiceChip(
              label: Text(l10n.txTypeExpense),
              selected: _type == TransactionType.expense,
              onSelected: (_) => setState(() {
                _type = TransactionType.expense;
                _categoryId = null;
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.txFilterStatus,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.commonAll),
              selected: _status == null,
              onSelected: (_) => setState(() => _status = null),
            ),
            for (final st in TransactionStatus.values)
              ChoiceChip(
                label: Text(localizedStatusLabel(context, st)),
                selected: _status == st,
                onSelected: (_) => setState(() => _status = st),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.txFilterPaymentMethod,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.commonAll),
              selected: _paymentMethod == null,
              onSelected: (_) => setState(() => _paymentMethod = null),
            ),
            for (final pm in PaymentMethod.values)
              ChoiceChip(
                label: Text(localizedPaymentMethodLabel(context, pm)),
                selected: _paymentMethod == pm,
                onSelected: (_) => setState(() => _paymentMethod = pm),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.txFilterCategory,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue:
              filteredCats.any((c) => c.id == _categoryId) ? _categoryId : null,
          decoration: const InputDecoration(isDense: true),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l10n.commonAll)),
            for (final c in filteredCats)
              DropdownMenuItem<String?>(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (val) => setState(() => _categoryId = val),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.txFilterDateRange,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: true),
                icon: const Icon(LucideIcons.calendarDays, size: 16),
                label: Text(_startDate ?? l10n.txFilterStartDate),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: false),
                icon: const Icon(LucideIcons.calendarDays, size: 16),
                label: Text(_endDate ?? l10n.txFilterEndDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.txFilterTaxDeductibleOnly),
          value: _taxOnly,
          onChanged: (v) => setState(() => _taxOnly = v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AfabButton(
                label: l10n.txFilterReset,
                variant: AfabButtonVariant.secondary,
                onPressed: () {
                  final (s, e) = resolveDatesForPeriod(TransactionPeriod.monthly);
                  Navigator.of(context).pop(
                    TransactionFilterState(
                      period: TransactionPeriod.monthly,
                      startDate: s,
                      endDate: e,
                      search: widget.initial.search,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AfabButton(
                label: l10n.txFilterApply,
                onPressed: () {
                  Navigator.of(context).pop(
                    TransactionFilterState(
                      period: _period,
                      startDate: _startDate,
                      endDate: _endDate,
                      search: widget.initial.search,
                      type: _type,
                      categoryId: _categoryId,
                      status: _status,
                      paymentMethod: _paymentMethod,
                      taxDeductible: _taxOnly ? true : null,
                      page: 0,
                      sortField: widget.initial.sortField,
                      sortAscending: widget.initial.sortAscending,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
