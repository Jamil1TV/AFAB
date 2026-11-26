import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:afab_mobile/features/transactions/domain/nlp_transaction_parser.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/transaction_list_card.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class QuickAddBar extends ConsumerStatefulWidget {
  const QuickAddBar({super.key});

  @override
  ConsumerState<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends ConsumerState<QuickAddBar> {
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit(ParsedNlpTransaction parsed) async {
    final l10n = context.l10n;
    if (!parsed.isValid) {
      AfabToast.showError(context, l10n.txQuickAddNoAmount);
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(transactionRepositoryProvider).createTransaction(
            CreateTransactionPayload(
              type: parsed.type,
              amount: parsed.amount!,
              originalCurrency: parsed.currency,
              description: parsed.description,
              transactionDate: parsed.transactionDate,
              categoryId: parsed.categoryId,
              paymentMethod: parsed.paymentMethod,
              status: TransactionStatus.completed,
              taxDeductible: parsed.taxDeductible,
            ),
          );
      _ctrl.clear();
      if (!mounted) return;
      invalidateFinanceLedgers(ref);
      AfabToast.showSuccess(context, l10n.txQuickAddSuccess);
      setState(() {});
    } on AppFailure catch (e) {
      if (!mounted) return;
      AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final defaultCurrency =
        ref.watch(activeBusinessProvider)?.currency ?? 'USD';
    final categories = ref.watch(categoryListProvider).value ?? const [];

    final parsed = _ctrl.text.trim().isNotEmpty
        ? NlpTransactionParser.parse(
            _ctrl.text,
            defaultCurrency: defaultCurrency,
            categories: categories,
          )
        : null;

    return AfabCard(
      padding: const EdgeInsets.all(14),
      borderColor: colors.primary.withValues(alpha: 0.25),
      backgroundColor: colors.secondaryBg.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.txQuickAddTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ctrl,
                  enabled: !_submitting,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) {
                    if (parsed != null) _submit(parsed);
                  },
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: l10n.txQuickAddHint,
                    isDense: true,
                    suffixIcon: _ctrl.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _ctrl.clear();
                              setState(() {});
                            },
                            icon: const Icon(LucideIcons.x, size: 16),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AfabButton(
                label: l10n.txQuickAddSubmit,
                compact: true,
                isLoading: _submitting,
                onPressed: parsed == null ? null : () => _submit(parsed),
              ),
            ],
          ),
          if (parsed != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${l10n.txQuickAddParsedAs}:',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                AfabStatusBadge(
                  label: parsed.type == TransactionType.income
                      ? l10n.txTypeIncome
                      : l10n.txTypeExpense,
                  variant: parsed.type == TransactionType.income
                      ? AfabBadgeVariant.success
                      : AfabBadgeVariant.primary,
                ),
                if (parsed.amount != null)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: AfabStatusBadge(
                      label: MoneyFormatter.formatDecimal(
                        parsed.amount!,
                        currency: parsed.currency,
                      ),
                      variant: AfabBadgeVariant.info,
                    ),
                  ),
                if (parsed.categoryName != null)
                  AfabStatusBadge(
                    label: parsed.categoryName!,
                    variant: AfabBadgeVariant.neutral,
                  ),
                AfabStatusBadge(
                  label: localizedPaymentMethodLabel(
                    context,
                    parsed.paymentMethod,
                  ),
                  variant: AfabBadgeVariant.neutral,
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: AfabStatusBadge(
                    label: parsed.transactionDate,
                    variant: AfabBadgeVariant.neutral,
                  ),
                ),
                if (parsed.taxDeductible)
                  AfabStatusBadge(
                    label: l10n.txBadgeTax,
                    variant: AfabBadgeVariant.info,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
