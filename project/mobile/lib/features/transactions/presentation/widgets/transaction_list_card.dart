import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String localizedStatusLabel(BuildContext context, TransactionStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    TransactionStatus.completed => l10n.txStatusCompleted,
    TransactionStatus.pending => l10n.txStatusPending,
    TransactionStatus.cancelled => l10n.txStatusCancelled,
  };
}

AfabBadgeVariant badgeVariantForStatus(TransactionStatus status) {
  return switch (status) {
    TransactionStatus.completed => AfabBadgeVariant.success,
    TransactionStatus.pending => AfabBadgeVariant.warning,
    TransactionStatus.cancelled => AfabBadgeVariant.danger,
  };
}

String localizedPaymentMethodLabel(BuildContext context, PaymentMethod method) {
  final l10n = context.l10n;
  return switch (method) {
    PaymentMethod.bankTransfer => l10n.txMethodBankTransfer,
    PaymentMethod.card => l10n.txMethodCard,
    PaymentMethod.creditCard => l10n.txMethodCreditCard,
    PaymentMethod.cash => l10n.txMethodCash,
    PaymentMethod.other => l10n.txMethodOther,
  };
}

class TransactionListCard extends StatelessWidget {
  const TransactionListCard({
    super.key,
    required this.transaction,
    required this.fallbackCurrency,
    this.dateFormat = 'YYYY-MM-DD',
    this.selected = false,
    this.isReadOnly = false,
    this.onTap,
    this.onDuplicate,
    this.onEdit,
    this.onDelete,
  });

  final TransactionDto transaction;
  final String fallbackCurrency;
  final String dateFormat;
  final bool selected;
  final bool isReadOnly;
  final VoidCallback? onTap;
  final VoidCallback? onDuplicate;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final isIncome = transaction.isIncome;
    final iconColor = isIncome ? colors.success : colors.primary;
    final baseCurr = transaction.resolvedBaseCurrency.isNotEmpty
        ? transaction.resolvedBaseCurrency
        : fallbackCurrency;

    final formattedDate = AfabDateFormatter.formatIsoDate(
      transaction.transactionDate,
      dateFormat: dateFormat,
      locale: locale,
    );

    final signedAmount = isIncome ? transaction.amount : -transaction.amount;

    return AfabCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: selected ? colors.primary : null,
      backgroundColor:
          selected ? colors.secondaryBg.withValues(alpha: 0.45) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncome
                      ? LucideIcons.trendingUp
                      : LucideIcons.arrowRightLeft,
                  size: 18,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.categoryName ?? (transaction.isSplit ? l10n.txBadgeSplit : l10n.txDetailsUncategorized)} • $formattedDate • ${localizedPaymentMethodLabel(context, transaction.paymentMethod)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    amount: signedAmount,
                    currency: baseCurr,
                    showSign: isIncome,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isIncome ? colors.success : colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  AfabStatusBadge(
                    label: localizedStatusLabel(context, transaction.status),
                    variant: badgeVariantForStatus(transaction.status),
                  ),
                ],
              ),
              if (!isReadOnly &&
                  (onDuplicate != null || onEdit != null || onDelete != null))
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: colors.textMuted,
                  ),
                  onSelected: (choice) {
                    if (choice == 'view') onTap?.call();
                    if (choice == 'duplicate') onDuplicate?.call();
                    if (choice == 'edit') onEdit?.call();
                    if (choice == 'delete') onDelete?.call();
                  },
                  itemBuilder: (menuCtx) => [
                    if (onTap != null)
                      PopupMenuItem(
                        value: 'view',
                        child: Text(l10n.commonView),
                      ),
                    if (onDuplicate != null)
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(l10n.txActionDuplicate),
                      ),
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.commonEdit),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l10n.commonDelete,
                          style: TextStyle(color: colors.danger),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (transaction.potentialDuplicate ||
              (transaction.priceHikePercentage != null &&
                  transaction.priceHikePercentage! > Decimal.zero) ||
              transaction.taxDeductible ||
              transaction.isSplit ||
              transaction.hasForeignFx) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (transaction.potentialDuplicate)
                  AfabStatusBadge(
                    label: l10n.txBadgeDuplicate,
                    variant: AfabBadgeVariant.warning,
                    icon: LucideIcons.triangleAlert,
                  ),
                if (transaction.priceHikePercentage != null &&
                    transaction.priceHikePercentage! > Decimal.zero)
                  AfabStatusBadge(
                    label: l10n.txBadgePriceHike(
                      transaction.priceHikePercentage!.toStringAsFixed(0),
                    ),
                    variant: AfabBadgeVariant.primary,
                    icon: LucideIcons.trendingUp,
                  ),
                if (transaction.taxDeductible)
                  AfabStatusBadge(
                    label: l10n.txBadgeTax,
                    variant: AfabBadgeVariant.info,
                  ),
                if (transaction.isSplit)
                  AfabStatusBadge(
                    label: l10n.txBadgeSplit,
                    variant: AfabBadgeVariant.primary,
                    icon: LucideIcons.layers,
                  ),
                if (transaction.hasForeignFx &&
                    transaction.originalAmount != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: AfabStatusBadge(
                      label:
                          '${transaction.originalAmount} ${transaction.originalCurrency}',
                      variant: AfabBadgeVariant.neutral,
                      icon: LucideIcons.globe,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
