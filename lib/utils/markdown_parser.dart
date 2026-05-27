import 'package:flutter/material.dart';

/// Extract [[wiki-link]] titles from markdown content.
/// Handles edge cases: empty brackets, whitespace-only, escaped brackets,
/// nested brackets, trimming. Returns titles in order (caller dedupes if needed).
List<String> extractWikiLinks(String content) {
  final pattern = RegExp(r'(?<!\\)\[\[(.+?)\]\]');
  final matches = pattern.allMatches(content);
  final titles = <String>[];

  for (final match in matches) {
    final title = match.group(1)!.trim();
    if (title.isNotEmpty) {
      titles.add(title);
    }
  }

  return titles;
}

/// Extract #hashtag patterns from text content.
List<String> extractTags(String content) {
  final pattern = RegExp(r'#[a-zA-Z0-9_-]+');
  final matches = pattern.allMatches(content);
  return matches.map((m) => m.group(0)!).toList();
}

/// Fallback color scheme used when none is provided (e.g., in tests).
ColorScheme _defaultColorScheme() => ColorScheme.fromSeed(
      seedColor: const Color(0xFF546E7A),
      brightness: Brightness.light,
    ).copyWith(
      secondary: const Color(0xFF1976D2),
      tertiary: const Color(0xFF00E676),
    );

/// Parse markdown content and return styled text spans.
/// Handles: H1-H3 headings, ordered/unordered lists, bold, italic, code blocks,
/// wiki-links, tags.
List<TextSpan> parseMarkdown(String input, {ColorScheme? colorScheme}) {
  final scheme = colorScheme ?? _defaultColorScheme();
  final lines = input.split('\n');
  final List<TextSpanResult> results = [];

  bool inCodeBlock = false;
  final codeLines = <String>[];

  for (final line in lines) {
    // Code block fence: ```
    if (line.trim().startsWith('```')) {
      if (inCodeBlock) {
        // Close code block
        if (codeLines.isNotEmpty) {
          results.add(TextSpanResult(
            type: SpanType.code,
            data: codeLines.join('\n'),
          ));
          codeLines.clear();
        }
        inCodeBlock = false;
      } else {
        inCodeBlock = true;
      }
      continue;
    }

    if (inCodeBlock) {
      codeLines.add(line);
      continue;
    }

    if (line.trim().isEmpty) continue;

    var headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
    if (headingMatch != null) {
      final level = headingMatch.group(1)!.length;
      final text = headingMatch.group(2)!;
      results.add(TextSpanResult(
        type: SpanType.headings,
        subType: HeadingLevel(level),
        data: text,
      ));
      continue;
    }

    var orderedListMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(line);
    if (orderedListMatch != null) {
      results.add(TextSpanResult(
        type: SpanType.lists,
        subType: ListType.ordered,
        data: orderedListMatch.group(2)!,
      ));
      continue;
    }

    var unorderedListMatch = RegExp(r'^[-*+]\s+(.+)$').firstMatch(line);
    if (unorderedListMatch != null) {
      results.add(TextSpanResult(
        type: SpanType.lists,
        subType: ListType.unordered,
        data: unorderedListMatch.group(1)!,
      ));
      continue;
    }

    results.addAll(_parseTextLine(line));
  }

  return [
    TextSpan(children: results.map((r) => _buildSpan(r, scheme)).toList())
  ];
}

TextSpan _buildSpan(TextSpanResult result, ColorScheme scheme) {
  switch (result.type) {
    case SpanType.headings:
      final level = result.subType as HeadingLevel;
      return _renderHeading(level, result.data, scheme);

    case SpanType.lists:
      return TextSpan(
        text: '\u2022 ${result.data.trim()}\n',
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.54),
          fontSize: 16,
        ),
      );

    case SpanType.bold:
      return TextSpan(
        text: result.data,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
          fontSize: 16,
        ),
      );

    case SpanType.italic:
      return TextSpan(
        text: result.data,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: scheme.onSurface,
          fontSize: 16,
        ),
      );

    case SpanType.code:
      return TextSpan(
        text: '${result.data}\n',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: scheme.onSurface,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
      );

    case SpanType.text:
      return TextSpan(
        text: '${result.data}\n',
        style: TextStyle(color: scheme.onSurface, fontSize: 16),
      );

    case SpanType.wikiLink:
      return TextSpan(
        text: result.data,
        style: TextStyle(
          color: scheme.secondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: scheme.secondary,
        ),
      );

    case SpanType.tag:
      return TextSpan(
        text: result.data,
        style: TextStyle(
          color: scheme.tertiary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      );
  }
  return TextSpan(text: result.data);
}

