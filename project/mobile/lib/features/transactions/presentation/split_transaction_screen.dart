import 'package:afab_mobile/core/config/business_constants.dart';
import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/currency_minor_units.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/transaction_list_card.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _SplitLineDraft {
  _SplitLineDraft({
    required this.localId,
    this.categoryId,
    String initialAmount = '',
    String initialMemo = '',
  })  : amountCtrl = TextEditingController(text: initialAmount),
        memoCtrl = TextEditingController(text: initialMemo);

  final int localId;
  String? categoryId;
  final TextEditingController amountCtrl;
  final TextEditingController memoCtrl;

  void dispose() {
    amountCtrl.dispose();
    memoCtrl.dispose();
  }
}

/// Screen `FIN-04`: Multi-category split allocation using exact `Decimal`
/// equality (zero IEEE-754 drift), dynamic currency formatting (`Balanced (DT 0.000)`),
/// `INCOME`/`EXPENSE` toggle, and async category default hydration.
class SplitTransactionScreen extends ConsumerStatefulWidget {
  const SplitTransactionScreen({super.key});

  @override
  ConsumerState<SplitTransactionScreen> createState() =>
      _SplitTransactionScreenState();
}

class _SplitTransactionScreenState
    extends ConsumerState<SplitTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int _nextId = 1;
  TransactionType _type = TransactionType.expense;
  String _currency = 'USD';
  late String _transactionDate;
  PaymentMethod _paymentMethod = PaymentMethod.card;
  TransactionStatus _status = TransactionStatus.completed;
  bool _taxDeductible = false;
  bool _submitting = false;
  bool _dirty = false;
  String? _errorBanner;

  late final List<_SplitLineDraft> _lines = [
    _SplitLineDraft(localId: _nextId++),
    _SplitLineDraft(localId: _nextId++),
  ];

  @override
  void initState() {
    super.initState();
    _transactionDate = intl.DateFormat('yyyy-MM-dd', 'en_US').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bizCurr =
          (ref.read(activeBusinessProvider)?.currency ?? 'USD').toUpperCase();
      setState(() => _currency = bizCurr);
      _hydrateDefaultCategories(ref.read(categoryListProvider).value ?? const []);
    });
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _descCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _hydrateDefaultCategories(List<CategoryDto> all) {
    final matching =
        all.where((c) => c.type.toUpperCase() == _type.apiValue).toList();
    if (matching.isEmpty) return;

    var changed = false;
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final validExisting = matching.any((c) => c.id == line.categoryId);
      if (!validExisting) {
        line.categoryId = matching[i % matching.length].id;
        changed = true;
      }
    }
    if (changed && mounted) setState(() {});
  }

  Decimal get _totalDecimal =>
      Decimal.tryParse(_totalCtrl.text.trim()) ?? Decimal.zero;

  Decimal get _allocatedDecimal {
    var sum = Decimal.zero;
    for (final line in _lines) {
      final v = Decimal.tryParse(line.amountCtrl.text.trim());
      if (v != null && v > Decimal.zero) {
        sum += v;
      }
    }
    return sum;
  }

  Decimal get _remainingDecimal => _totalDecimal - _allocatedDecimal;

  bool get _isBalanced =>
      _totalDecimal > Decimal.zero && _remainingDecimal == Decimal.zero;

  void _addLine() {
    final cats = (ref.read(categoryListProvider).value ?? const [])
        .where((c) => c.type.toUpperCase() == _type.apiValue)
        .toList();
    setState(() {
      _lines.add(
        _SplitLineDraft(
          localId: _nextId++,
          categoryId:
              cats.isNotEmpty ? cats[_lines.length % cats.length].id : null,
        ),
      );
      _dirty = true;
    });
  }

  void _removeLine(int index) {
    final l10n = context.l10n;
    if (_lines.length <= 2) {
      AfabToast.showError(context, l10n.txSplitMinLinesError);
      return;
    }
    setState(() {
      final removed = _lines.removeAt(index);
      removed.dispose();
      _dirty = true;
    });
  }

  void _fillLine(int index) {
    final line = _lines[index];
    final current = Decimal.tryParse(line.amountCtrl.text.trim()) ?? Decimal.zero;
    final target = current + _remainingDecimal;
    if (target <= Decimal.zero) return;
    final scale = CurrencyMinorUnits.decimalsFor(_currency);
    setState(() {
      line.amountCtrl.text = target.round(scale: scale).toStringAsFixed(scale);
      _dirty = true;
    });
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

  Future<void> _submit() async {
    setState(() => _errorBanner = null);
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    if (_lines.length < 2) {
      setState(() => _errorBanner = l10n.txSplitMinLinesError);
      return;
    }
    if (!_isBalanced) {
      setState(() => _errorBanner = l10n.txSplitUnbalancedError);
      return;
    }

    final splitPayloads = <SplitLinePayload>[];
    for (final line in _lines) {
      final amt = Decimal.tryParse(line.amountCtrl.text.trim());
      if (amt == null || amt < Decimal.parse('0.0001')) {
        setState(() => _errorBanner = l10n.txFormAmountInvalid);
        return;
      }
      if (line.categoryId == null || line.categoryId!.isEmpty) {
        setState(() => _errorBanner = l10n.authFieldRequired);
        return;
      }
      splitPayloads.add(
        SplitLinePayload(
          categoryId: line.categoryId!,
          amount: amt,
          description: line.memoCtrl.text,
        ),
      );
    }

    setState(() => _submitting = true);
    try {
      await ref.read(transactionRepositoryProvider).createTransaction(
            CreateTransactionPayload(
              type: _type,
              amount: _totalDecimal,
              originalCurrency: _currency,
              description: _descCtrl.text.trim(),
              transactionDate: _transactionDate,
              paymentMethod: _paymentMethod,
              status: _status,
              taxDeductible: _taxDeductible,
              splitItems: splitPayloads,
            ),
          );
      if (!mounted) return;
      invalidateFinanceLedgers(ref);
      AfabToast.showSuccess(context, l10n.txFormSavedToast);
      Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final biz = ref.watch(activeBusinessProvider);
    final baseCurr = (biz?.currency ?? 'USD').toUpperCase();
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';

    ref.listen<AsyncValue<List<CategoryDto>>>(
      categoryListProvider,
      (_, next) {
        if (next.hasValue) {
          _hydrateDefaultCategories(next.value!);
        }
      },
    );

    final allCats = ref.watch(categoryListProvider).value ?? const [];
    final matchingCats = allCats
        .where((c) => c.type.toUpperCase() == _type.apiValue)
        .toList();

    final currencyCodes = {
      baseCurr,
      _currency.toUpperCase(),
      ...BusinessConstants.currencies.map((e) => e.code),
    }.toList();

    final zeroBalancedFormatted = MoneyFormatter.formatDecimal(
      Decimal.zero,
      currency: _currency,
    );

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
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
        if (discard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(title: Text(l10n.txSplitTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        l10n.txSplitSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (_errorBanner != null) ...[
                        AfabInsetPanel(
                          borderColor: colors.danger.withValues(alpha: 0.45),
                          child: Text(
                            _errorBanner!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                              for (final l in _lines) {
                                l.categoryId = null;
                              }
                              _dirty = true;
                            });
                            _hydrateDefaultCategories(allCats);
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      AfabInsetPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.txSplitTotalAmount,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: TextFormField(
                                          controller: _totalCtrl,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration:
                                              const InputDecoration(hintText: '0.00'),
                                          onChanged: (_) => setState(() {
                                            _dirty = true;
                                          }),
                                          validator: (v) {
                                            final dec = Decimal.tryParse(
                                              (v ?? '').trim(),
                                            );
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.txFormCurrencyLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        initialValue: _currency.toUpperCase(),
                                        isExpanded: true,
                                        items: [
                                          for (final code in currencyCodes)
                                            DropdownMenuItem(
                                              value: code,
                                              child: Text(code),
                                            ),
                                        ],
                                        onChanged: (val) {
                                          if (val == null) return;
                                          setState(() {
                                            _currency = val;
                                            _dirty = true;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.txSplitVendorLabel,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descCtrl,
                              maxLength: 255,
                              decoration: InputDecoration(
                                hintText: l10n.txFormDescriptionHint,
                              ),
                              onChanged: (_) => _dirty = true,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? l10n.authFieldRequired
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: l10n.txFormDateLabel,
                                        suffixIcon: const Icon(
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
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<PaymentMethod>(
                                    initialValue: _paymentMethod,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: l10n.txFilterPaymentMethod,
                                    ),
                                    items: [
                                      for (final pm in PaymentMethod.values)
                                        DropdownMenuItem(
                                          value: pm,
                                          child: Text(
                                            localizedPaymentMethodLabel(
                                              context,
                                              pm,
                                            ),
                                          ),
                                        ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _paymentMethod = val;
                                          _dirty = true;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      DropdownButtonFormField<TransactionStatus>(
                                    initialValue: _status,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: l10n.txFilterStatus,
                                    ),
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
                                      if (val != null) {
                                        setState(() {
                                          _status = val;
                                          _dirty = true;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => setState(() {
                                      _taxDeductible = !_taxDeductible;
                                      _dirty = true;
                                    }),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l10n.txBadgeTax,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Switch.adaptive(
                                          value: _taxDeductible,
                                          onChanged: (v) => setState(() {
                                            _taxDeductible = v;
                                            _dirty = true;
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.txSplitLinesHeader(_lines.length),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          AfabButton(
                            label: l10n.txSplitAddLine,
                            icon: LucideIcons.plus,
                            variant: AfabButtonVariant.soft,
                            compact: true,
                            onPressed: _addLine,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      for (var i = 0; i < _lines.length; i++) ...[
                        _SplitLineCard(
                          key: ValueKey(_lines[i].localId),
                          index: i,
                          draft: _lines[i],
                          categories: matchingCats,
                          canRemove: _lines.length > 2,
                          showFill: _remainingDecimal > Decimal.zero,
                          onCategoryChanged: (catId) => setState(() {
                            _lines[i].categoryId = catId;
                            _dirty = true;
                          }),
                          onAmountChanged: () => setState(() {
                            _dirty = true;
                          }),
                          onFill: () => _fillLine(i),
                          onRemove: () => _removeLine(i),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${l10n.txSplitAllocated}: ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              MoneyText(
                                amount: _allocatedDecimal,
                                currency: _currency,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          _isBalanced
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.circleCheck,
                                      size: 16,
                                      color: colors.success,
                                    ),
                                    const SizedBox(width: 6),
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        l10n.txSplitBalanced(
                                          zeroBalancedFormatted,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(color: colors.success),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${l10n.txSplitRemaining}: ',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    MoneyText(
                                      amount: _remainingDecimal,
                                      currency: _currency,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: colors.danger),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: AfabButton(
                              label: l10n.commonCancel,
                              variant: AfabButtonVariant.secondary,
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: AfabButton(
                              label: l10n.txSplitConfirmBtn,
                              isLoading: _submitting,
                              onPressed: _isBalanced && !_submitting
                                  ? _submit
                                  : null,
                            ),
                          ),
                        ],
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

class _SplitLineCard extends StatelessWidget {
  const _SplitLineCard({
    super.key,
    required this.index,
    required this.draft,
    required this.categories,
    required this.canRemove,
    required this.showFill,
    required this.onCategoryChanged,
    required this.onAmountChanged,
    required this.onFill,
    required this.onRemove,
  });

  final int index;
  final _SplitLineDraft draft;
  final List<CategoryDto> categories;
  final bool canRemove;
  final bool showFill;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onAmountChanged;
  final VoidCallback onFill;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final validCatId = categories.any((c) => c.id == draft.categoryId)
        ? draft.categoryId
        : null;

    return AfabCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: colors.primary.withValues(alpha: 0.14),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: validCatId,
                  isExpanded: true,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem<String?>(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: ColorParser.parseHex(
                                  c.color,
                                  colors.primary,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: l10n.commonDelete,
                onPressed: onRemove,
                icon: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: canRemove ? colors.danger : colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: draft.memoCtrl,
                  maxLength: 255,
                  decoration: InputDecoration(
                    hintText: l10n.txSplitLineMemoHint,
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: draft.amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      isDense: true,
                    ),
                    onChanged: (_) => onAmountChanged(),
                  ),
                ),
              ),
              if (showFill) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onFill,
                  style: TextButton.styleFrom(
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  child: Text(l10n.txSplitFillRemaining),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
