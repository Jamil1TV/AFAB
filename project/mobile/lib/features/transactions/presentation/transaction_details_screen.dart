import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/receipts/data/receipt_dto.dart';
import 'package:afab_mobile/features/receipts/domain/receipt_providers.dart';
import 'package:afab_mobile/features/receipts/presentation/receipt_upload_sheet.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/delete_transaction_dialog.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/transaction_list_card.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `FIN-02`: Standalone transaction inspector fetching fresh state from
/// `GET /transactions/{id}` and `GET /receipts/transactions/{id}`.
class TransactionDetailsScreen extends ConsumerWidget {
  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
    this.initialPreview,
  });

  final String transactionId;
  final TransactionDto? initialPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detailAsync = ref.watch(transactionDetailProvider(transactionId));
    final tx = detailAsync.value ?? initialPreview;
    final isEditable = !(ref.watch(activeBusinessProvider)?.isReadOnly ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.txDetailsTitle),
        actions: [
          IconButton(
            tooltip: l10n.moreHubAskCopilotTooltip,
            onPressed: () => context.go('/copilot'),
            icon: const Icon(LucideIcons.sparkles),
          ),
          if (tx != null && isEditable)
            PopupMenuButton<String>(
              onSelected: (val) async {
                if (val == 'duplicate') {
                  context.push(
                    '/transactions/${tx.id}/duplicate',
                    extra: tx,
                  );
                } else if (val == 'edit') {
                  context.push(
                    '/transactions/${tx.id}/edit',
                    extra: tx,
                  );
                } else if (val == 'delete') {
                  await _handleDelete(context, ref, tx, popAfter: true);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l10n.txActionDuplicate),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.commonEdit),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l10n.commonDelete,
                    style: TextStyle(color: context.afabColors.danger),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: TransactionDetailsPane(
            transactionId: transactionId,
            initialPreview: initialPreview,
            popOnDelete: true,
          ),
        ),
      ),
    );
  }
}