/// Split a text line into inline segments for wiki-links, #tags, bold, italic.
List<TextSpanResult> _parseTextLine(String line) {
  final results = <TextSpanResult>[];
  // Combined pattern: **bold**, *italic*, [[wiki-link]], or #tag
  final pattern = RegExp(
    r'\*\*(.+?)\*\*' // bold
    r'|\*(.+?)\*' // italic
    r'|(?<!\\)\[\[(.+?)\]\]' // wiki-link
    r'|#[a-zA-Z0-9_-]+' // tag
  );
  int lastEnd = 0;

  for (final match in pattern.allMatches(line)) {
    // Text before match
    if (match.start > lastEnd) {
      final before = line.substring(lastEnd, match.start);
      if (before.isNotEmpty) {
        results.add(TextSpanResult(type: SpanType.text, data: before));
      }
    }

    final matched = match.group(0)!;

    if (matched.startsWith('**') && matched.endsWith('**')) {
      // Bold
      final text = match.group(1) ?? '';
      if (text.isNotEmpty) {
        results.add(TextSpanResult(type: SpanType.bold, data: text));
      }
    } else if (matched.startsWith('*') && matched.endsWith('*')) {
      // Italic (single asterisk, not bold which is double)
      final text = match.group(2) ?? '';
      if (text.isNotEmpty) {
        results.add(TextSpanResult(type: SpanType.italic, data: text));
      }
    } else if (matched.startsWith('[[')) {
      // Wiki-link: extract inner title
      final title = match.group(3)?.trim() ?? '';
      if (title.isNotEmpty) {
        results.add(TextSpanResult(type: SpanType.wikiLink, data: title));
      }
    } else {
      // Tag
      results.add(TextSpanResult(type: SpanType.tag, data: matched));
    }

    lastEnd = match.end;
  }

  // Remaining text
  if (lastEnd < line.length) {
    results.add(TextSpanResult(
      type: SpanType.text,
      data: line.substring(lastEnd),
    ));
  }

  return results;
}

TextSpan _renderHeading(
    HeadingLevel level, String text, ColorScheme scheme) {
  switch (level.level) {
    case 1:
      return TextSpan(
        text: '$text\n',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 28,
          color: scheme.primary,
        ),
      );
    case 2:
      return TextSpan(
        text: '$text\n',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 22,
          color: scheme.primary,
        ),
      );
    case 3:
      return TextSpan(
        text: '$text\n',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: scheme.primary,
        ),
      );
    default:
      return TextSpan(text: '$text\n', style: const TextStyle(fontSize: 16));
  }
}

/// Build inline spans for preview, rendering [[wiki-links]] as tappable
/// widgets and formatting markdown. Accepts an optional [onLinkTap] callback
/// for navigation.
List<InlineSpan> buildPreviewSpans(
  String content, {
  void Function(String title)? onLinkTap,
  ColorScheme? colorScheme,
}) {
  final scheme = colorScheme ?? _defaultColorScheme();
  final lines = content.split('\n');
  final spans = <InlineSpan>[];

  bool inCodeBlock = false;
  final codeLines = <String>[];

  for (final line in lines) {
    // Code block fence
    if (line.trim().startsWith('```')) {
      if (inCodeBlock) {
        if (codeLines.isNotEmpty) {
          spans.add(TextSpan(
            text: '${codeLines.join('\n')}\n',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: scheme.onSurface,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ));
          codeLines.clear();
        }
        inCodeBlock = false;
      } else {
        inCodeBlock = true;
      }
      continue;
    }

    if (inCodeBlock) {
      codeLines.add(line);
      continue;
    }

    if (line.trim().isEmpty) continue;

    // H1, H2, H3 headings
    var headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
    if (headingMatch != null) {
      final level = headingMatch.group(1)!.length;
      final text = headingMatch.group(2)!;
      spans.add(_renderHeading(HeadingLevel(level), text, scheme));
      continue;
    }

    // Ordered list
    var orderedMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(line);
    if (orderedMatch != null) {
      spans.add(TextSpan(
        text: '${orderedMatch.group(1)!}. ${orderedMatch.group(2)!}\n',
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.54),
          fontSize: 16,
        ),
      ));
      continue;
    }

    // Unordered list
    var unorderedMatch = RegExp(r'^[-*+]\s+(.+)$').firstMatch(line);
    if (unorderedMatch != null) {
      spans.add(TextSpan(
        text: '\u2022 ${unorderedMatch.group(1)!}\n',
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.54),
          fontSize: 16,
        ),
      ));
      continue;
    }

    // Regular text — detect inline formatting and [[wiki-links]]
    spans.addAll(
        _parsePreviewLine(line, onLinkTap: onLinkTap, colorScheme: scheme));
  }

  return spans;
}

