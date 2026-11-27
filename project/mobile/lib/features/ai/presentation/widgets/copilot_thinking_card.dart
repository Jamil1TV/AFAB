import 'dart:async';

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_markdown.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CopilotThinkingCard extends StatefulWidget {
  const CopilotThinkingCard({
    super.key,
    required this.streamPhase,
    required this.streamingText,
    required this.thinkingText,
    required this.activeTools,
    required this.completedTools,
  });

  final String streamPhase;
  final String streamingText;
  final String thinkingText;
  final List<String> activeTools;
  final List<({String tool, int evidenceCount})> completedTools;

  @override
  State<CopilotThinkingCard> createState() => _CopilotThinkingCardState();
}

class _CopilotThinkingCardState extends State<CopilotThinkingCard> {
  Timer? _ticker;
  final ValueNotifier<int> _elapsedTenths = ValueNotifier<int>(0);
  bool _traceExpanded = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) {
        _elapsedTenths.value += 2;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    _elapsedTenths.dispose();
    super.dispose();
  }

  String _headline(BuildContext context, int elapsedTenths) {
    final l10n = context.l10n;
    if (widget.activeTools.isNotEmpty) {
      return '${localizedToolLabel(l10n, widget.activeTools.last)}...';
    }
    if (widget.thinkingText.isNotEmpty) {
      return l10n.aiDeepThinkingLive;
    }
    if (widget.streamPhase == 'warming_model') {
      return l10n.aiPhaseWarmingModel;
    }
    final phaseIdx = (elapsedTenths ~/ 18) % 3;
    return switch (phaseIdx) {
      0 => l10n.aiPhaseMemory,
      1 => l10n.aiPhaseLedger,
      _ => l10n.aiPhaseSynthesis,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isLiveStreaming = widget.streamingText.isNotEmpty;
    final hasThinkingTrace = widget.thinkingText.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: hasThinkingTrace
                ? () => setState(() => _traceExpanded = !_traceExpanded)
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ValueListenableBuilder<int>(
                valueListenable: _elapsedTenths,
                builder: (context, elapsedTenths, _) {
                  final elapsedStr = (elapsedTenths / 10).toStringAsFixed(1);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _AuroraConstellationDots(
                        tick: elapsedTenths,
                        activeColor:
                            isLiveStreaming ? colors.success : colors.primary,
                        reduceMotion: reduceMotion,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isLiveStreaming
                              ? l10n.aiStreamingLabel
                              : _headline(context, elapsedTenths),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                    color: colors.textPrimary
                                        .withValues(alpha: 0.92),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          l10n.aiElapsedSeconds(elapsedStr),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 11.5,
                                    color: colors.textMuted,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                        ),
                      ),
                      if (hasThinkingTrace) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _traceExpanded
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 15,
                          color: colors.textMuted,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          if (widget.completedTools.isNotEmpty ||
              widget.activeTools.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final done in widget.completedTools)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.successBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.circleCheck,
                          size: 12,
                          color: colors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${localizedToolLabel(l10n, done.tool)} (${done.evidenceCount})',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colors.success),
                        ),
                      ],
                    ),
                  ),
                for (final active in widget.activeTools)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          localizedToolLabel(l10n, active),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: colors.primary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (hasThinkingTrace && _traceExpanded) ...[
            const SizedBox(height: 8),
            AfabInsetPanel(
              padding: const EdgeInsets.all(10),
              child: Text(
                widget.thinkingText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.45,
                    ),
              ),
            ),
          ],
          if (isLiveStreaming) ...[
            const SizedBox(height: 10),
            Directionality(
              textDirection: MessageDirectionResolver.resolveForMessage(
                widget.streamingText,
              ),
              child: CopilotMarkdown(
                content: widget.streamingText,
                isStreaming: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuroraConstellationDots extends StatelessWidget {
  const _AuroraConstellationDots({
    required this.tick,
    required this.activeColor,
    required this.reduceMotion,
  });

  final int tick;
  final Color activeColor;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final step = reduceMotion ? 0 : (tick ~/ 2) % 3;

    Color dotColor(int idx) {
      final alpha = step == idx ? 1.0 : 0.34;
      return activeColor.withValues(alpha: alpha);
    }

    Widget dot(int idx) => AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: dotColor(idx),
            shape: BoxShape.circle,
          ),
        );

    return SizedBox(
      width: 14,
      height: 12,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [dot(0), dot(1)],
          ),
          const SizedBox(height: 3),
          dot(2),
        ],
      ),
    );
  }
}
