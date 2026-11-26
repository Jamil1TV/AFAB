import 'dart:async';

import 'package:afab_mobile/core/config/business_constants.dart';
import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/currency_minor_units.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/transaction_list_card.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `FIN-03`: Create, Duplicate (`POST`), or Edit (`PUT`) a transaction
/// with live FX preview, optional custom FX rate, full `status`, and `CREDIT_CARD`.
class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({
    super.key,
    required this.mode,
    this.transactionId,
    this.initialTransaction,
    this.initialType = TransactionType.expense,
    this.initialDate,
  });

  final TransactionFormMode mode;
  final String? transactionId;
  final TransactionDto? initialTransaction;
  final TransactionType initialType;
  final String? initialDate;

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _customRateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _taxRateCtrl = TextEditingController();

  late TransactionType _type;
  String _currency = 'USD';
  late String _transactionDate;
  String? _categoryId;
  PaymentMethod _paymentMethod = PaymentMethod.bankTransfer;
  TransactionStatus _status = TransactionStatus.completed;
  bool _taxDeductible = false;
  bool _showCustomRate = false;
  bool _submitting = false;
  bool _dirty = false;
  bool _hydratedFromSeed = false;

  TransactionDto? _loadedEditTx;
  String? _serverError;
  Map<String, String> _fieldErrors = const {};

  Timer? _fxDebounce;
  CancelToken? _fxCancelToken;
  AsyncValue<FxConvertResultDto?> _fxQuote = const AsyncValue.data(null);

  bool get _isEditing => widget.mode == TransactionFormMode.edit;
  bool get _isDuplicate => widget.mode == TransactionFormMode.duplicate;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final seedDate = widget.initialDate?.trim();
    _transactionDate = (seedDate != null &&
            seedDate.isNotEmpty &&
            DateTime.tryParse(seedDate) != null)
        ? seedDate
        : intl.DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now());
    final seed = widget.initialTransaction;
    if (seed != null) {
      _applySeed(seed);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final bizCurr = ref.read(activeBusinessProvider)?.currency ?? 'USD';
        setState(() => _currency = bizCurr.toUpperCase());
        if ((_isEditing || _isDuplicate) && widget.transactionId != null) {
          _fetchSeedById(widget.transactionId!);
        }
      });
    }
  }

  Future<void> _fetchSeedById(String id) async {
    try {
      final tx =
          await ref.read(transactionRepositoryProvider).getTransactionById(id);
      if (!mounted) return;
      _applySeed(tx);
    } catch (_) {
      // Initial fallback remains editable if direct fetch fails.
    }
  }

  void _applySeed(TransactionDto seed) {
    if (_hydratedFromSeed) return;
    _hydratedFromSeed = true;
    final bizCurr = ref.read(activeBusinessProvider)?.currency ??
        seed.resolvedBaseCurrency;

    final seedAmount = (seed.hasForeignFx && seed.originalAmount != null)
        ? seed.originalAmount!
        : seed.amount;
    final seedCurrency = (seed.originalCurrency != null &&
            seed.originalCurrency!.isNotEmpty)
        ? seed.originalCurrency!.toUpperCase()
        : (seed.resolvedBaseCurrency.isNotEmpty
            ? seed.resolvedBaseCurrency.toUpperCase()
            : bizCurr.toUpperCase());

    setState(() {
      _loadedEditTx = seed;
      _type = seed.type;
      _descCtrl.text = seed.description;
      _amountCtrl.text = seedAmount.toString();
      _currency = seedCurrency;
      _transactionDate = _isDuplicate
          ? intl.DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now())
          : seed.transactionDate;
      _categoryId = seed.categoryId;
      _paymentMethod = seed.paymentMethod;
      _status = seed.status;
      _notesCtrl.text = seed.notes ?? '';
      _taxDeductible = seed.taxDeductible;
      if (seed.taxRate != null) {
        _taxRateCtrl.text = seed.taxRate.toString();
      }
      _dirty = false;
    });

    if (!_isEditing) {
      _scheduleFxQuote();
    }
  }

  @override
  void dispose() {
    _fxDebounce?.cancel();
    _fxCancelToken?.cancel();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _customRateCtrl.dispose();
    _notesCtrl.dispose();
    _taxRateCtrl.dispose();
    super.dispose();
  }

  void _scheduleFxQuote() {
    if (_isEditing) return;
    _fxDebounce?.cancel();
    _fxCancelToken?.cancel();

    final baseCurr =
        (ref.read(activeBusinessProvider)?.currency ?? 'USD').toUpperCase();
    final parsedAmt = Decimal.tryParse(_amountCtrl.text.trim());
    if (_currency.toUpperCase() == baseCurr ||
        parsedAmt == null ||
        parsedAmt <= Decimal.zero) {
      setState(() => _fxQuote = const AsyncValue.data(null));
      return;
    }

    _fxDebounce = Timer(const Duration(milliseconds: 300), () async {
      final token = CancelToken();
      _fxCancelToken = token;
      setState(() => _fxQuote = const AsyncValue.loading());
      try {
        final quote = await ref
            .read(transactionRepositoryProvider)
            .convertCurrency(
              from: _currency,
              to: baseCurr,
              amount: parsedAmt,
              cancelToken: token,
            );
        if (mounted && !token.isCancelled) {
          setState(() => _fxQuote = AsyncValue.data(quote));
        }
      } catch (e, st) {
        if (e is DioException && CancelToken.isCancel(e)) return;
        if (mounted) {
          setState(() => _fxQuote = AsyncValue.error(e, st));
        }
      }
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = context.l10n;
    final res = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(l10n.commonDiscardTitle),
        content: Text(l10n.commonDiscardDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: Text(l10n.commonKeepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: Text(l10n.commonDiscardConfirm),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _submit() async {
    setState(() {
      _serverError = null;
      _fieldErrors = const {};
    });
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final parsedAmount = Decimal.tryParse(_amountCtrl.text.trim());
    if (parsedAmount == null || parsedAmount < Decimal.parse('0.0001')) {
      setState(() {
        _fieldErrors = {'amount': l10n.txFormAmountInvalid};
      });
      return;
    }

    Decimal? taxRate;
    if (_taxDeductible && _taxRateCtrl.text.trim().isNotEmpty) {
      taxRate = Decimal.tryParse(_taxRateCtrl.text.trim());
      if (taxRate == null ||
          taxRate < Decimal.zero ||
          taxRate > Decimal.fromInt(100)) {
        setState(() {
          _fieldErrors = {'taxRate': l10n.txFormTaxRateInvalid};
        });
        return;
      }
    }

    Decimal? customRate;
    final baseCurr =
        (ref.read(activeBusinessProvider)?.currency ?? 'USD').toUpperCase();
    if (!_isEditing &&
        _showCustomRate &&
        _currency.toUpperCase() != baseCurr &&
        _customRateCtrl.text.trim().isNotEmpty) {
      customRate = Decimal.tryParse(_customRateCtrl.text.trim());
      if (customRate == null || customRate < Decimal.parse('0.000001')) {
        setState(() {
          _fieldErrors = {'exchangeRate': l10n.txFormAmountInvalid};
        });
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      TransactionDto saved;
      if (_isEditing && widget.transactionId != null) {
        saved = await ref.read(transactionRepositoryProvider).updateTransaction(
              widget.transactionId!,
              UpdateTransactionPayload(
                type: _type,
                amount: parsedAmount,
                description: _descCtrl.text.trim(),
                transactionDate: _transactionDate,
                categoryId: _categoryId,
                paymentMethod: _paymentMethod,
                status: _status,
                notes: _notesCtrl.text,
                taxDeductible: _taxDeductible,
                taxRate: _taxDeductible ? taxRate : null,
              ),
            );
      } else {
        saved = await ref.read(transactionRepositoryProvider).createTransaction(
              CreateTransactionPayload(
                type: _type,
                amount: parsedAmount,
                originalCurrency: _currency.toUpperCase(),
                exchangeRate: customRate,
                description: _descCtrl.text.trim(),
                transactionDate: _transactionDate,
                categoryId: _categoryId,
                paymentMethod: _paymentMethod,
                status: _status,
                notes: _notesCtrl.text,
                taxDeductible: _taxDeductible,
                taxRate: _taxDeductible ? taxRate : null,
              ),
            );
      }

      if (!mounted) return;
      invalidateFinanceLedgers(
        ref,
        editedTransactionId: _isEditing ? widget.transactionId : null,
      );
      AfabToast.showSuccess(context, l10n.txFormSavedToast);
      Navigator.of(context).pop(saved);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _serverError = e.message;
        _fieldErrors = e is ValidationFailure ? e.fieldErrors : const {};
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDate() async {
    final parsed = DateTime.tryParse(_transactionDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
      locale: Localizations.localeOf(context),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _transactionDate = intl.DateFormat('yyyy-MM-dd', 'en_US').format(picked);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final biz = ref.watch(activeBusinessProvider);
    final baseCurr = (biz?.currency ?? 'USD').toUpperCase();
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';

    final allCats = ref.watch(categoryListProvider).value ?? const [];
    final matchingCats = allCats
        .where((c) => c.type.toUpperCase() == _type.apiValue)
        .toList();

    final effectiveCategoryId =
        matchingCats.any((c) => c.id == _categoryId) ? _categoryId : null;

    final title = switch (widget.mode) {
      TransactionFormMode.create => l10n.txFormAddTitle,
      TransactionFormMode.duplicate => l10n.txFormDuplicateTitle,
      TransactionFormMode.edit => l10n.txFormEditTitle,
    };

    final currencyCodes = {
      baseCurr,
      _currency.toUpperCase(),
      ...BusinessConstants.currencies.map((e) => e.code),
    }.toList();

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_serverError != null) ...[
                          AfabInsetPanel(
                            borderColor: colors.danger.withValues(alpha: 0.45),
                            child: Text(
                              _serverError!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_isEditing &&
                            (_loadedEditTx?.isSplit ?? false)) ...[
                          AfabInsetPanel(
                            borderColor: colors.info.withValues(alpha: 0.45),
                            child: Text(
                              l10n.txFormSplitEditNotice,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Center(
                          child: AfabSegmentedBar<TransactionType>(
                            items: [
                              AfabSegmentItem(
                                value: TransactionType.income,
                                label: l10n.txTypeIncome,
                              ),
                              AfabSegmentItem(
                                value: TransactionType.expense,
                                label: l10n.txTypeExpense,
                              ),
                            ],
                            selectedValue: _type,
                            onSelected: (next) {
                              if (next == _type) return;
                              setState(() {
                                _type = next;
                                _categoryId = null;
                                _dirty = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.txFormDescriptionLabel,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descCtrl,
                          maxLength: 255,
                          decoration: InputDecoration(
                            hintText: l10n.txFormDescriptionHint,
                            errorText: _fieldErrors['description'],
                          ),
                          onChanged: (_) => _dirty = true,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.authFieldRequired
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.txFormAmountLabel,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: TextFormField(
                                      controller: _amountCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        errorText: _fieldErrors['amount'],
                                      ),
                                      onChanged: (_) {
                                        _dirty = true;
                                        _scheduleFxQuote();
                                      },
                                      validator: (v) {
                                        final dec =
                                            Decimal.tryParse((v ?? '').trim());
                                        if (dec == null ||
                                            dec < Decimal.parse('0.0001')) {
                                          return l10n.txFormAmountInvalid;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.txFormCurrencyLabel,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    initialValue: _currency.toUpperCase(),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      suffixIcon: _isEditing
                                          ? const Icon(
                                              LucideIcons.lock,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    items: [
                                      for (final code in currencyCodes)
                                        DropdownMenuItem(
                                          value: code,
                                          child: Text(
                                            code == baseCurr
                                                ? '$code (Base)'
                                                : code,
                                          ),
                                        ),
                                    ],
                                    onChanged: _isEditing
                                        ? null
                                        : (val) {
                                            if (val == null) return;
                                            setState(() {
                                              _currency = val;
                                              _dirty = true;
                                            });
                                            _scheduleFxQuote();
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // FX Snapshot / Quote Banner
                        if (_isEditing) ...[
                          const SizedBox(height: 10),
                          AfabInsetPanel(
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.lock,
                                  size: 15,
                                  color: colors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.txFormFxLockedNotice,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_currency.toUpperCase() != baseCurr) ...[
                          const SizedBox(height: 10),
                          AfabInsetPanel(
                            borderColor: colors.primary.withValues(alpha: 0.35),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _fxQuote.when(
                                  loading: () => const Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('FX...'),
                                    ],
                                  ),
                                  error: (_, _) => Text(
                                    l10n.txFormFxOfflineHint,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  data: (quote) {
                                    if (quote == null) {
                                      return Text(
                                        '$_currency → $baseCurr',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      );
                                    }
                                    return Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        '1 ${quote.from} = ${quote.exchangeRate.toStringAsFixed(6)} ${quote.to}  ≈  ${MoneyFormatter.formatDecimal(quote.convertedAmount, currency: quote.to)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => setState(
                                    () => _showCustomRate = !_showCustomRate,
                                  ),
                                  child: Text(
                                    l10n.txFormCustomRateToggle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: colors.primary),
                                  ),
                                ),
                                if (_showCustomRate) ...[
                                  const SizedBox(height: 8),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: TextFormField(
                                      controller: _customRateCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: InputDecoration(
                                        labelText:
                                            l10n.txFormCustomRateLabel(baseCurr),
                                        isDense: true,
                                        errorText: _fieldErrors['exchangeRate'],
                                      ),
                                      onChanged: (_) => _dirty = true,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.txFormDateLabel,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        suffixIcon: Icon(
                                          LucideIcons.calendarDays,
                                          size: 16,
                                        ),
                                      ),
                                      child: Text(
                                        AfabDateFormatter.formatIsoDate(
                                          _transactionDate,
                                          dateFormat: dateFmt,
                                          locale: locale,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.txFilterStatus,
                                    style:
                                        Theme.of(context).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<TransactionStatus>(
                                    initialValue: _status,
                                    isExpanded: true,
                                    items: [
                                      for (final st in TransactionStatus.values)
                                        DropdownMenuItem(
                                          value: st,
                                          child: Text(
                                            localizedStatusLabel(context, st),
                                          ),
                                        ),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      setState(() {
                                        _status = val;
                                        _dirty = true;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              l10n.txFilterCategory,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            TextButton(
                              onPressed: () => context.push('/categories'),
                              child: Text(l10n.txCatTitle),
                            ),
                          ],
                        ),
                        DropdownButtonFormField<String?>(
                          initialValue: effectiveCategoryId,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.txDetailsUncategorized),
                            ),
                            for (final cat in matchingCats)
                              DropdownMenuItem<String?>(
                                value: cat.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: ColorParser.parseHex(
                                          cat.color,
                                          colors.primary,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          onChanged: (val) => setState(() {
                            _categoryId = val;
                            _dirty = true;
                          }),
                        ),

                        const SizedBox(height: 14),
                        Text(
                          l10n.txFilterPaymentMethod,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<PaymentMethod>(
                          initialValue: _paymentMethod,
                          isExpanded: true,
                          items: [
                            for (final pm in PaymentMethod.values)
                              DropdownMenuItem(
                                value: pm,
                                child: Text(
                                  localizedPaymentMethodLabel(context, pm),
                                ),
                              ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() {
                              _paymentMethod = val;
                              _dirty = true;
                            });
                          },
                        ),

                        const SizedBox(height: 14),
                        Text(
                          l10n.txFormNotesLabel,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          maxLength: 1000,
                          onChanged: (_) => _dirty = true,
                        ),

                        const SizedBox(height: 10),
                        AfabInsetPanel(
                          child: Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() {
                                  _taxDeductible = !_taxDeductible;
                                  _dirty = true;
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          l10n.txFormTaxSwitch,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Switch.adaptive(
                                        value: _taxDeductible,
                                        onChanged: (val) => setState(() {
                                          _taxDeductible = val;
                                          _dirty = true;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_taxDeductible) ...[
                                const SizedBox(height: 8),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextFormField(
                                    controller: _taxRateCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.txFormTaxRateLabel,
                                      hintText: '19.0',
                                      errorText: _fieldErrors['taxRate'],
                                    ),
                                    onChanged: (_) => _dirty = true,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(top: BorderSide(color: colors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AfabButton(
                            label: l10n.commonCancel,
                            variant: AfabButtonVariant.secondary,
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final ok = await _confirmDiscard();
                                    if (ok && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AfabButton(
                            label: _isEditing
                                ? l10n.txFormSubmitEdit
                                : l10n.txFormSubmitCreate,
                            isLoading: _submitting,
                            onPressed: _submit,
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
      ),
    );
  }
}

/// Convenience helper for Decimal minor-unit hint formatting if needed.
String formatDecimalPlain(Decimal value, String currency) {
  final scale = CurrencyMinorUnits.decimalsFor(currency);
  return value.round(scale: scale).toStringAsFixed(scale);
}

Widget buildTxFormLoadingPlaceholder() => const AfabListSkeleton(count: 4);
