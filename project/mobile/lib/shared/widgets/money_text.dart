import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Displays formatted financial amounts with:
/// - `Decimal` exactness & ISO-4217 3-decimal support (`TND`, `KWD`, `BHD`, `OMR`).
/// - Western digits (`0-9`) and forced LTR isolation in RTL Arabic layouts.
/// - `FontFeature.tabularFigures()` and `FittedBox(scaleDown)` so amounts never clip.
class MoneyText extends ConsumerWidget {
  const MoneyText({
    super.key,
    required this.amount,
    required this.currency,
    this.style,
    this.showSign = false,
    this.compact = false,
    this.alignment = AlignmentDirectional.centerStart,
  });

  final Decimal amount;
  final String currency;
  final TextStyle? style;
  final bool showSign;
  final bool compact;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numberFormat = ref.watch(prefsStoreProvider).getNumberFormat();
    final formatted = compact
        ? MoneyFormatter.formatCompact(
            amount,
            currency: currency,
            numberFormat: numberFormat,
          )
        : MoneyFormatter.formatDecimal(
            amount,
            currency: currency,
            numberFormat: numberFormat,
            showSign: showSign,
          );

    final baseStyle = (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          formatted,
          maxLines: 1,
          style: baseStyle,
        ),
      ),
    );
  }
}
