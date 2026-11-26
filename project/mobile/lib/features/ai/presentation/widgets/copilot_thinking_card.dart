import 'dart:async';

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_markdown.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

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
  int _elapsedTenths = 0;
  bool _traceExpanded = true;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) {
        setState(() => _elapsedTenths += 2);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  String _headline(BuildContext context) {
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
    final phaseIdx = (_elapsedTenths ~/ 18) % 3;
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
    final elapsedStr = (_elapsedTenths / 10).toStringAsFixed(1);
    final isLiveStreaming = widget.streamingText.isNotEmpty;

    return AfabCard(
      borderColor: colors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isLiveStreaming ? colors.success : colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLiveStreaming ? l10n.aiStreamingLabel : _headline(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.primary,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceInset,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    l10n.aiElapsedSeconds(elapsedStr),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
              ),
            ],
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
                      borderRadius: BorderRadius.circular(8),
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
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
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
          if (widget.thinkingText.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _traceExpanded = !_traceExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(LucideIcons.brain, size: 14, color: colors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      l10n.aiReasoningTrace,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const Spacer(),
                    Icon(
                      _traceExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 15,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_traceExpanded)
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
          const SizedBox(height: 10),
          if (isLiveStreaming)
            Directionality(
              textDirection: MessageDirectionResolver.resolveForMessage(
                widget.streamingText,
              ),
              child: CopilotMarkdown(
                content: widget.streamingText,
                isStreaming: true,
              ),
            )
          else
            _SkeletonShimmerLines(reduceMotion: reduceMotion),
        ],
      ),
    );
  }
}

class _SkeletonShimmerLines extends StatelessWidget {
  const _SkeletonShimmerLines({required this.reduceMotion});
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final bars = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(colors, widthFactor: 0.92),
        const SizedBox(height: 8),
        _bar(colors, widthFactor: 0.78),
        const SizedBox(height: 8),
        _bar(colors, widthFactor: 0.56),
      ],
    );
    if (reduceMotion) return bars;
    return Shimmer.fromColors(
      baseColor: colors.border,
      highlightColor: colors.surface,
      child: bars,
    );
  }

  Widget _bar(AfabColors colors, {required double widthFactor}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 11,
        decoration: BoxDecoration(
          color: colors.surfaceInset,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
