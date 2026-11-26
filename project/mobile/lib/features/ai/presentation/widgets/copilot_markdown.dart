import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pure-Dart Markdown renderer matching `CopilotMarkdown.tsx` blocks:
/// headings (`#..###`), bold/italic/inline code, LTR fenced code blocks with Copy,
/// horizontal-scroll tables, blockquotes, rules, bullet & ordered lists.
class CopilotMarkdown extends StatelessWidget {
  const CopilotMarkdown({
    super.key,
    required this.content,
    this.isStreaming = false,
  });

  final String content;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(content);
    if (blocks.isEmpty) {
      if (!isStreaming) return const SizedBox.shrink();
      return const _StreamingCursor();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          _buildBlock(
            context,
            blocks[i],
            appendCursor: isStreaming && i == blocks.length - 1,
          ),
          if (i < blocks.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildBlock(
    BuildContext context,
    _MdBlock block, {
    required bool appendCursor,
  }) {
    final colors = context.afabColors;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15.5,
          height: 1.6,
          color: colors.textPrimary,
        );

    switch (block) {
      case _CodeBlock():
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FencedCodeCard(language: block.language, code: block.code),
            if (appendCursor) const _StreamingCursor(),
          ],
        );
      case _HrBlock():
        return Divider(height: 16, color: colors.border);
      case _HeadingBlock():
        final style = switch (block.level) {
          1 => Theme.of(context).textTheme.titleLarge,
          2 => Theme.of(context).textTheme.titleMedium,
          _ => Theme.of(context).textTheme.titleSmall,
        };
        return Text.rich(
          TextSpan(
            children: [
              ..._buildInlineSpans(block.text, style ?? bodyStyle!, colors),
              if (appendCursor) const WidgetSpan(child: _StreamingCursor()),
            ],
          ),
        );
      case _QuoteBlock():
        return Container(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: colors.surfaceInset,
            border: BorderDirectional(
              start: BorderSide(color: colors.primary, width: 3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                ..._buildInlineSpans(
                  block.lines.join('\n'),
                  bodyStyle!.copyWith(
                    color: colors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                  colors,
                ),
                if (appendCursor) const WidgetSpan(child: _StreamingCursor()),
              ],
            ),
          ),
        );
      case _TableBlock():
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.symmetric(
                inside: BorderSide(color: colors.border),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colors.surfaceInset),
                  children: [
                    for (final h in block.headers)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Text(
                          h,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                for (final row in block.rows)
                  TableRow(
                    children: [
                      for (var c = 0; c < block.headers.length; c++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Text.rich(
                            TextSpan(
                              children: _buildInlineSpans(
                                c < row.length ? row[c] : '',
                                Theme.of(context).textTheme.bodySmall!,
                                colors,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      case _ListBlock():
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var idx = 0; idx < block.items.length; idx++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          block.ordered ? '${idx + 1}.' : '•',
                          style: bodyStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            ..._buildInlineSpans(
                              block.items[idx],
                              bodyStyle!,
                              colors,
                            ),
                            if (appendCursor && idx == block.items.length - 1)
                              const WidgetSpan(child: _StreamingCursor()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case _ParagraphBlock():
        return Text.rich(
          TextSpan(
            children: [
              ..._buildInlineSpans(block.text, bodyStyle!, colors),
              if (appendCursor) const WidgetSpan(child: _StreamingCursor()),
            ],
          ),
        );
    }
  }

  List<InlineSpan> _buildInlineSpans(
    String text,
    TextStyle baseStyle,
    AfabColors colors,
  ) {
    final regex = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)');
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: baseStyle));
      }
      final tok = m.group(0)!;
      if (tok.startsWith('**') && tok.endsWith('**')) {
        spans.add(
          TextSpan(
            text: tok.substring(2, tok.length - 2),
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (tok.startsWith('`') && tok.endsWith('`')) {
        spans.add(
          TextSpan(
            text: ' ${tok.substring(1, tok.length - 1)} ',
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: (baseStyle.fontSize ?? 14) - 1.5,
              color: colors.primary,
              backgroundColor: colors.primary.withValues(alpha: 0.1),
            ),
          ),
        );
      } else if (tok.startsWith('*') && tok.endsWith('*')) {
        spans.add(
          TextSpan(
            text: tok.substring(1, tok.length - 1),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: baseStyle));
    }
    return spans;
  }

  List<_MdBlock> _parseBlocks(String raw) {
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_MdBlock>[];
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      if (trimmed.startsWith('```')) {
        final lang = trimmed.substring(3).trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        if (i < lines.length) i++;
        blocks.add(_CodeBlock(language: lang, code: codeLines.join('\n')));
        continue;
      }

      if (RegExp(r'^(-{3,}|\*{3,})$').hasMatch(trimmed)) {
        blocks.add(const _HrBlock());
        i++;
        continue;
      }

      final heading = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
      if (heading != null) {
        blocks.add(
          _HeadingBlock(
            level: heading.group(1)!.length,
            text: heading.group(2)!,
          ),
        );
        i++;
        continue;
      }

      if (trimmed.startsWith('>')) {
        final quotes = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('>')) {
          quotes.add(lines[i].trim().replaceFirst(RegExp(r'^>\s?'), ''));
          i++;
        }
        blocks.add(_QuoteBlock(lines: quotes));
        continue;
      }

      if (trimmed.contains('|') &&
          i + 1 < lines.length &&
          _isTableSep(lines[i + 1])) {
        final headers = _splitRow(trimmed);
        i += 2;
        final rows = <List<String>>[];
        while (i < lines.length &&
            lines[i].trim().contains('|') &&
            !lines[i].trim().startsWith('```')) {
          rows.add(_splitRow(lines[i]));
          i++;
        }
        blocks.add(_TableBlock(headers: headers, rows: rows));
        continue;
      }

      if (RegExp(r'^[-*•]\s+').hasMatch(trimmed)) {
        final items = <String>[];
        while (i < lines.length &&
            RegExp(r'^[-*•]\s+').hasMatch(lines[i].trim())) {
          items.add(lines[i].trim().replaceFirst(RegExp(r'^[-*•]\s+'), ''));
          i++;
        }
        blocks.add(_ListBlock(items: items, ordered: false));
        continue;
      }

      if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        final items = <String>[];
        while (i < lines.length &&
            RegExp(r'^\d+\.\s+').hasMatch(lines[i].trim())) {
          items.add(lines[i].trim().replaceFirst(RegExp(r'^\d+\.\s+'), ''));
          i++;
        }
        blocks.add(_ListBlock(items: items, ordered: true));
        continue;
      }

      final para = <String>[trimmed];
      i++;
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !RegExp(r'^(#{1,3}\s+|[-*•]\s+|\d+\.\s+|```|>\s?|(-{3,}|\*{3,})$)')
              .hasMatch(lines[i].trim()) &&
          !(lines[i].trim().contains('|') &&
              i + 1 < lines.length &&
              _isTableSep(lines[i + 1]))) {
        para.add(lines[i].trim());
        i++;
      }
      blocks.add(_ParagraphBlock(text: para.join(' ')));
    }

    return blocks;
  }

  List<String> _splitRow(String line) {
    final clean = line.trim().replaceFirst(RegExp(r'^\|'), '').replaceFirst(
          RegExp(r'\|$'),
          '',
        );
    return clean.split('|').map((c) => c.trim()).toList();
  }

  bool _isTableSep(String line) {
    final trimmed = line.trim();
    if (!trimmed.contains('|') || !trimmed.contains('-')) return false;
    final cells = _splitRow(trimmed);
    return cells.isNotEmpty &&
        cells.every((c) => RegExp(r'^:?-{2,}:?$').hasMatch(c));
  }
}

sealed class _MdBlock {
  const _MdBlock();
}

final class _CodeBlock extends _MdBlock {
  const _CodeBlock({required this.language, required this.code});
  final String language;
  final String code;
}

final class _HrBlock extends _MdBlock {
  const _HrBlock();
}

final class _HeadingBlock extends _MdBlock {
  const _HeadingBlock({required this.level, required this.text});
  final int level;
  final String text;
}

final class _QuoteBlock extends _MdBlock {
  const _QuoteBlock({required this.lines});
  final List<String> lines;
}

final class _TableBlock extends _MdBlock {
  const _TableBlock({required this.headers, required this.rows});
  final List<String> headers;
  final List<List<String>> rows;
}

final class _ListBlock extends _MdBlock {
  const _ListBlock({required this.items, required this.ordered});
  final List<String> items;
  final bool ordered;
}

final class _ParagraphBlock extends _MdBlock {
  const _ParagraphBlock({required this.text});
  final String text;
}

class _FencedCodeCard extends StatelessWidget {
  const _FencedCodeCard({required this.language, required this.code});
  final String language;
  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (language.isEmpty ? 'code' : language).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) {
                        AfabToast.showSuccess(context, l10n.aiCopied);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.copy,
                            size: 12,
                            color: Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.aiCopy,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                code,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamingCursor extends StatelessWidget {
  const _StreamingCursor();

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Container(
      width: 7,
      height: 14,
      margin: const EdgeInsetsDirectional.only(start: 3),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
