import 'package:flutter/material.dart';

import 'package:graphite/core/design/colors.dart';
import 'package:graphite/core/design/spacing.dart';
import 'package:graphite/core/design/typography.dart';

/// A markdown controller that keeps raw markdown text editable while painting
/// common markdown syntax with live-preview styling.
class InlineMarkdownEditingController extends TextEditingController {
  InlineMarkdownEditingController({super.text});

  bool _livePreview = true;

  bool get livePreview => _livePreview;

  set livePreview(bool value) {
    if (_livePreview == value) return;
    _livePreview = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!_livePreview) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final baseStyle = style ?? GraphiteTypography.mono;
    final tokenStyle = baseStyle.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.45),
    );
    final strongStyle = baseStyle.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );
    final emphasisStyle = baseStyle.copyWith(
      color: colorScheme.onSurface,
      fontStyle: FontStyle.italic,
    );
    final listMarkerStyle = baseStyle.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final linkStyle = baseStyle.copyWith(
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: colorScheme.primary.withValues(alpha: 0.55),
    );
    final tagStyle = baseStyle.copyWith(
      color: GraphiteColors.moss,
      fontWeight: FontWeight.w600,
    );
    final headingStyles = List<TextStyle>.generate(
      6,
      (index) => _markdownHeadingStyle(colorScheme.onSurface, index + 1),
    );

    final children = <InlineSpan>[];
    final source = text;
    final lines = source.split('\n');

    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        children.add(TextSpan(text: '\n', style: baseStyle));
      }
      _appendDecoratedLine(
        children,
        lines[i],
        baseStyle,
        tokenStyle,
        strongStyle,
        emphasisStyle,
        headingStyles,
        listMarkerStyle,
        linkStyle,
        tagStyle,
      );
    }

    return TextSpan(style: baseStyle, children: children);
  }

  static void _appendDecoratedLine(
    List<InlineSpan> children,
    String line,
    TextStyle baseStyle,
    TextStyle tokenStyle,
    TextStyle strongStyle,
    TextStyle emphasisStyle,
    List<TextStyle> headingStyles,
    TextStyle listMarkerStyle,
    TextStyle linkStyle,
    TextStyle tagStyle,
  ) {
    if (line.isEmpty) return;

    final headingMatch = RegExp(r'^(#{1,6})(\s+)').firstMatch(line);
    var start = 0;
    TextStyle lineBaseStyle = baseStyle;

    if (headingMatch != null) {
      children.add(TextSpan(text: headingMatch[1], style: tokenStyle));
      children.add(TextSpan(text: headingMatch[2], style: baseStyle));
      start = headingMatch.end;
      lineBaseStyle = headingStyles[headingMatch[1]!.length - 1];
    } else {
      final listMatch = RegExp(r'^(\s*)([-*+]|\d+\.)(\s+)').firstMatch(line);
      if (listMatch != null) {
        children.add(TextSpan(text: listMatch[1], style: baseStyle));
        children.add(TextSpan(text: listMatch[2], style: listMarkerStyle));
        children.add(TextSpan(text: listMatch[3], style: baseStyle));
        start = listMatch.end;
      }
    }

    _appendInlineSpans(
      children,
      line.substring(start),
      lineBaseStyle,
      tokenStyle,
      strongStyle,
      emphasisStyle,
      linkStyle,
      tagStyle,
    );
  }

  static void _appendInlineSpans(
    List<InlineSpan> children,
    String text,
    TextStyle baseStyle,
    TextStyle tokenStyle,
    TextStyle strongStyle,
    TextStyle emphasisStyle,
    TextStyle linkStyle,
    TextStyle tagStyle,
  ) {
    final pattern = RegExp(
      r'(\[\[[^\]\n]+\]\])|(\*\*[^*\n]+?\*\*)|(?<!\*)\*[^*\n]+?\*(?!\*)|(?<!\w)#[a-zA-Z0-9_-]+',
    );
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        children.add(
          TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
        );
      }

      final token = match[0]!;
      if (token.startsWith('[[')) {
        children.add(TextSpan(text: '[[', style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: linkStyle,
          ),
        );
        children.add(TextSpan(text: ']]', style: tokenStyle));
      } else if (token.startsWith('**')) {
        children.add(TextSpan(text: '**', style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: strongStyle,
          ),
        );
        children.add(TextSpan(text: '**', style: tokenStyle));
      } else if (token.startsWith('*')) {
        children.add(TextSpan(text: '*', style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: emphasisStyle,
          ),
        );
        children.add(TextSpan(text: '*', style: tokenStyle));
      } else {
        children.add(TextSpan(text: token, style: tagStyle));
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
  }

  static TextStyle _markdownHeadingStyle(Color color, int level) {
    final base = switch (level) {
      1 => GraphiteTypography.markdownH1,
      2 => GraphiteTypography.markdownH2,
      3 => GraphiteTypography.markdownH3,
      4 => GraphiteTypography.markdownH4,
      5 => GraphiteTypography.markdownH5,
      _ => GraphiteTypography.markdownH6,
    };
    return base.copyWith(color: color);
  }
}

/// A clean, distraction-free markdown editor pane.
/// Accepts a TextEditingController to bind content.
class EditorPane extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onWikiLinkTap;
  final bool showLineNumbers;

  const EditorPane({
    super.key,
    required this.controller,
    this.onChanged,
    this.onWikiLinkTap,
    this.showLineNumbers = true,
  });

  @override
  State<EditorPane> createState() => _EditorPaneState();
}

