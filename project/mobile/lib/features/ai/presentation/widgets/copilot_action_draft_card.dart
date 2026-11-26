import 'dart:typed_data';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/data/ai_repository.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/invoices/domain/invoice_calculator.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CopilotActionDraftCard extends ConsumerStatefulWidget {
  const CopilotActionDraftCard({
    super.key,
    required this.messageId,
    required this.draft,
    required this.isReadOnly,
    required this.onUpdated,
  });

  final String messageId;
  final AiActionDraftDto draft;
  final bool isReadOnly;
  final ValueChanged<AiActionDraftDto> onUpdated;

  @override
  ConsumerState<CopilotActionDraftCard> createState() =>
      _CopilotActionDraftCardState();
}

class _CopilotActionDraftCardState
    extends ConsumerState<CopilotActionDraftCard> {
  bool _saving = false;
  bool _dismissing = false;
  Uint8List? _receiptPreviewBytes;

  // CREATE_TRANSACTION state
  late String _txType;
  late final TextEditingController _txAmountCtrl;
  late final TextEditingController _txCurrencyCtrl;
  late final TextEditingController _txDescCtrl;
  late String _txDate;
  late String _txCategoryId;
  late String _txMethod;
  late final TextEditingController _txNotesCtrl;

  // CREATE_INVOICE state
  late String _invCustomerId;
  late String _invIssueDate;
  late String _invDueDate;
  late String _invCurrency;
  late final TextEditingController _invNotesCtrl;
  bool _invIssueImmediately = false;

  // CREATE_BUDGET state
  late final TextEditingController _budNameCtrl;
  late final TextEditingController _budAmountCtrl;
  late String _budCategoryId;
  late String _budPeriod;
  late final TextEditingController _budAlertCtrl;

  static const _paymentMethods = [
    'CASH',
    'CARD',
    'BANK_TRANSFER',
    'CREDIT_CARD',
    'OTHER',
  ];

  static const _budgetPeriods = ['MONTHLY', 'QUARTERLY', 'YEARLY', 'CUSTOM'];

  @override
  void initState() {
    super.initState();
    final p = widget.draft.payload;
    final todayIso = DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now());
    final in30DaysIso = DateFormat('yyyy-MM-dd', 'en_US').format(
      DateTime.now().add(const Duration(days: 30)),
    );

    _txType = (p['type'] ?? 'EXPENSE').toString().toUpperCase();
    if (_txType != 'INCOME' && _txType != 'EXPENSE') _txType = 'EXPENSE';
    _txAmountCtrl = TextEditingController(text: '${p['amount'] ?? ''}');
    _txCurrencyCtrl = TextEditingController(
      text: (p['currency'] ?? 'USD').toString().toUpperCase(),
    );
    _txDescCtrl = TextEditingController(
      text: (p['description'] ?? '').toString(),
    );
    _txDate = (p['transactionDate'] ?? todayIso).toString();
    _txCategoryId = (p['categoryId'] ?? '').toString();
    final rawMethod =
        (p['paymentMethod'] ?? 'BANK_TRANSFER').toString().toUpperCase();
    _txMethod =
        _paymentMethods.contains(rawMethod) ? rawMethod : 'BANK_TRANSFER';
    _txNotesCtrl = TextEditingController(text: (p['notes'] ?? '').toString());

    _invCustomerId = (p['customerId'] ?? '').toString();
    _invIssueDate = (p['issueDate'] ?? todayIso).toString();
    _invDueDate = (p['dueDate'] ?? in30DaysIso).toString();
    _invCurrency = (p['currency'] ?? 'USD').toString().toUpperCase();
    _invNotesCtrl = TextEditingController(text: (p['notes'] ?? '').toString());

    _budNameCtrl = TextEditingController(text: (p['name'] ?? '').toString());
    _budAmountCtrl = TextEditingController(text: '${p['amount'] ?? ''}');
    _budCategoryId = (p['categoryId'] ?? '').toString();
    final rawPeriod = (p['periodType'] ?? 'MONTHLY').toString().toUpperCase();
    _budPeriod = _budgetPeriods.contains(rawPeriod) ? rawPeriod : 'MONTHLY';
    _budAlertCtrl = TextEditingController(
      text: '${p['alertThresholdPercent'] ?? 80}',
    );

    _loadStagedPreview();
  }

  @override
  void dispose() {
    _txAmountCtrl.dispose();
    _txCurrencyCtrl.dispose();
    _txDescCtrl.dispose();
    _txNotesCtrl.dispose();
    _invNotesCtrl.dispose();
    _budNameCtrl.dispose();
    _budAmountCtrl.dispose();
    _budAlertCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStagedPreview() async {
    final attId = widget.draft.stagedAttachmentId;
    if (attId == null ||
        attId.isEmpty ||
        widget.draft.status != 'PENDING') {
      return;
    }
    try {
      final bytes =
          await ref.read(aiRepositoryProvider).fetchAttachmentPreview(attId);
      if (mounted && bytes.isNotEmpty) {
        setState(() => _receiptPreviewBytes = bytes);
      }
    } catch (_) {
      // Optional receipt preview fallback.
    }
  }

  Future<void> _pickIsoDate(
    String currentIso,
    ValueChanged<String> onSelected,
  ) async {
    final initial = DateTime.tryParse(currentIso) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      onSelected(DateFormat('yyyy-MM-dd', 'en_US').format(picked));
    }
  }

  Future<void> _dismiss() async {
    if (_saving || _dismissing || widget.isReadOnly) return;
    setState(() => _dismissing = true);
    try {
      final updated = await ref.read(aiRepositoryProvider).dismissDraft(
            messageId: widget.messageId,
            draftId: widget.draft.draftId,
          );
      if (mounted) widget.onUpdated(updated);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (_) {
      if (mounted) AfabToast.showError(context, context.l10n.aiDraftDismissFailed);
    } finally {
      if (mounted) setState(() => _dismissing = false);
    }
  }

  Future<void> _approve() async {
    if (_saving || _dismissing || widget.isReadOnly) return;
    final l10n = context.l10n;
    final repo = ref.read(aiRepositoryProvider);
    final p = widget.draft.payload;

    setState(() => _saving = true);
    try {
      late final AiActionDraftDto updated;
      if (widget.draft.actionType == 'CREATE_TRANSACTION') {
        final dec = InvoiceCalculator.parseNormalized(_txAmountCtrl.text);
        if (dec == null || dec <= Decimal.zero) {
          AfabToast.showError(context, l10n.aiDraftInvalidAmount);
          return;
        }
        final cats = ref.read(categoryListProvider).value ?? const <CategoryDto>[];
        final validCat = cats.any((c) => c.id == _txCategoryId)
            ? (_txCategoryId.isEmpty ? null : _txCategoryId)
            : null;
        final curr = _txCurrencyCtrl.text.trim().toUpperCase();
        updated = await repo.approveTransactionDraft({
          'messageId': widget.messageId,
          'draftId': widget.draft.draftId,
          'type': _txType,
          'amount': double.parse(dec.toString()),
          'originalCurrency': curr.length == 3 ? curr : 'USD',
          'description':
              _txDescCtrl.text.trim().isEmpty ? 'Transaction' : _txDescCtrl.text.trim(),
          'transactionDate': _txDate,
          'categoryId': ?validCat,
          'paymentMethod': _txMethod,
          'status': 'COMPLETED',
          'notes': _txNotesCtrl.text.trim(),
          if (widget.draft.stagedAttachmentId != null)
            'stagedAttachmentId': widget.draft.stagedAttachmentId,
          if (p['extractedOcrText'] is String)
            'extractedOcrText': p['extractedOcrText'],
        });
      } else if (widget.draft.actionType == 'CREATE_INVOICE') {
        final rawItems = p['items'] is List ? (p['items'] as List) : const [];
        final items = rawItems
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (it) => {
                'description': (it['description'] ?? 'Services').toString(),
                'quantity': (it['quantity'] as num?)?.toDouble() ?? 1.0,
                'unitPrice': (it['unitPrice'] as num?)?.toDouble() ?? 0.0,
                'taxRate': (it['taxRate'] as num?)?.toDouble() ?? 0.0,
              },
            )
            .toList();
        final custs =
            ref.read(aiCustomersDropdownProvider).value ?? const <CustomerDto>[];
        final validCust = custs.any((c) => c.id == _invCustomerId)
            ? (_invCustomerId.isEmpty ? null : _invCustomerId)
            : null;
        updated = await repo.approveInvoiceDraft({
          'messageId': widget.messageId,
          'draftId': widget.draft.draftId,
          'customerId': ?validCust,
          'issueDate': _invIssueDate,
          'dueDate': _invDueDate,
          'currency': _invCurrency,
          'discountAmount': (p['discountAmount'] as num?)?.toDouble() ?? 0.0,
          'notes': _invNotesCtrl.text.trim(),
          'issueImmediately': _invIssueImmediately,
          'items': items,
        });
      } else {
        final dec = InvoiceCalculator.parseNormalized(_budAmountCtrl.text);
        if (dec == null || dec <= Decimal.zero) {
          AfabToast.showError(context, l10n.aiDraftInvalidAmount);
          return;
        }
        final cats = ref.read(categoryListProvider).value ?? const <CategoryDto>[];
        final validCat = cats.any((c) => c.id == _budCategoryId)
            ? (_budCategoryId.isEmpty ? null : _budCategoryId)
            : null;
        final threshold = (int.tryParse(_budAlertCtrl.text.trim()) ?? 80)
            .clamp(10, 100);
        updated = await repo.approveBudgetDraft({
          'messageId': widget.messageId,
          'draftId': widget.draft.draftId,
          'name':
              _budNameCtrl.text.trim().isEmpty ? 'Budget' : _budNameCtrl.text.trim(),
          'amount': double.parse(dec.toString()),
          'categoryId': ?validCat,
          'periodType': _budPeriod,
          'alertThresholdPercent': threshold,
        });
      }

      if (!mounted) return;
      AfabToast.showSuccess(context, l10n.aiDraftApprovedToast);
      widget.onUpdated(updated);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (_) {
      if (mounted) AfabToast.showError(context, l10n.aiDraftApproveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    if (widget.draft.status == 'APPROVED') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.successBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.circleCheck, size: 18, color: colors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.aiDraftSavedBadge} · ${widget.draft.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.success,
                        ),
                  ),
                  Text(
                    widget.draft.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (widget.draft.createdEntityHref != null &&
                widget.draft.createdEntityHref!.isNotEmpty) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => context.go(
                  mapWebHrefToMobileRoute(widget.draft.createdEntityHref),
                ),
                icon: const Icon(LucideIcons.arrowUpRight, size: 14),
                label: Text(l10n.aiDraftViewRecord),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (widget.draft.status == 'DISMISSED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceInset,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          '${l10n.aiDraftDismissedBadge} · ${widget.draft.title}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final categories =
        ref.watch(categoryListProvider).value ?? const <CategoryDto>[];
    final customers =
        ref.watch(aiCustomersDropdownProvider).value ?? const <CustomerDto>[];

    return AfabInsetPanel(
      borderColor: colors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.shieldAlert,
                  size: 16,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.aiDraftPendingReview} · ${widget.draft.title}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiDraftReviewHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.aiDraftDismiss,
                onPressed:
                    (_saving || _dismissing || widget.isReadOnly) ? null : _dismiss,
                icon: const Icon(LucideIcons.x, size: 16),
              ),
            ],
          ),
          if (_receiptPreviewBytes != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _receiptPreviewBytes!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aiDraftReceiptLinked,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          l10n.aiDraftReceiptWillSave,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (widget.draft.actionType == 'CREATE_TRANSACTION')
            _buildTxForm(l10n, categories)
          else if (widget.draft.actionType == 'CREATE_INVOICE')
            _buildInvoiceForm(l10n, colors, customers)
          else
            _buildBudgetForm(l10n, categories),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              AfabButton(
                label: l10n.aiDraftDismiss,
                variant: AfabButtonVariant.secondary,
                compact: true,
                onPressed: (_saving || _dismissing || widget.isReadOnly)
                    ? null
                    : _dismiss,
              ),
              AfabButton(
                label: _saving ? l10n.aiDraftSaving : l10n.aiDraftApproveSave,
                icon: LucideIcons.check,
                compact: true,
                isLoading: _saving,
                onPressed:
                    (_saving || _dismissing || widget.isReadOnly) ? null : _approve,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTxForm(AppLocalizations l10n, List<CategoryDto> allCategories) {
    final filtered = allCategories
        .where((c) => c.type.toUpperCase() == _txType)
        .toList();
    final effectiveCat =
        filtered.any((c) => c.id == _txCategoryId) ? _txCategoryId : '';

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _txType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.aiDraftType,
            isDense: true,
          ),
          items: [
            DropdownMenuItem(value: 'EXPENSE', child: Text(l10n.txTypeExpense)),
            DropdownMenuItem(value: 'INCOME', child: Text(l10n.txTypeIncome)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _txType = v);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _txAmountCtrl,
                textDirection: TextDirection.ltr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.aiDraftAmount,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _txCurrencyCtrl,
                textDirection: TextDirection.ltr,
                maxLength: 3,
                decoration: InputDecoration(
                  labelText: l10n.aiDraftCurrency,
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _txDescCtrl,
          maxLength: 255,
          decoration: InputDecoration(
            labelText: l10n.aiDraftDescription,
            counterText: '',
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _pickIsoDate(_txDate, (d) => setState(() => _txDate = d)),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.aiDraftDate,
              isDense: true,
              suffixIcon: const Icon(LucideIcons.calendar, size: 16),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(_txDate),
            ),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey('tx_cat_${_txType}_$effectiveCat'),
          initialValue: effectiveCat,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.aiDraftCategory,
            isDense: true,
          ),
          items: [
            DropdownMenuItem(value: '', child: Text(l10n.txDetailsUncategorized)),
            for (final c in filtered)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _txCategoryId = v ?? ''),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _txMethod,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.aiDraftPaymentMethod,
            isDense: true,
          ),
          items: [
            for (final m in _paymentMethods)
              DropdownMenuItem(value: m, child: Text(m)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _txMethod = v);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _txNotesCtrl,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: l10n.aiDraftNotes,
            counterText: '',
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceForm(
    AppLocalizations l10n,
    AfabColors colors,
    List<CustomerDto> customers,
  ) {
    final p = widget.draft.payload;
    final rawItems = p['items'] is List ? (p['items'] as List) : const [];
    final effectiveCust =
        customers.any((c) => c.id == _invCustomerId) ? _invCustomerId : '';
    final total = MoneyFormatter.parseDecimal(p['totalAmount']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('inv_cust_$effectiveCust'),
          initialValue: effectiveCust,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.aiDraftCustomer,
            isDense: true,
          ),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(
                (p['customerName'] ?? l10n.txDetailsUncategorized).toString(),
              ),
            ),
            for (final c in customers)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _invCustomerId = v ?? ''),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickIsoDate(
                  _invIssueDate,
                  (d) => setState(() => _invIssueDate = d),
                ),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.aiDraftIssueDate,
                    isDense: true,
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(_invIssueDate),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _pickIsoDate(
                  _invDueDate,
                  (d) => setState(() => _invDueDate = d),
                ),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.aiDraftDueDate,
                    isDense: true,
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(_invDueDate),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (final raw in rawItems.whereType<Map<dynamic, dynamic>>())
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${raw['description'] ?? ''} × ${raw['quantity'] ?? 1}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyText(
                        amount: MoneyFormatter.parseDecimal(raw['unitPrice']) *
                            MoneyFormatter.parseDecimal(raw['quantity'] ?? 1),
                        currency: _invCurrency,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              Divider(height: 14, color: colors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.aiDraftTotal,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  MoneyText(
                    amount: total,
                    currency: _invCurrency,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          value: _invIssueImmediately,
          onChanged: (v) => setState(() => _invIssueImmediately = v ?? false),
          title: Text(
            l10n.aiDraftIssueImmediately,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        TextField(
          controller: _invNotesCtrl,
          decoration: InputDecoration(
            labelText: l10n.aiDraftNotes,
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetForm(
    AppLocalizations l10n,
    List<CategoryDto> allCategories,
  ) {
    final expenseCats = allCategories.where((c) => c.isExpense).toList();
    final effectiveCat =
        expenseCats.any((c) => c.id == _budCategoryId) ? _budCategoryId : '';

    return Column(
      children: [
        TextField(
          controller: _budNameCtrl,
          maxLength: 150,
          decoration: InputDecoration(
            labelText: l10n.aiDraftBudgetName,
            counterText: '',
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _budAmountCtrl,
                textDirection: TextDirection.ltr,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.aiDraftAmount,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _budAlertCtrl,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.aiDraftAlertPct,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey('bud_cat_$effectiveCat'),
          initialValue: effectiveCat,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.aiDraftCategory,
            isDense: true,
          ),
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(l10n.budgetsAllBusinessExpenses),
            ),
            for (final c in expenseCats)
              DropdownMenuItem(value: c.id, child: Text(c.name)),
          ],
          onChanged: (v) => setState(() => _budCategoryId = v ?? ''),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _budPeriod,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.aiDraftPeriod,
            isDense: true,
          ),
          items: [
            for (final p in _budgetPeriods)
              DropdownMenuItem(value: p, child: Text(p)),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _budPeriod = v);
          },
        ),
      ],
    );
  }
}
