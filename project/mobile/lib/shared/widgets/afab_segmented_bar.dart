import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AfabSegmentItem<T> {
  const AfabSegmentItem({required this.value, required this.label});

  final T value;
  final String label;
}

class AfabSegmentedBar<T> extends ConsumerWidget {
  const AfabSegmentedBar({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<AfabSegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.afabColors;
    final appearance = ref.watch(appearanceNotifierProvider);
    final outerRadius = BorderRadius.circular(appearance.radius.baseRadius);
    final innerRadius = BorderRadius.circular(
      (appearance.radius.baseRadius - 3).clamp(4, 14),
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: outerRadius,
        border: Border.all(color: colors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 2),
                child: Material(
                  color: item.value == selectedValue
                      ? colors.primary
                      : Colors.transparent,
                  borderRadius: innerRadius,
                  child: InkWell(
                    borderRadius: innerRadius,
                    onTap: () => onSelected(item.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: item.value == selectedValue
                                  ? Colors.white
                                  : colors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
