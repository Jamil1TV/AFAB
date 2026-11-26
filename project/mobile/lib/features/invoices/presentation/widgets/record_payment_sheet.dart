import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/currency_minor_units.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/invoices/domain/invoice_calculator.dart';
import 'package:afab_mobile/features/invoices/domain/invoices_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

/// Screen `BIZ-06`: Idempotent full/partial invoice payment sheet.
/// Generates one UUID v4 `Idempotency-Key` per sheet session and reuses it
/// across retries so double-taps or flaky mobile timeouts never duplicate payments.
Future<PaymentDto?> showRecordPaymentSheet(
  BuildContext context, {
  required InvoiceDto invoice,
}) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<PaymentDto>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _RecordPaymentForm(
              invoice: invoice,
              showDialogHeader: true,
            ),
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<PaymentDto>(
    context: context,
    title: context.l10n.paymentSheetTitle,
    subtitle: context.l10n.paymentRemainingLabel(
      invoice.invoiceNumber,
      MoneyFormatter.formatDecimal(
        invoice.outstandingBalance,
        currency: invoice.currency,
      ),
    ),
    builder: (ctx) => _RecordPaymentForm(
      invoice: invoice,
      showDialogHeader: false,
    ),
  );
}

class _RecordPaymentForm extends ConsumerStatefulWidget {
  const _RecordPaymentForm({
    required this.invoice,
    required this.showDialogHeader,
  });

  final InvoiceDto invoice;
  final bool showDialogHeader;

