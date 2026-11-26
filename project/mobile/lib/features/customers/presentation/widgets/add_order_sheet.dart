import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/domain/customers_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

Future<InvoiceDto?> showAddOrderSheet(
  BuildContext context, {
  required CustomerDto customer,
}) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<InvoiceDto>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _AddOrderForm(customer: customer, showDialogHeader: true),
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<InvoiceDto>(
    context: context,
    title: context.l10n.customersOrderModalTitle,
    subtitle: customer.name,
    builder: (ctx) => _AddOrderForm(customer: customer, showDialogHeader: false),
  );
}

class _AddOrderForm extends ConsumerStatefulWidget {
  const _AddOrderForm({
    required this.customer,
    required this.showDialogHeader,
  });

  final CustomerDto customer;
  final bool showDialogHeader;

  @override
  ConsumerState<_AddOrderForm> createState() => _AddOrderFormState();
}

class _AddOrderFormState extends ConsumerState<_AddOrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  DateTime _orderDate = DateTime.now();
  String _paymentMethod = 'BANK_TRANSFER';
  String _initialStatus = 'PAID'; // PAID | UNPAID | DRAFT
  bool _submitting = false;
  String? _serverError;

  // Preserved across partial failures so retries never duplicate the invoice or payment.
  late final String _idempotencyKey;
  InvoiceDto? _createdInvoice;
  bool _issued = false;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _orderDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = Decimal.tryParse(
      _amountCtrl.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount < Decimal.parse('0.0001')) return;

    setState(() {
      _submitting = true;
      _serverError = null;
    });

    final bizCurrency = ref.read(activeBusinessProvider)?.currency ?? 'USD';
    final isoDate = DateFormat('yyyy-MM-dd', 'en_US').format(_orderDate);
    final repo = ref.read(invoicesRepositoryProvider);

    try {
      // Step 1: Create DRAFT invoice if not already created in an earlier attempt.
      _createdInvoice ??= await repo.createInvoice(
        CreateInvoiceRequestDto(
          customerId: widget.customer.id,
          issueDate: isoDate,
          dueDate: isoDate,
          currency: bizCurrency,
          discountAmount: Decimal.zero,
          notes: 'Customer Order — ${widget.customer.name}',
          items: [
            InvoiceItemRequestDto(
              description: _descCtrl.text.trim(),
              quantity: Decimal.one,
              unitPrice: amount,
              taxRate: Decimal.zero,
            ),
          ],
        ),
      );

      final invId = _createdInvoice!.id;

      // Step 2: Issue if UNPAID or PAID.
      if ((_initialStatus == 'UNPAID' || _initialStatus == 'PAID') && !_issued) {
        _createdInvoice = await repo.issueInvoice(invId, sent: false);
        _issued = true;
      }

      // Step 3: Record idempotent payment if PAID.
      if (_initialStatus == 'PAID') {
        await repo.recordPayment(
          invId,
          RecordPaymentRequestDto(
            amount: amount,
            currency: _createdInvoice!.currency,
            paymentDate: isoDate,
            paymentMethod: _paymentMethod,
            notes: 'Recorded from Customer Order',
            idempotencyKey: _idempotencyKey,
          ),
        );
      }

      final latest = await repo.getInvoiceById(invId);
      if (!mounted) return;
      invalidateCustomerProviders(ref, customerId: widget.customer.id);
      ref.invalidate(transactionListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(revenueListProvider);
      ref.invalidate(revenueSummaryProvider);
      ref.invalidate(expenseSummaryProvider);
      AfabToast.showSuccess(context, context.l10n.customersOrderCreatedToast);
      Navigator.of(context).pop(latest);
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
    final currency = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final helperText = switch (_initialStatus) {
      'PAID' => l10n.customersOrderPaidHelper,
      'UNPAID' => l10n.customersOrderUnpaidHelper,
      _ => l10n.customersOrderDraftHelper,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customersOrderModalTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.customer.name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
            label: l10n.customersOrderDescLabel,
            controller: _descCtrl,
            enabled: _createdInvoice == null,
            maxLength: 255,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.authFieldRequired : null,
          ),
          const SizedBox(height: 12),
          AfabTextField(
            label: l10n.customersOrderAmountLabel(currency),
            controller: _amountCtrl,
            enabled: _createdInvoice == null,
            forceLtr: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final d = Decimal.tryParse((v ?? '').trim().replaceAll(',', '.'));
              if (d == null || d < Decimal.parse('0.0001')) {
                return l10n.txFormAmountInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _createdInvoice == null ? _pickDate : null,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.customersOrderDateLabel,
                      isDense: true,
                      suffixIcon: const Icon(LucideIcons.calendar, size: 16),
                    ),
                    child: Text(
                      AfabDateFormatter.formatDateTime(
                        _orderDate,
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
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _initialStatus,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.customersOrderInitialStatus,
              isDense: true,
            ),
            items: [
              DropdownMenuItem(value: 'PAID', child: Text(l10n.invoicesStatusPaid)),
              DropdownMenuItem(
                value: 'UNPAID',
                child: Text(l10n.invoicesStatusUnpaid),
              ),
              DropdownMenuItem(
                value: 'DRAFT',
                child: Text(l10n.invoicesStatusDraft),
              ),
            ],
            onChanged: _createdInvoice == null
                ? (v) {
                    if (v != null) setState(() => _initialStatus = v);
                  }
                : null,
          ),
          const SizedBox(height: 10),
          AfabInsetPanel(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 16, color: colors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
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
