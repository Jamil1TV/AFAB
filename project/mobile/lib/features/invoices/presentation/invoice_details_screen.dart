import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoice_pdf_generator.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/invoices/domain/invoices_providers.dart';
import 'package:afab_mobile/features/invoices/presentation/widgets/record_payment_sheet.dart';
import 'package:afab_mobile/features/settings/domain/signature_vault_provider.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `BIZ-04`: Phone standalone Invoice Details screen.
class InvoiceDetailsScreen extends StatelessWidget {
  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.invoicesDetailTitle)),
      body: InvoiceDetailsPane(invoiceId: invoiceId),
    );
  }
}

/// Reusable Invoice Details pane for phone detail screen & tablet right pane.
class InvoiceDetailsPane extends ConsumerStatefulWidget {
  const InvoiceDetailsPane({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailsPane> createState() => _InvoiceDetailsPaneState();
}

class _InvoiceDetailsPaneState extends ConsumerState<InvoiceDetailsPane> {
  bool _busy = false;
  bool _exportingPdf = false;

  Future<void> _issue(InvoiceDto invoice, {required bool sent}) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(invoicesRepositoryProvider)
          .issueInvoice(invoice.id, sent: sent);
      if (!mounted) return;
      invalidateInvoiceProviders(
        ref,
        invoiceId: invoice.id,
        customerId: invoice.customerId,
      );
      AfabToast.showSuccess(
        context,
        sent
            ? context.l10n.invoicesIssuedSentToast
            : context.l10n.invoicesIssuedUnpaidToast,
      );
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(InvoiceDto invoice) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.invoicesCancelConfirmTitle),
        content: Text(l10n.invoicesCancelConfirmDesc(invoice.invoiceNumber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.invoicesCancelBtn),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(invoicesRepositoryProvider).cancelInvoice(invoice.id);
      if (!mounted) return;
      invalidateInvoiceProviders(
        ref,
        invoiceId: invoice.id,
        customerId: invoice.customerId,
      );
      AfabToast.showSuccess(context, l10n.invoicesCancelledToast);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportPdf(InvoiceDto invoice) async {
    setState(() => _exportingPdf = true);
    try {
      final biz = ref.read(activeBusinessProvider);
      final bizId = biz?.id ?? 'default';
      final sigReg = ref.read(signatureVaultProvider(bizId));
      final sigBytes = await ref
          .read(signatureVaultProvider(bizId).notifier)
          .readActiveBytes();
      await InvoicePdfGenerator.exportAndShare(
        invoice,
        businessName: biz?.name ?? 'AFAB',
        numberFormat: biz?.numberFormat ?? 'US',
        signaturePngBytes: sigBytes,
        signatoryName: sigReg.activeSignature?.signatoryName,
        signatoryTitle: sigReg.activeSignature?.signatoryTitle,
      );
    } catch (e) {
      if (mounted) {
        AfabToast.showError(
          context,
          '${context.l10n.errorGenericTitle}: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  void _openAiReminder(InvoiceDto invoice) {
    final customerLabel = (invoice.customerName?.isNotEmpty == true)
        ? invoice.customerName!
        : 'customer';
    final balanceStr = MoneyFormatter.formatDecimal(
      invoice.outstandingBalance,
      currency: invoice.currency,
    );
    context.go(
      '/copilot',
      extra: CopilotPromptRequest(
        prompt:
            'Draft a polite, professional payment reminder for invoice ${invoice.invoiceNumber} ($balanceStr outstanding, due ${invoice.dueDate}) addressed to $customerLabel.',
        autoSend: true,
        screenContext: {
          'page': 'invoice_details',
          'invoiceId': invoice.id,
          'invoiceNumber': invoice.invoiceNumber,
        },
      ),
    );
  }

  String _methodLabel(BuildContext context, String raw) {
    final l10n = context.l10n;
    return switch (raw.toUpperCase()) {
      'BANK_TRANSFER' => l10n.txMethodBankTransfer,
      'CARD' => l10n.txMethodCard,
      'CREDIT_CARD' => l10n.txMethodCreditCard,
      'CASH' => l10n.txMethodCash,
      _ => l10n.txMethodOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final detailAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));

    return detailAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: AfabLoader(size: 56),
        ),
      ),
      error: (err, _) => AfabErrorState(
        title: l10n.errorGenericTitle,
        message: err.toString(),
        retryLabel: l10n.commonRetry,
        onRetry: () => ref.invalidate(invoiceDetailProvider(widget.invoiceId)),
      ),
      data: (inv) {
        final isDraft = inv.status == InvoiceStatus.draft;
        final canPay = inv.status.isPayable &&
            inv.outstandingBalance > Decimal.zero &&
            isEditable;
        final canCancel = isEditable &&
            inv.status != InvoiceStatus.paid &&
            inv.status != InvoiceStatus.cancelled &&
            inv.paidAmount == Decimal.zero;
        final canRemind = inv.status.isPayable;

        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(invoiceDetailProvider(widget.invoiceId).future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (inv.overdue || inv.status == InvoiceStatus.overdue) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.triangleAlert,
                        size: 18,
                        color: colors.danger,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.invoicesOverdueBanner,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Header & Lifecycle Actions
              AfabCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              inv.invoiceNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AfabStatusBadge(
                          label: inv.status.localizedLabel(context),
                          variant: inv.status.badgeVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        Text(
                          '${l10n.invoicesIssueDate}: ${AfabDateFormatter.formatIsoDate(inv.issueDate, dateFormat: dateFmt, locale: locale)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${l10n.invoicesDueDate}: ${AfabDateFormatter.formatIsoDate(inv.dueDate, dateFormat: dateFmt, locale: locale)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isDraft && isEditable) ...[
                          AfabButton(
                            label: l10n.invoicesEditDraftBtn,
                            icon: LucideIcons.pencil,
                            variant: AfabButtonVariant.secondary,
                            compact: true,
                            onPressed: _busy
                                ? null
                                : () => context.push(
                                      '/invoices/${inv.id}/edit',
                                      extra: inv,
                                    ),
                          ),
                          AfabButton(
                            label: l10n.invoicesMarkSentBtn,
                            icon: LucideIcons.send,
                            compact: true,
                            isLoading: _busy,
                            onPressed:
                                _busy ? null : () => _issue(inv, sent: true),
                          ),
                          AfabButton(
                            label: l10n.invoicesIssueUnpaidBtn,
                            icon: LucideIcons.fileCheck,
                            variant: AfabButtonVariant.soft,
                            compact: true,
                            isLoading: _busy,
                            onPressed:
                                _busy ? null : () => _issue(inv, sent: false),
                          ),
                        ],
                        if (canPay)
                          AfabButton(
                            label: l10n.invoicesRecordPaymentBtn,
                            icon: LucideIcons.creditCard,
                            compact: true,
                            onPressed: () =>
                                showRecordPaymentSheet(context, invoice: inv),
                          ),
                        if (canRemind)
                          AfabButton(
                            label: l10n.invoicesAiReminderBtn,
                            icon: LucideIcons.sparkles,
                            variant: AfabButtonVariant.soft,
                            compact: true,
                            onPressed: () => _openAiReminder(inv),
                          ),
                        AfabButton(
                          label: l10n.invoicesExportPdfBtn,
                          icon: LucideIcons.fileDown,
                          variant: AfabButtonVariant.secondary,
                          compact: true,
                          isLoading: _exportingPdf,
                          onPressed: _exportingPdf ? null : () => _exportPdf(inv),
                        ),
                        if (canCancel)
                          AfabButton(
                            label: l10n.invoicesCancelBtn,
                            icon: LucideIcons.ban,
                            variant: AfabButtonVariant.danger,
                            compact: true,
                            onPressed: _busy ? null : () => _cancel(inv),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Billed Customer Card
              AfabCard(
                onTap: (inv.customerId != null && inv.customerId!.isNotEmpty)
                    ? () => context.push('/customers/${inv.customerId}')
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.secondaryBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.user,
                        size: 18,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.invoicesCustomerSection,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (inv.customerName != null &&
                                    inv.customerName!.isNotEmpty)
                                ? inv.customerName!
                                : l10n.invoicesWalkInCustomer,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (inv.customerEmail != null &&
                              inv.customerEmail!.isNotEmpty)
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                inv.customerEmail!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (inv.customerId != null && inv.customerId!.isNotEmpty)
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: colors.textMuted,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Line Items & Totals Summary
              AfabCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.invoicesLineItems,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < inv.items.length; i++) ...[
                      AfabInsetPanel(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    inv.items[i].description,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                MoneyText(
                                  amount: inv.items[i].lineTotal,
                                  currency: inv.currency,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    l10n.invoicesQtyPrice(
                                      inv.items[i].quantity.toString(),
                                      MoneyFormatter.formatDecimal(
                                        inv.items[i].unitPrice,
                                        currency: inv.currency,
                                      ),
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                if (inv.items[i].taxRate > Decimal.zero)
                                  AfabStatusBadge(
                                    label: l10n.invoicesTaxRateBadge(
                                      inv.items[i].taxRate.toString(),
                                    ),
                                    variant: AfabBadgeVariant.neutral,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (i < inv.items.length - 1) const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 14),
                    Divider(height: 1, color: colors.border),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: l10n.invoicesSubtotal,
                      amount: inv.subtotal,
                      currency: inv.currency,
                    ),
                    _SummaryRow(
                      label: l10n.invoicesTax,
                      amount: inv.taxAmount,
                      currency: inv.currency,
                    ),
                    if (inv.discountAmount > Decimal.zero)
                      _SummaryRow(
                        label: l10n.invoicesDiscount,
                        amount: -inv.discountAmount,
                        currency: inv.currency,
                      ),
                    Divider(height: 16, color: colors.border),
                    _SummaryRow(
                      label: l10n.invoicesTotal,
                      amount: inv.totalAmount,
                      currency: inv.currency,
                      bold: true,
                    ),
                    _SummaryRow(
                      label: l10n.invoicesPaidAmount,
                      amount: inv.paidAmount,
                      currency: inv.currency,
                      valueColor: colors.success,
                    ),
                    _SummaryRow(
                      label: l10n.invoicesOutstanding,
                      amount: inv.outstandingBalance,
                      currency: inv.currency,
                      bold: true,
                      valueColor: inv.outstandingBalance > Decimal.zero
                          ? colors.warning
                          : colors.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Payment History with clickable incomeTransactionId
              AfabCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.invoicesPaymentsHistory,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    if (inv.payments.isEmpty)
                      AfabEmptyState(
                        icon: LucideIcons.wallet,
                        title: l10n.commonNoData,
                        description: l10n.invoicesPaymentsEmpty,
                      )
                    else
                      for (var i = 0; i < inv.payments.length; i++) ...[
                        _PaymentHistoryTile(
                          payment: inv.payments[i],
                          dateFormat: dateFmt,
                          locale: locale,
                          methodLabel: _methodLabel(
                            context,
                            inv.payments[i].paymentMethod,
                          ),
                          linkedTxLabel: l10n.invoicesLinkedTx,
                          onTapTx: (inv.payments[i].incomeTransactionId !=
                                      null &&
                                  inv.payments[i].incomeTransactionId!
                                      .isNotEmpty)
                              ? () => context.push(
                                    '/transactions/${inv.payments[i].incomeTransactionId}',
                                  )
                              : null,
                        ),
                        if (i < inv.payments.length - 1)
                          const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),

              if (inv.notes != null && inv.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                AfabCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.txDetailsNotes,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        inv.notes!.trim(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final Decimal amount;
  final String currency;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  const _PaymentHistoryTile({
    required this.payment,
    required this.dateFormat,
    required this.locale,
    required this.methodLabel,
    required this.linkedTxLabel,
    this.onTapTx,
  });

  final PaymentDto payment;
  final String dateFormat;
  final String locale;
  final String methodLabel;
  final String linkedTxLabel;
  final VoidCallback? onTapTx;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final dateStr = AfabDateFormatter.formatIsoDate(
      payment.paymentDate,
      dateFormat: dateFormat,
      locale: locale,
    );

    return AfabInsetPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$dateStr · $methodLabel',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              MoneyText(
                amount: payment.amount,
                currency: payment.currency,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          if (payment.convertedBaseAmount != null &&
              payment.baseCurrency != null &&
              payment.baseCurrency != payment.currency) ...[
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '≈ ${MoneyFormatter.formatDecimal(payment.convertedBaseAmount!, currency: payment.baseCurrency!)}'
                '${payment.exchangeRate != null ? ' (@ ${payment.exchangeRate})' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          if (payment.reference != null && payment.reference!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              payment.reference!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (onTapTx != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onTapTx,
              borderRadius: BorderRadius.circular(8),
              child: AfabStatusBadge(
                label: linkedTxLabel,
                icon: LucideIcons.arrowUpRight,
                variant: AfabBadgeVariant.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