class _EditorPaneState extends State<EditorPane> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _wasFocusedOnTapDown = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _pushUndoState() {
    _undoStack.add(widget.controller.text);
    _redoStack.clear();
  }

  void _insertMarkup(String prefix, String suffix) {
    _pushUndoState();

    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isValid && selection.start != selection.end) {
      // Wrap selected text
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length,
        ),
      );
    } else {
      // Insert at cursor with cursor placed between prefix and suffix
      final cursorPos = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(cursorPos, cursorPos, '$prefix$suffix');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursorPos + prefix.length),
      );
    }

    widget.onChanged?.call(controller.text);
  }

  void _insertLinePrefix(String prefix) {
    _pushUndoState();

    final controller = widget.controller;
    final text = controller.text;
    final selection = controller.selection;
    final cursorPos = selection.isValid ? selection.start : text.length;

    // Find start of current line
    int lineStart = cursorPos;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }

    // Check if line already starts with prefix + space
    final prefixWithSpace = '$prefix ';
    final lineEnd = text.indexOf('\n', cursorPos);
    final currentLine = text.substring(
      lineStart,
      lineEnd == -1 ? text.length : lineEnd,
    );

    if (currentLine.startsWith(prefixWithSpace)) {
      // Toggle off: remove prefix and space
      final newText = text.replaceRange(
        lineStart,
        lineStart + prefixWithSpace.length,
        '',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: (cursorPos - prefixWithSpace.length).clamp(0, newText.length),
        ),
      );
    } else {
      final newText = text.replaceRange(lineStart, lineStart, prefixWithSpace);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: cursorPos + prefixWithSpace.length,
        ),
      );
    }

    widget.onChanged?.call(controller.text);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(widget.controller.text);
    final previous = _undoStack.removeLast();
    widget.controller.text = previous;
    widget.onChanged?.call(previous);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(widget.controller.text);
    final next = _redoStack.removeLast();
    widget.controller.text = next;
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        children: [
          if (widget.showLineNumbers) _buildFormattingToolbar(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (_) {
                    _wasFocusedOnTapDown = _focusNode.hasFocus;
                  },
                  onTapUp: (details) {
                    if (!_wasFocusedOnTapDown) {
                      _openWikiLinkAt(details.localPosition, constraints);
                    }
                  },
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    onChanged: widget.onChanged,
                    style: GraphiteTypography.mono.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: GraphiteSpacing.xl,
                        vertical: GraphiteSpacing.xl,
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  ),
                );
              },
            ),
          ),
          if (widget.showLineNumbers) _buildFooter(context),
        ],
      ),
    );
  }

  void _openWikiLinkAt(Offset localPosition, BoxConstraints constraints) {
    final onWikiLinkTap = widget.onWikiLinkTap;
    if (onWikiLinkTap == null) return;

    final text = widget.controller.text;
    if (text.isEmpty) return;

    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = GraphiteTypography.mono.copyWith(
      color: colorScheme.onSurface,
    );
    final textSpan = widget.controller.buildTextSpan(
      context: context,
      style: textStyle,
      withComposing: false,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: constraints.maxWidth - GraphiteSpacing.xl * 2);

    final textOffset = Offset(
      localPosition.dx - GraphiteSpacing.xl,
      localPosition.dy - GraphiteSpacing.xl + _scrollController.offset,
    );
    final position = textPainter.getPositionForOffset(textOffset).offset;
    final linkMatch = RegExp(r'\[\[([^\]\n]+)\]\]')
        .allMatches(text)
        .where((match) => position >= match.start && position <= match.end);

    if (linkMatch.isEmpty) return;
    final title = linkMatch.first[1]?.trim();
    if (title == null || title.isEmpty) return;

    FocusScope.of(context).unfocus();
    onWikiLinkTap(title);
  }

  Widget _buildFormattingToolbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GraphiteSpacing.lg,
        vertical: GraphiteSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Bold (**)',
              onPressed: () => _insertMarkup('**', '**'),
            ),
            _toolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Italic (*)',
              onPressed: () => _insertMarkup('*', '*'),
            ),
            _toolbarButton(
              icon: Icons.title,
              tooltip: 'Heading (#)',
              onPressed: () => _insertLinePrefix('#'),
            ),
            _toolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'List (-)',
              onPressed: () => _insertLinePrefix('-'),
            ),
            _toolbarButton(
              icon: Icons.link,
              tooltip: 'Link ([[]])',
              onPressed: () => _insertMarkup('[[', ']]'),
            ),
            const SizedBox(width: GraphiteSpacing.xl),
            _toolbarButton(icon: Icons.undo, tooltip: 'Undo', onPressed: _undo),
            _toolbarButton(icon: Icons.redo, tooltip: 'Redo', onPressed: _redo),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(GraphiteSpacing.sm),
          child: Icon(icon, size: 24, color: colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = widget.controller.text;
    final wordCount = _countWords(text);
    final charCount = text.length;
    final lineCount = _lineCount(text);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GraphiteSpacing.lg,
        vertical: GraphiteSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '$lineCount lines $wordCount words $charCount chars',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.38),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  int _lineCount(String text) {
    if (text.isEmpty) return 1;
    return '\n'.allMatches(text).length + 1;
  }
}