  @override
  ConsumerState<_RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends ConsumerState<_RecordPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _rateCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late final String _idempotencyKey;
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'BANK_TRANSFER';
  bool _submitting = false;
  bool _dispatched = false;
  bool _isRetryPrompt = false;
  bool _statusConflict = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
    final decimals = CurrencyMinorUnits.decimalsFor(widget.invoice.currency);
    _amountCtrl = TextEditingController(
      text: widget.invoice.outstandingBalance.toStringAsFixed(decimals),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setQuickAmount(bool half) {
    final decimals = CurrencyMinorUnits.decimalsFor(widget.invoice.currency);
    final full = widget.invoice.outstandingBalance;
    final target = half
        ? (full / Decimal.fromInt(2))
            .toDecimal(scaleOnInfinitePrecision: decimals + 4)
            .round(scale: decimals)
        : full.round(scale: decimals);
    final clamped = target > full ? full : target;
    _amountCtrl.text = clamped.toStringAsFixed(decimals);
    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = InvoiceCalculator.parseNormalized(_amountCtrl.text);
    if (amount == null || amount < InvoiceCalculator.minPositive) return;
    if (amount > widget.invoice.outstandingBalance) return;

    Decimal? manualRate;
    final rateText = _rateCtrl.text.trim();
    if (rateText.isNotEmpty) {
      manualRate = InvoiceCalculator.parseNormalized(rateText);
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _statusConflict = false;
    });

    _dispatched = true;
    final request = RecordPaymentRequestDto(
      amount: amount,
      currency: widget.invoice.currency,
      paymentDate: DateFormat('yyyy-MM-dd', 'en_US').format(_paymentDate),
      paymentMethod: _paymentMethod,
      reference: _refCtrl.text,
      notes: _notesCtrl.text,
      idempotencyKey: _idempotencyKey,
      exchangeRate: manualRate,
    );

    try {
      final payment = await ref
          .read(invoicesRepositoryProvider)
          .recordPayment(widget.invoice.id, request);
      if (!mounted) return;
      invalidateInvoiceProviders(
        ref,
        invoiceId: widget.invoice.id,
        customerId: widget.invoice.customerId,
        includeLedgers: true,
      );
      AfabToast.showSuccess(context, context.l10n.paymentSuccessToast);
      Navigator.of(context).pop(payment);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.message;
        _isRetryPrompt = e is NetworkFailure || e is ServerFailure;
        _statusConflict = e is ConflictFailure;
      });
    }
  }

  void _closeSheet() {
    if (_dispatched) {
      invalidateInvoiceProviders(
        ref,
        invoiceId: widget.invoice.id,
        customerId: widget.invoice.customerId,
        includeLedgers: true,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final baseCurrency = (biz?.currency ?? widget.invoice.currency).toUpperCase();
    final isCrossCurrency =
        widget.invoice.currency.toUpperCase() != baseCurrency;
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final parsedAmount = InvoiceCalculator.parseNormalized(_amountCtrl.text);
    final parsedRate = InvoiceCalculator.parseNormalized(_rateCtrl.text);
    final convertedPreview = (isCrossCurrency &&
            parsedAmount != null &&
            parsedRate != null &&
            parsedRate > Decimal.zero)
        ? (parsedAmount * parsedRate)
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.paymentSheetTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          l10n.paymentRemainingLabel(
                            widget.invoice.invoiceNumber,
                            MoneyFormatter.formatDecimal(
                              widget.invoice.outstandingBalance,
                              currency: widget.invoice.currency,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _closeSheet,
                  icon: Icon(LucideIcons.x, color: colors.textMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // 1:1 Income Transaction Accounting Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.infoBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 17, color: colors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.paymentLedgerNotice,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.dangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _errorMessage!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.danger),
                  ),
                  if (_statusConflict) ...[
                    const SizedBox(height: 8),
                    AfabButton(
                      label: l10n.commonReload,
                      variant: AfabButtonVariant.secondary,
                      compact: true,
                      onPressed: () {
                        invalidateInvoiceProviders(
                          ref,
                          invoiceId: widget.invoice.id,
                          customerId: widget.invoice.customerId,
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          AfabTextField(
            label: '${l10n.txFormAmountLabel} (${widget.invoice.currency})',
            controller: _amountCtrl,
            forceLtr: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final d = InvoiceCalculator.parseNormalized(v ?? '');
              if (d == null || d < InvoiceCalculator.minPositive) {
                return l10n.txFormAmountInvalid;
              }
              if (d > widget.invoice.outstandingBalance) {
                return l10n.paymentOverBalanceError;
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                label: Text(l10n.paymentFullBalanceChip),
                onPressed: () => _setQuickAmount(false),
              ),
              ActionChip(
                label: Text(l10n.paymentHalfChip),
                onPressed: () => _setQuickAmount(true),
              ),
              Text(
                l10n.paymentAmountHelper(
                  MoneyFormatter.formatDecimal(
                    widget.invoice.outstandingBalance,
                    currency: widget.invoice.currency,
                  ),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.paymentDateLabel,
                      isDense: true,
                      suffixIcon: const Icon(LucideIcons.calendar, size: 16),
                    ),
                    child: Text(
                      AfabDateFormatter.formatDateTime(
                        _paymentDate,
                        dateFormat: dateFmt,
                        locale: locale,
                      ),
                    ),
                  ),
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
                    DropdownMenuItem(
                      value: 'BANK_TRANSFER',
                      child: Text(l10n.txMethodBankTransfer),
                    ),
                    DropdownMenuItem(value: 'CARD', child: Text(l10n.txMethodCard)),
                    DropdownMenuItem(
                      value: 'CREDIT_CARD',
                      child: Text(l10n.txMethodCreditCard),
                    ),
                    DropdownMenuItem(value: 'CASH', child: Text(l10n.txMethodCash)),
                    DropdownMenuItem(value: 'OTHER', child: Text(l10n.txMethodOther)),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _paymentMethod = v);
                  },
                ),
              ),
            ],
          ),

          if (isCrossCurrency) ...[
            const SizedBox(height: 12),
            AfabTextField(
              label: l10n.paymentFxLabel(widget.invoice.currency, baseCurrency),
              controller: _rateCtrl,
              forceLtr: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                final r = InvoiceCalculator.parseNormalized(t);
                if (r == null || r < Decimal.parse('0.000001')) {
                  return l10n.paymentRateInvalidError;
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            Text(
              l10n.paymentFxHelper(baseCurrency),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (convertedPreview != null) ...[
              const SizedBox(height: 6),
              AfabInsetPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(baseCurrency, style: Theme.of(context).textTheme.labelSmall),
                    MoneyText(
                      amount: convertedPreview,
                      currency: baseCurrency,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 12),
          AfabTextField(
            label: l10n.paymentReferenceLabel,
            hintText: l10n.paymentReferenceHint,
            controller: _refCtrl,
            maxLength: 255,
            textInputAction: TextInputAction.next,
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
                  onPressed: _submitting ? null : _closeSheet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AfabButton(
                  label: _isRetryPrompt
                      ? l10n.paymentRetrySameBtn
                      : l10n.paymentConfirmBtn,
                  isLoading: _submitting,
                  onPressed: _statusConflict ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
