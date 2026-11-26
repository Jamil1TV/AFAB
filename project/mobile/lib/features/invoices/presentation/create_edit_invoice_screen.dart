import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/features/customers/presentation/widgets/customer_picker_sheet.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/invoices/domain/invoice_calculator.dart';
import 'package:afab_mobile/features/invoices/domain/invoices_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum InvoiceFormMode { create, edit }

class _LineItemControllers {
  _LineItemControllers({
    String description = '',
    String quantity = '1',
    String unitPrice = '',
    String taxRate = '0',
  })  : descCtrl = TextEditingController(text: description),
        qtyCtrl = TextEditingController(text: quantity),
        priceCtrl = TextEditingController(text: unitPrice),
        taxCtrl = TextEditingController(text: taxRate);

  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController taxCtrl;

  InvoiceLineInput toInput() => InvoiceLineInput(
        description: descCtrl.text,
        quantity: qtyCtrl.text,
        unitPrice: priceCtrl.text,
        taxRate: taxCtrl.text,
      );

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    taxCtrl.dispose();
  }
}

/// Screen `BIZ-05`: Multi-item Draft Invoice Builder & Editor.
class CreateEditInvoiceScreen extends ConsumerStatefulWidget {
  const CreateEditInvoiceScreen({
    super.key,
    required this.mode,
    this.invoiceId,
    this.initialInvoice,
    this.initialCustomerId,
  });

  final InvoiceFormMode mode;
  final String? invoiceId;
  final InvoiceDto? initialInvoice;
  final String? initialCustomerId;

  @override
  ConsumerState<CreateEditInvoiceScreen> createState() =>
      _CreateEditInvoiceScreenState();
}

