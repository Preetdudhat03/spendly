import 'package:flutter/material.dart';

/// Lightweight and crash-safe formatter for GitHub release notes.
class ReleaseNotesView extends StatelessWidget {
  final String rawNotes;
  final int maxLines;

  const ReleaseNotesView({
    super.key,
    required this.rawNotes,
    this.maxLines = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (rawNotes.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Performance improvements, bug fixes, and stability updates.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white70 : Colors.black87,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final lines = rawNotes
        .split('\n')
        .where((l) => !l.trim().startsWith('<!--') && !l.trim().endsWith('-->'))
        .toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.map((line) => _buildFormattedLine(context, line)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedLine(BuildContext context, String line) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trimmed = line.trim();

    if (trimmed.isEmpty) {
      return const SizedBox(height: 6);
    }

    // Headings: #, ##, ###
    if (trimmed.startsWith('#')) {
      final headingText = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          headingText,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    // Bullet points: - , * , +
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('+ ')) {
      final bulletText = trimmed.substring(2);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: _buildRichText(context, bulletText),
            ),
          ],
        ),
      );
    }

    // Regular line
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: _buildRichText(context, trimmed),
    );
  }

  Widget _buildRichText(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
      height: 1.35,
      fontSize: 13,
    );

    // Simple parser for **bold** and `code`
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*.*?\*\*|`.*?`)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultStyle,
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length >= 4) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: defaultStyle?.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`') && matchedText.length >= 2) {
        spans.add(TextSpan(
          text: matchedText.substring(1, matchedText.length - 1),
          style: defaultStyle?.copyWith(
            fontFamily: 'monospace',
            backgroundColor: isDark ? Colors.white12 : Colors.black12,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans.isEmpty ? [TextSpan(text: text, style: defaultStyle)] : spans),
    );
  }
}
