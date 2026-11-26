import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/budgets/domain/budgets_providers.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/currencies/data/currencies_repository.dart';
import 'package:afab_mobile/features/currencies/data/currency_dtos.dart';
import 'package:afab_mobile/features/currencies/domain/currencies_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/invoices/domain/invoices_providers.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `INT-02`: Business Currency Migration Sheet with selectable target
/// currency, live preview, stale-request cancellation, and P1.1 immutability.
Future<CurrencyChangeResultDto?> showCurrencyMigrationSheet(
  BuildContext context,
) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<CurrencyChangeResultDto>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 740),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _CurrencyMigrationBody(showDialogHeader: true),
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<CurrencyChangeResultDto>(
    context: context,
    title: context.l10n.migrationTitle,
    subtitle: context.l10n.migrationSubtitle,
    builder: (ctx) => const _CurrencyMigrationBody(showDialogHeader: false),
  );
}

class _CurrencyMigrationBody extends ConsumerStatefulWidget {
  const _CurrencyMigrationBody({required this.showDialogHeader});

  final bool showDialogHeader;

  @override
  ConsumerState<_CurrencyMigrationBody> createState() =>
      _CurrencyMigrationBodyState();
}

class _CurrencyMigrationBodyState
    extends ConsumerState<_CurrencyMigrationBody> {
  late String _oldCurrency;
  late String _targetCurrency;
  CurrencyChangePreviewDto? _preview;
  bool _loadingPreview = true;
  bool _submitting = false;
  bool _userPickedTarget = false;
  String? _error;
  CancelToken? _previewToken;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    final biz = ref.read(activeBusinessProvider);
    _oldCurrency = (biz?.currency ?? 'USD').toUpperCase();
    _targetCurrency = _oldCurrency == 'USD' ? 'EUR' : 'USD';
    _loadPreview(_targetCurrency);
  }

  @override
  void dispose() {
    _previewToken?.cancel();
    super.dispose();
  }

  Future<void> _loadPreview(String target) async {
    _previewToken?.cancel();
    final token = CancelToken();
    _previewToken = token;
    final reqSeq = ++_seq;

    setState(() {
      _targetCurrency = target;
      _loadingPreview = true;
      _error = null;
    });

    try {
      final preview = await ref
          .read(currenciesRepositoryProvider)
          .previewBusinessCurrencyChange(
            newCurrency: target,
            cancelToken: token,
          );
      if (!mounted || reqSeq != _seq) return;
      setState(() {
        _preview = preview;
        _loadingPreview = false;
      });
    } on AppFailure catch (e) {
      if (!mounted || reqSeq != _seq) return;
      setState(() {
        _loadingPreview = false;
        _error = e.message;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await ref
          .read(currenciesRepositoryProvider)
          .changeBusinessCurrency(newCurrency: _targetCurrency);
      if (!mounted) return;
      ref.invalidate(businessListProvider);
      ref.read(viewBaseCurrencyProvider.notifier).setBase(res.newCurrency);
      ref.invalidate(marketRatesProvider);
      ref.invalidate(directoryRatesMapProvider);
      ref.invalidate(currenciesPortfolioProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(transactionListProvider);
      ref.invalidate(expenseSummaryProvider);
      ref.invalidate(expenseListProvider);
      ref.invalidate(revenueSummaryProvider);
      ref.invalidate(revenueListProvider);
      ref.invalidate(invoicesListProvider);
      ref.invalidate(invoiceSummaryProvider);
      ref.invalidate(budgetListProvider);
      ref.invalidate(budgetOverviewSummaryProvider);

      AfabToast.showSuccess(
        context,
        context.l10n.migrationSuccessToast(res.newCurrency),
      );
      Navigator.of(context).pop(res);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BusinessDto?>(activeBusinessProvider, (prev, next) {
      if (prev == null && next != null && !_userPickedTarget) {
        final newOld = next.currency.toUpperCase();
        if (newOld != _oldCurrency) {
          final nextTarget = newOld == 'USD' ? 'EUR' : 'USD';
          setState(() {
            _oldCurrency = newOld;
            _targetCurrency = nextTarget;
          });
          _loadPreview(nextTarget);
        }
      }
    });

    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final role = (biz?.userRole ?? 'OWNER').toUpperCase();
    final canEdit =
        !(biz?.isReadOnly ?? false) && (role == 'OWNER' || role == 'ADMIN');

    final options = CurrencyCatalog.migrationTargets
        .where((c) => c.code != _oldCurrency)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showDialogHeader) ...[
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.arrowLeftRight,
                  size: 20,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.migrationTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      l10n.migrationSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    _submitting ? null : () => Navigator.of(context).pop(),
                icon: Icon(LucideIcons.x, color: colors.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (!canEdit) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.warningBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(
              l10n.migrationPermissionNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.dangerBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.circleAlert, size: 16, color: colors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.danger),
                  ),
                ),
                TextButton(
                  onPressed: _loadingPreview
                      ? null
                      : () => _loadPreview(_targetCurrency),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        DropdownButtonFormField<String>(
          initialValue: _targetCurrency,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.migrationTargetLabel,
            isDense: true,
          ),
          items: [
            for (final c in options)
              DropdownMenuItem(
                value: c.code,
                child: Text('${c.code} — ${c.name}'),
              ),
          ],
          onChanged: _submitting
              ? null
              : (v) {
                  if (v != null && v != _targetCurrency) {
                    _userPickedTarget = true;
                    _loadPreview(v);
                  }
                },
        ),
        const SizedBox(height: 14),

        if (_loadingPreview)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: AfabLoader(size: 48, label: l10n.migrationFetchingPreview),
          )
        else if (_preview != null) ...[
          AfabInsetPanel(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _preview!.oldCurrency,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '1 ${_preview!.oldCurrency} = ${_preview!.exchangeRate.toDouble().toStringAsFixed(4)} ${_preview!.newCurrency}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _preview!.newCurrency,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AfabInsetPanel(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.migrationCurrentBalance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: MoneyText(
                          amount: _preview!.currentNetBalance,
                          currency: _preview!.oldCurrency,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AfabInsetPanel(
                  padding: const EdgeInsets.all(12),
                  borderColor: colors.primary.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.migrationProjectedBalance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: MoneyText(
                          amount: _preview!.projectedNetBalance,
                          currency: _preview!.newCurrency,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AfabInsetPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(LucideIcons.coins, size: 17, color: colors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.migrationPreservedLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                AfabStatusBadge(
                  label: l10n.migrationPreservedCount(
                    _preview!.transactionsCount,
                  ),
                  variant: AfabBadgeVariant.neutral,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 16,
                      color: colors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.migrationImmutabilityTitle,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.migrationImmutabilityBody(
                    _preview!.newCurrency,
                    _preview!.transactionsCount,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),
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
                label: _submitting
                    ? l10n.migrationUpdating
                    : l10n.migrationConfirmBtn,
                isLoading: _submitting,
                onPressed: (canEdit &&
                        !_loadingPreview &&
                        !_submitting &&
                        _preview != null)
                    ? _submit
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