Future<void> _handleDelete(
  BuildContext context,
  WidgetRef ref,
  TransactionDto tx, {
  required bool popAfter,
}) async {
  final l10n = context.l10n;
  final bizCurrency = ref.read(activeBusinessProvider)?.currency ?? 'USD';
  final confirmed = await showDeleteTransactionDialog(
    context,
    transaction: tx,
    fallbackCurrency: bizCurrency,
  );
  if (!confirmed || !context.mounted) return;

  try {
    await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
    if (!context.mounted) return;
    if (ref.read(selectedTransactionIdProvider) == tx.id) {
      ref.read(selectedTransactionIdProvider.notifier).select(null);
    }
    invalidateFinanceLedgers(ref);
    AfabToast.showSuccess(context, l10n.txDeletedToast);
    if (popAfter && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    AfabToast.showError(context, e.message);
  }
}

/// Embeddable transaction detail inspector reused in both `TransactionDetailsScreen`
/// and `TransactionsScreen` (`>= 840dp` tablet Master-Detail split view).
class TransactionDetailsPane extends ConsumerWidget {
  const TransactionDetailsPane({
    super.key,
    required this.transactionId,
    this.initialPreview,
    this.popOnDelete = false,
  });

  final String transactionId;
  final TransactionDto? initialPreview;
  final bool popOnDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final fallbackCurr = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';

    final detailAsync = ref.watch(transactionDetailProvider(transactionId));
    final receiptsAsync = ref.watch(transactionReceiptsProvider(transactionId));
    final uploadState = ref.watch(receiptUploadControllerProvider(transactionId));

    if (detailAsync.hasError && initialPreview == null) {
      return Center(
        child: AfabEmptyState(
          icon: LucideIcons.circleAlert,
          title: l10n.txDetailsUnavailable,
          description: l10n.txDetailsUnavailableDesc,
          actionLabel: l10n.txDetailsBackToLedger,
          onAction: () {
            if (popOnDelete && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ref.read(selectedTransactionIdProvider.notifier).select(null);
            }
          },
        ),
      );
    }

    final tx = detailAsync.value ?? initialPreview;
    if (tx == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: AfabListSkeleton(count: 5),
      );
    }

    final isIncome = tx.isIncome;
    final baseCurr = tx.resolvedBaseCurrency.isNotEmpty
        ? tx.resolvedBaseCurrency
        : fallbackCurr;
    final signedAmt = isIncome ? tx.amount : -tx.amount;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionDetailProvider(transactionId));
              ref.invalidate(transactionReceiptsProvider(transactionId));
              await Future.wait([
                ref.read(transactionDetailProvider(transactionId).future),
                ref.read(transactionReceiptsProvider(transactionId).future),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (tx.parentTransactionId != null &&
                    tx.parentTransactionId!.isNotEmpty) ...[
                  AfabInsetPanel(
                    borderColor: colors.primary.withValues(alpha: 0.35),
                    child: Row(
                      children: [
                        Icon(LucideIcons.layers, size: 18, color: colors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.txDetailsChildSplitBanner,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(
                            '/transactions/${tx.parentTransactionId}',
                          ),
                          child: Text(l10n.txDetailsViewParent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Hero Summary Card
                AfabCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          AfabStatusBadge(
                            label: isIncome
                                ? l10n.txTypeIncome
                                : l10n.txTypeExpense,
                            variant: isIncome
                                ? AfabBadgeVariant.success
                                : AfabBadgeVariant.danger,
                          ),
                          AfabStatusBadge(
                            label: localizedStatusLabel(context, tx.status),
                            variant: badgeVariantForStatus(tx.status),
                          ),
                          if (tx.taxDeductible)
                            AfabStatusBadge(
                              label: l10n.txBadgeTax,
                              variant: AfabBadgeVariant.info,
                            ),
                          if (tx.isSplit)
                            AfabStatusBadge(
                              label: l10n.txBadgeSplit,
                              variant: AfabBadgeVariant.primary,
                              icon: LucideIcons.layers,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: MoneyText(
                          amount: signedAmt,
                          currency: baseCurr,
                          showSign: isIncome,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: isIncome
                                    ? colors.success
                                    : colors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (tx.hasForeignFx && tx.originalAmount != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.globe,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  l10n.txDetailsOriginalFx(
                                    MoneyFormatter.formatDecimal(
                                      tx.originalAmount!,
                                      currency: tx.originalCurrency!,
                                    ),
                                    tx.exchangeRate!.toStringAsFixed(6),
                                    tx.originalCurrency!,
                                    baseCurr,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        tx.description,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),

                if (tx.potentialDuplicate) ...[
                  const SizedBox(height: 12),
                  AfabInsetPanel(
                    borderColor: colors.warning.withValues(alpha: 0.45),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.triangleAlert,
                          size: 18,
                          color: colors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.txDetailsDuplicateAlertTitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: colors.warning),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.txDetailsDuplicateAlertDesc,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (tx.priceHikePercentage != null &&
                    tx.priceHikePercentage! > Decimal.zero) ...[
                  const SizedBox(height: 12),
                  AfabInsetPanel(
                    borderColor: colors.primary.withValues(alpha: 0.4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.trendingUp,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.txDetailsPriceHikeTitle(
                                  tx.priceHikePercentage!.toStringAsFixed(0),
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: colors.primary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.txDetailsPriceHikeDesc,
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
                // Metadata Panel
                AfabInsetPanel(
                  child: Column(
                    children: [
                      _MetaRow(
                        label: l10n.txFilterCategory,
                        valueWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ColorParser.parseHex(
                                  tx.categoryColor,
                                  colors.primary,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                tx.categoryName ??
                                    (tx.isSplit
                                        ? l10n.txBadgeSplit
                                        : l10n.txDetailsUncategorized),
                                style: Theme.of(context).textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 18, color: colors.border),
                      _MetaRow(
                        label: l10n.txFormDateLabel,
                        valueText: AfabDateFormatter.formatIsoDate(
                          tx.transactionDate,
                          dateFormat: dateFmt,
                          locale: locale,
                        ),
                      ),
                      Divider(height: 18, color: colors.border),
                      _MetaRow(
                        label: l10n.txFilterPaymentMethod,
                        valueText: localizedPaymentMethodLabel(
                          context,
                          tx.paymentMethod,
                        ),
                      ),
                      Divider(height: 18, color: colors.border),
                      _MetaRow(
                        label: l10n.txDetailsFxSnapshot,
                        valueText: tx.legacyFx
                            ? l10n.txDetailsLegacyFx(baseCurr)
                            : '${tx.originalCurrency ?? baseCurr} → $baseCurr (${tx.fxRateSource ?? 'LOCKED'})',
                      ),
                      if (tx.taxDeductible && tx.taxRate != null) ...[
                        Divider(height: 18, color: colors.border),
                        _MetaRow(
                          label: l10n.txDetailsTaxRate,
                          valueText: '${tx.taxRate}%',
                        ),
                      ],
                    ],
                  ),
                ),

                if (tx.isSplit && tx.splitItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(LucideIcons.layers, size: 16, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.txDetailsSplitSection,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final line in tx.splitItems) ...[
                    AfabInsetPanel(
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: ColorParser.parseHex(
                                line.categoryColor,
                                colors.primary,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.categoryName,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (line.description != null &&
                                    line.description!.isNotEmpty)
                                  Text(
                                    line.description!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          MoneyText(
                            amount: line.amount,
                            currency: baseCurr,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                if (tx.notes != null && tx.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.txDetailsNotes,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  AfabInsetPanel(
                    child: Text(
                      tx.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                // Private Receipts Section
                Row(
                  children: [
                    Icon(LucideIcons.paperclip, size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.receiptsSectionTitle(
                          receiptsAsync.value?.length ?? 0,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isEditable)
                      AfabButton(
                        label: l10n.receiptsAttachBtn,
                        icon: LucideIcons.plus,
                        variant: AfabButtonVariant.soft,
                        compact: true,
                        onPressed: uploadState.isUploading
                            ? null
                            : () => showReceiptUploadSheet(
                                  context,
                                  transactionId: transactionId,
                                ),
                      ),
                  ],
                ),
                if (uploadState.isUploading) ...[
                  const SizedBox(height: 10),
                  AfabInsetPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.receiptsUploading,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(
                                    receiptUploadControllerProvider(
                                      transactionId,
                                    ).notifier,
                                  )
                                  .cancelUpload(),
                              icon: const Icon(LucideIcons.x, size: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: uploadState.progress),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                receiptsAsync.when(
                  loading: () => const AfabListSkeleton(count: 2),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(
                      transactionReceiptsProvider(transactionId),
                    ),
                  ),
                  data: (receipts) {
                    if (receipts.isEmpty) {
                      return AfabInsetPanel(
                        child: Text(
                          l10n.receiptsEmptyDesc,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final receipt in receipts) ...[
                          _ReceiptRow(
                            receipt: receipt,
                            isEditable: isEditable,
                            onTap: () => context.push(
                              '/transactions/$transactionId/receipts/${receipt.id}',
                              extra: receipt,
                            ),
                            onDelete: () =>
                                _deleteReceipt(context, ref, receipt),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),
                InkWell(
                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: tx.id));
                    if (context.mounted) {
                      AfabToast.showSuccess(
                        context,
                        l10n.commonCopiedToClipboard,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.txDetailsAuditId,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            tx.id,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isEditable)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AfabButton(
                      label: l10n.txActionDuplicate,
                      icon: LucideIcons.copy,
                      variant: AfabButtonVariant.secondary,
                      compact: true,
                      onPressed: () => context.push(
                        '/transactions/${tx.id}/duplicate',
                        extra: tx,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AfabButton(
                      label: l10n.commonEdit,
                      icon: LucideIcons.pencil,
                      compact: true,
                      onPressed: () => context.push(
                        '/transactions/${tx.id}/edit',
                        extra: tx,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: l10n.commonDelete,
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: colors.danger.withValues(alpha: 0.45),
                      ),
                    ),
                    onPressed: () => _handleDelete(
                      context,
                      ref,
                      tx,
                      popAfter: popOnDelete,
                    ),
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: colors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _deleteReceipt(
    BuildContext context,
    WidgetRef ref,
    ReceiptDto receipt,
  ) async {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(l10n.receiptsDeleteConfirmTitle),
        content: Text(l10n.receiptsDeleteConfirmDesc(receipt.originalFilename)),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(transactionReceiptsProvider(transactionId).notifier)
          .deleteReceipt(receipt.id);
      if (context.mounted) {
        AfabToast.showSuccess(context, l10n.receiptsDeletedToast);
      }
    } on AppFailure catch (e) {
      if (context.mounted) AfabToast.showError(context, e.message);
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    this.valueText,
    this.valueWidget,
  });

  final String label;
  final String? valueText;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: valueWidget ??
                Text(
                  valueText ?? '-',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.receipt,
    required this.isEditable,
    required this.onTap,
    required this.onDelete,
  });

  final ReceiptDto receipt;
  final bool isEditable;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (receipt.isPdf ? colors.danger : colors.info)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              receipt.isPdf ? LucideIcons.fileText : LucideIcons.image,
              size: 18,
              color: receipt.isPdf ? colors.danger : colors.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.originalFilename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${receipt.shortTypeLabel} • ${receipt.formattedSize}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.commonView,
            onPressed: onTap,
            icon: Icon(LucideIcons.eye, size: 18, color: colors.textMuted),
          ),
          if (isEditable)
            IconButton(
              tooltip: l10n.commonDelete,
              onPressed: onDelete,
              icon: Icon(LucideIcons.trash2, size: 18, color: colors.danger),
            ),
        ],
      ),
    );
  }
}