/// Parse a single text line for preview, splitting at inline formatting
/// markers: **bold**, *italic*, [[wiki-link]], #tag.
List<InlineSpan> _parsePreviewLine(
  String line, {
  void Function(String title)? onLinkTap,
  required ColorScheme colorScheme,
}) {
  final scheme = colorScheme;
  final spans = <InlineSpan>[];
  final pattern = RegExp(
    r'\*\*(.+?)\*\*' // bold
    r'|\*(.+?)\*' // italic
    r'|(?<!\\)\[\[(.+?)\]\]' // wiki-link
    r'|#[a-zA-Z0-9_-]+' // tag
  );
  int lastEnd = 0;

  for (final match in pattern.allMatches(line)) {
    // Text before match
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: line.substring(lastEnd, match.start),
        style: TextStyle(color: scheme.onSurface, fontSize: 16),
      ));
    }

    final matched = match.group(0)!;

    if (matched.startsWith('**') && matched.endsWith('**')) {
      // Bold
      final text = match.group(1) ?? '';
      if (text.isNotEmpty) {
        spans.add(TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
            fontSize: 16,
          ),
        ));
      }
    } else if (matched.startsWith('*') && matched.endsWith('*')) {
      // Italic
      final text = match.group(2) ?? '';
      if (text.isNotEmpty) {
        spans.add(TextSpan(
          text: text,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: scheme.onSurface,
            fontSize: 16,
          ),
        ));
      }
    } else if (matched.startsWith('[[')) {
      // Wiki-link
      final title = match.group(3)!.trim();
      if (title.isNotEmpty) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: onLinkTap != null ? () => onLinkTap(title) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: scheme.secondary.withValues(alpha: 0.3)),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: scheme.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: scheme.secondary,
                ),
              ),
            ),
          ),
        ));
      }
    } else {
      // Tag
      spans.add(TextSpan(
        text: matched,
        style: TextStyle(
          color: scheme.tertiary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ));
    }

    lastEnd = match.end;
  }

  // Remaining text after last match, plus trailing newline
  final trailing = lastEnd < line.length ? line.substring(lastEnd) : '';
  spans.add(TextSpan(
    text: '$trailing\n',
    style: TextStyle(color: scheme.onSurface, fontSize: 16),
  ));

  return spans;
}

/// Result of parsing a line (type, subtype, text)
class TextSpanResult {
  final SpanType type;
  final dynamic subType;
  final String data;

  const TextSpanResult({
    required this.type,
    this.subType,
    required this.data,
  });
}

/// Type of span (headings, lists, text, wikiLink, tag, bold, italic, code)
class SpanType {
  static const headings = SpanType._('headings');
  static const lists = SpanType._('lists');
  static const text = SpanType._('text');
  static const wikiLink = SpanType._('wikiLink');
  static const tag = SpanType._('tag');
  static const bold = SpanType._('bold');
  static const italic = SpanType._('italic');
  static const code = SpanType._('code');

  final String _name;
  const SpanType._(this._name);

  @override
  String toString() => _name;
}

/// Heading level (1, 2, or 3)
class HeadingLevel {
  final int level;
  const HeadingLevel(this.level);
}

/// List type
class ListType {
  static const ordered = 'ordered';
  static const unordered = 'unordered';
}