class _CreateEditInvoiceScreenState
    extends ConsumerState<CreateEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final List<_LineItemControllers> _lines = [];

  String? _customerId;
  String? _customerLabel;
  late String _currency;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  bool _loadingDraft = false;
  bool _nonDraftLocked = false;
  bool _isDirty = false;
  bool _submitting = false;
  String? _serverError;
  InvoiceDto? _loadedDraft;

  static const _commonCurrencies = [
    'USD',
    'EUR',
    'TND',
    'GBP',
    'AED',
    'SAR',
    'CAD',
    'CHF',
    'QAR',
    'KWD',
    'MAD',
  ];

  @override
  void initState() {
    super.initState();
    _currency = ref.read(activeBusinessProvider)?.currency ?? 'USD';

    if (widget.mode == InvoiceFormMode.edit) {
      if (widget.initialInvoice != null) {
        _hydrateFromDraft(widget.initialInvoice!);
      } else if (widget.invoiceId != null) {
        _fetchDraft(widget.invoiceId!);
      }
    } else {
      _lines.add(_LineItemControllers());
      if (widget.initialCustomerId != null &&
          widget.initialCustomerId!.isNotEmpty) {
        _prefetchCustomer(widget.initialCustomerId!);
      }
    }
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _prefetchCustomer(String id) async {
    try {
      final c = await ref.read(customersRepositoryProvider).getCustomerById(id);
      if (!mounted) return;
      setState(() {
        _customerId = c.id;
        _customerLabel = c.customerCode.isNotEmpty
            ? '${c.name} (${c.customerCode})'
            : c.name;
      });
    } catch (_) {
      // Optional prefill; leave unselected on failure.
    }
  }

  Future<void> _fetchDraft(String id) async {
    setState(() => _loadingDraft = true);
    try {
      final inv = await ref.read(invoicesRepositoryProvider).getInvoiceById(id);
      if (!mounted) return;
      _hydrateFromDraft(inv);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDraft = false;
        _serverError = e.message;
      });
    }
  }

  void _hydrateFromDraft(InvoiceDto inv) {
    for (final l in _lines) {
      l.dispose();
    }
    _lines.clear();

    _loadedDraft = inv;
    _nonDraftLocked = inv.status != InvoiceStatus.draft;
    _customerId = inv.customerId;
    _customerLabel = inv.customerName;
    _currency = inv.currency;
    _issueDate = DateTime.tryParse(inv.issueDate) ?? _issueDate;
    _dueDate = DateTime.tryParse(inv.dueDate) ?? _dueDate;
    _discountCtrl.text = inv.discountAmount.toString();
    _notesCtrl.text = inv.notes ?? '';
    if (inv.items.isEmpty) {
      _lines.add(_LineItemControllers());
    } else {
      for (final item in inv.items) {
        _lines.add(
          _LineItemControllers(
            description: item.description,
            quantity: item.quantity.toString(),
            unitPrice: item.unitPrice.toString(),
            taxRate: item.taxRate.toString(),
          ),
        );
      }
    }
    setState(() {
      _loadingDraft = false;
      _isDirty = false;
    });
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    } else {
      setState(() {});
    }
  }

  Future<void> _pickCustomer() async {
    final result = await showCustomerPickerSheet(
      context,
      selectedCustomerId: _customerId,
    );
    if (result == null || !mounted) return;
    setState(() {
      _customerId = result.customer?.id;
      _customerLabel = result.customer == null
          ? null
          : (result.customer!.customerCode.isNotEmpty
              ? '${result.customer!.name} (${result.customer!.customerCode})'
              : result.customer!.name);
      _isDirty = true;
    });
  }

  Future<void> _pickIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _issueDate = picked;
        if (_dueDate.isBefore(_issueDate)) {
          _dueDate = _issueDate;
        }
        _isDirty = true;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(_issueDate) ? _issueDate : _dueDate,
      firstDate: _issueDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = picked;
        _isDirty = true;
      });
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(_LineItemControllers());
      _isDirty = true;
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    final removed = _lines.removeAt(index);
    removed.dispose();
    setState(() => _isDirty = true);
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonDiscardTitle),
        content: Text(l10n.commonDiscardDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDiscardConfirm),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<void> _submit() async {
    if (_nonDraftLocked) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final preview = InvoiceCalculator.computeTotals(
      items: _lines.map((l) => l.toInput()).toList(),
      discountRaw: _discountCtrl.text,
    );
    if (preview.discountExceedsTotal) {
      setState(
        () => _serverError = context.l10n.invoicesFormDiscountExceedsError,
      );
      return;
    }

    setState(() {
      _submitting = true;
      _serverError = null;
    });

    final fmt = DateFormat('yyyy-MM-dd', 'en_US');
    final request = CreateInvoiceRequestDto(
      customerId: _customerId,
      issueDate: fmt.format(_issueDate),
      dueDate: fmt.format(_dueDate),
      currency: _currency,
      discountAmount: preview.discount,
      notes: _notesCtrl.text,
      items: [
        for (final l in _lines)
          InvoiceItemRequestDto(
            description: l.descCtrl.text.trim(),
            quantity:
                InvoiceCalculator.parseNormalized(l.qtyCtrl.text) ?? Decimal.one,
            unitPrice:
                InvoiceCalculator.parseNormalized(l.priceCtrl.text) ?? Decimal.zero,
            taxRate:
                InvoiceCalculator.parseNormalized(l.taxCtrl.text) ?? Decimal.zero,
          ),
      ],
    );

    try {
      final repo = ref.read(invoicesRepositoryProvider);
      final saved = widget.mode == InvoiceFormMode.edit
          ? await repo.updateDraftInvoice(
              widget.invoiceId ?? _loadedDraft!.id,
              request,
            )
          : await repo.createInvoice(request);
      if (!mounted) return;
      invalidateInvoiceProviders(
        ref,
        invoiceId: saved.id,
        customerId: saved.customerId,
      );
      AfabToast.showSuccess(
        context,
        context.l10n.invoicesFormSavedToast(saved.invoiceNumber),
      );
      _isDirty = false;
      if (widget.mode == InvoiceFormMode.create) {
        context.go('/invoices/${saved.id}');
      } else if (context.canPop()) {
        context.pop(saved);
      } else {
        context.go('/invoices/${saved.id}');
      }
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

    final currencies = {
      _currency.toUpperCase(),
      if (biz != null) biz.currency.toUpperCase(),
      ..._commonCurrencies,
    }.toList();

    final preview = InvoiceCalculator.computeTotals(
      items: _lines.map((l) => l.toInput()).toList(),
      discountRaw: _discountCtrl.text,
    );

    final title = widget.mode == InvoiceFormMode.edit
        ? l10n.invoicesFormEditTitle(_loadedDraft?.invoiceNumber ?? '')
        : l10n.invoicesFormCreateTitle;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (ok && context.mounted) {
          _isDirty = false;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/invoices');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () async {
              final ok = await _confirmDiscard();
              if (ok && context.mounted) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/invoices');
                }
              }
            },
          ),
        ),
        body: _loadingDraft
            ? const Center(child: AfabLoader(size: 56))
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_nonDraftLocked) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colors.dangerBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          colors.danger.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.invoicesFormOnlyDraftError,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: colors.danger),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (_serverError != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colors.dangerBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          colors.danger.withValues(alpha: 0.3),
                                    ),
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

                              // Customer & Currency
                              AfabCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    InkWell(
                                      onTap: _nonDraftLocked
                                          ? null
                                          : _pickCustomer,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText:
                                              l10n.invoicesFormCustomerLabel,
                                          isDense: true,
                                          suffixIcon: const Icon(
                                            LucideIcons.chevronDown,
                                            size: 16,
                                          ),
                                        ),
                                        child: Text(
                                          _customerLabel ??
                                              l10n.customersPickerWalkIn,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      initialValue: _currency,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText:
                                            l10n.invoicesFormCurrencyLabel,
                                        isDense: true,
                                      ),
                                      items: [
                                        for (final c in currencies)
                                          DropdownMenuItem(
                                            value: c,
                                            child: Text(c),
                                          ),
                                      ],
                                      onChanged: _nonDraftLocked
                                          ? null
                                          : (v) {
                                              if (v != null) {
                                                setState(() {
                                                  _currency = v;
                                                  _isDirty = true;
                                                });
                                              }
                                            },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Dates
                              AfabCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _nonDraftLocked
                                            ? null
                                            : _pickIssueDate,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: l10n.invoicesIssueDate,
                                            isDense: true,
                                            suffixIcon: const Icon(
                                              LucideIcons.calendar,
                                              size: 16,
                                            ),
                                          ),
                                          child: Text(
                                            AfabDateFormatter.formatDateTime(
                                              _issueDate,
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
                                        onTap: _nonDraftLocked
                                            ? null
                                            : _pickDueDate,
                                        borderRadius: BorderRadius.circular(12),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: l10n.invoicesDueDate,
                                            isDense: true,
                                            suffixIcon: const Icon(
                                              LucideIcons.calendar,
                                              size: 16,
                                            ),
                                          ),
                                          child: Text(
                                            AfabDateFormatter.formatDateTime(
                                              _dueDate,
                                              dateFormat: dateFmt,
                                              locale: locale,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Dynamic Line Items
                              AfabCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l10n.invoicesLineItems,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed:
                                              _nonDraftLocked ? null : _addLine,
                                          icon: const Icon(
                                            LucideIcons.plus,
                                            size: 16,
                                          ),
                                          label: Text(
                                            l10n.invoicesFormAddLineBtn,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    for (var i = 0; i < _lines.length; i++) ...[
                                      AfabInsetPanel(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: AfabTextField(
                                                    label: l10n
                                                        .invoicesFormItemDescLabel,
                                                    controller:
                                                        _lines[i].descCtrl,
                                                    enabled: !_nonDraftLocked,
                                                    maxLength: 255,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    onChanged: (_) =>
                                                        _markDirty(),
                                                    validator: (v) => (v ==
                                                                null ||
                                                            v.trim().isEmpty)
                                                        ? l10n.authFieldRequired
                                                        : null,
                                                  ),
                                                ),
                                                if (_lines.length > 1) ...[
                                                  const SizedBox(width: 6),
                                                  IconButton(
                                                    onPressed: _nonDraftLocked
                                                        ? null
                                                        : () => _removeLine(i),
                                                    icon: Icon(
                                                      LucideIcons.trash2,
                                                      size: 18,
                                                      color: colors.danger,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: AfabTextField(
                                                    label: l10n
                                                        .invoicesFormQtyLabel,
                                                    controller:
                                                        _lines[i].qtyCtrl,
                                                    enabled: !_nonDraftLocked,
                                                    forceLtr: true,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                    onChanged: (_) =>
                                                        _markDirty(),
                                                    validator: (v) {
                                                      final d = InvoiceCalculator
                                                          .parseNormalized(
                                                        v ?? '',
                                                      );
                                                      if (d == null ||
                                                          d <
                                                              InvoiceCalculator
                                                                  .minPositive) {
                                                        return l10n
                                                            .txFormAmountInvalid;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 2,
                                                  child: AfabTextField(
                                                    label: l10n
                                                        .invoicesFormUnitPriceLabel,
                                                    controller:
                                                        _lines[i].priceCtrl,
                                                    enabled: !_nonDraftLocked,
                                                    forceLtr: true,
                                                    hintText: '0.00',
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                    onChanged: (_) =>
                                                        _markDirty(),
                                                    validator: (v) {
                                                      final d = InvoiceCalculator
                                                          .parseNormalized(
                                                        v ?? '',
                                                      );
                                                      if (d == null ||
                                                          d < Decimal.zero) {
                                                        return l10n
                                                            .txFormAmountInvalid;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: AfabTextField(
                                                    label: l10n
                                                        .invoicesFormTaxPctLabel,
                                                    controller:
                                                        _lines[i].taxCtrl,
                                                    enabled: !_nonDraftLocked,
                                                    forceLtr: true,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                    onChanged: (_) =>
                                                        _markDirty(),
                                                    validator: (v) {
                                                      final d = InvoiceCalculator
                                                          .parseNormalized(
                                                        v ?? '',
                                                      );
                                                      if (d == null ||
                                                          d < Decimal.zero ||
                                                          d >
                                                              InvoiceCalculator
                                                                  .maxTaxRate) {
                                                        return l10n
                                                            .txFormTaxRateInvalid;
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: AlignmentDirectional
                                                  .centerEnd,
                                              child: MoneyText(
                                                amount: preview
                                                    .lines[i].lineTotal,
                                                currency: _currency,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (i < _lines.length - 1)
                                        const SizedBox(height: 10),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Discount & Totals Card
                              AfabCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AfabTextField(
                                      label:
                                          '${l10n.invoicesFormDiscountLabel} ($_currency)',
                                      controller: _discountCtrl,
                                      enabled: !_nonDraftLocked,
                                      forceLtr: true,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: (_) => _markDirty(),
                                    ),
                                    const SizedBox(height: 12),
                                    AfabInsetPanel(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        children: [
                                          _PreviewTotalRow(
                                            label: l10n.invoicesSubtotal,
                                            amount: preview.subtotal,
                                            currency: _currency,
                                          ),
                                          _PreviewTotalRow(
                                            label: l10n.invoicesTax,
                                            amount: preview.taxAmount,
                                            currency: _currency,
                                          ),
                                          if (preview.discount > Decimal.zero)
                                            _PreviewTotalRow(
                                              label: l10n.invoicesDiscount,
                                              amount: -preview.discount,
                                              currency: _currency,
                                            ),
                                          Divider(
                                            height: 14,
                                            color: colors.border,
                                          ),
                                          _PreviewTotalRow(
                                            label: l10n.invoicesTotal,
                                            amount: preview.total,
                                            currency: _currency,
                                            bold: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Notes Card
                              AfabCard(
                                child: AfabTextField(
                                  label: l10n.txDetailsNotes,
                                  hintText: l10n.invoicesFormNotesHint,
                                  controller: _notesCtrl,
                                  enabled: !_nonDraftLocked,
                                  maxLength: 2000,
                                  onChanged: (_) => _markDirty(),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Sticky Bottom Total & Save Bar
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border(top: BorderSide(color: colors.border)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: SafeArea(
                        top: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.invoicesTotal,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                      MoneyText(
                                        amount: preview.total,
                                        currency: _currency,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                AfabButton(
                                  label: widget.mode == InvoiceFormMode.edit
                                      ? l10n.invoicesFormUpdateDraftBtn
                                      : l10n.invoicesFormSaveDraftBtn,
                                  isLoading: _submitting,
                                  onPressed: _nonDraftLocked ? null : _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PreviewTotalRow extends StatelessWidget {
  const _PreviewTotalRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.bold = false,
  });

  final String label;
  final Decimal amount;
  final String currency;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bold
                  ? textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
                  : textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          MoneyText(
            amount: amount,
            currency: currency,
            style: (bold ? textTheme.titleMedium : textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
