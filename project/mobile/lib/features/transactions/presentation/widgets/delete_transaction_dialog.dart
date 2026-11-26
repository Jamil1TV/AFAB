import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:flutter/material.dart';

Future<bool> showDeleteTransactionDialog(
  BuildContext context, {
  required TransactionDto transaction,
  required String fallbackCurrency,
}) async {
  final l10n = context.l10n;
  final colors = context.afabColors;
  final baseCurr = transaction.resolvedBaseCurrency.isNotEmpty
      ? transaction.resolvedBaseCurrency
      : fallbackCurrency;
  final formatted = MoneyFormatter.formatDecimal(
    transaction.amount,
    currency: baseCurr,
  );

  final res = await showDialog<bool>(
    context: context,
    builder: (dlgCtx) => AlertDialog(
      title: Text(l10n.txDeleteConfirmTitle),
      content: Text(
        l10n.txDeleteConfirmDesc(transaction.description, formatted),
      ),
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
  return res ?? false;
}
