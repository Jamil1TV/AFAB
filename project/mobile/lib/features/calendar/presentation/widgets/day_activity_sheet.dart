import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> showDayActivitySheet(
  BuildContext context, {
  required String isoDate,
  required String dateFormat,
  required String baseCurrency,
  required bool isEditable,
  required List<TransactionDto> transactions,
  required List<InvoiceDto> dueInvoices,
  required List<RecurringTransactionDto> recurringRuns,
}) {
  final locale = Localizations.localeOf(context).languageCode;
  final formatted = AfabDateFormatter.formatIsoDate(
    isoDate,
    dateFormat: dateFormat,
    locale: locale,
  );
  return showAfabBottomSheet<void>(
    context: context,
    title: context.l10n.calendarSelectedDateTitle,
    subtitle: formatted,
    builder: (sheetCtx) => DayActivityContent(
      isoDate: isoDate,
      dateFormat: dateFormat,
      baseCurrency: baseCurrency,
      isEditable: isEditable,
      transactions: transactions,
      dueInvoices: dueInvoices,
      recurringRuns: recurringRuns,
      onBeforeNavigate: () => Navigator.of(sheetCtx).pop(),
    ),
  );
}

class DayActivityContent extends StatelessWidget {
  const DayActivityContent({
    super.key,
    required this.isoDate,
    required this.dateFormat,
    required this.baseCurrency,
    required this.isEditable,
    required this.transactions,
    required this.dueInvoices,
    required this.recurringRuns,
    this.onBeforeNavigate,
  });

  final String isoDate;
  final String dateFormat;
  final String baseCurrency;
  final bool isEditable;
  final List<TransactionDto> transactions;
  final List<InvoiceDto> dueInvoices;
  final List<RecurringTransactionDto> recurringRuns;
  final VoidCallback? onBeforeNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final totalCount =
        transactions.length + dueInvoices.length + recurringRuns.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AfabDateFormatter.formatIsoDate(
                    isoDate,
                    dateFormat: dateFormat,
                    locale: locale,
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                AfabStatusBadge(
                  label: l10n.calendarEntriesCount(totalCount),
                  variant: AfabBadgeVariant.primary,
                ),
              ],
            ),
            if (isEditable)
              AfabButton(
                label: l10n.txAddButton,
                icon: LucideIcons.plus,
                compact: true,
                onPressed: () {
                  onBeforeNavigate?.call();
                  context.push('/transactions/new?date=$isoDate');
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (totalCount == 0)
          AfabEmptyState(
            icon: LucideIcons.receipt,
            title: l10n.commonNoData,
            description: l10n.calendarNoActivityDate,
          )
        else ...[
          for (final tx in transactions) ...[
            _CalendarTxTile(
              tx: tx,
              fallbackCurrency: baseCurrency,
              onTap: () {
                onBeforeNavigate?.call();
                context.push('/transactions/${tx.id}', extra: tx);
              },
            ),
            const SizedBox(height: 8),
          ],
          if (dueInvoices.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.calendarOverlayInvoicesDue,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colors.warning, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final inv in dueInvoices) ...[
              AfabInsetPanel(
                padding: const EdgeInsets.all(12),
                borderColor: colors.warning.withValues(alpha: 0.3),
                child: InkWell(
                  onTap: () {
                    onBeforeNavigate?.call();
                    context.push('/invoices/${inv.id}');
                  },
                  child: Row(
                    children: [
                      Icon(LucideIcons.fileText, size: 17, color: colors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                inv.invoiceNumber,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Text(
                              inv.customerName ?? l10n.invoicesWalkInCustomer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyText(
                        amount: inv.outstandingBalance,
                        currency: inv.currency,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (recurringRuns.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.calendarOverlayRecurring,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colors.info, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final r in recurringRuns) ...[
              AfabInsetPanel(
                padding: const EdgeInsets.all(12),
                borderColor: colors.info.withValues(alpha: 0.3),
                child: InkWell(
                  onTap: () {
                    onBeforeNavigate?.call();
                    context.go('/recurring');
                  },
                  child: Row(
                    children: [
                      Icon(LucideIcons.repeat, size: 17, color: colors.info),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyText(
                        amount: r.amount,
                        currency: r.currency,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ],
    );
  }
}

class _CalendarTxTile extends StatelessWidget {
  const _CalendarTxTile({
    required this.tx,
    required this.fallbackCurrency,
    required this.onTap,
  });

  final TransactionDto tx;
  final String fallbackCurrency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final isIncome = tx.type == TransactionType.income;
    final tint = isIncome ? colors.success : colors.danger;
    final curr = tx.currency.isNotEmpty ? tx.currency : fallbackCurrency;

    return AfabInsetPanel(
      padding: const EdgeInsets.all(12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                isIncome
                    ? LucideIcons.arrowUpRight
                    : LucideIcons.arrowDownLeft,
                size: 16,
                color: tint,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${tx.categoryName ?? l10n.txDetailsUncategorized} · ${tx.status.apiValue}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MoneyText(
              amount: isIncome ? tx.amount : -tx.amount,
              currency: curr,
              showSign: true,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
