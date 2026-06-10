import 'dart:async';

import 'package:flutter/material.dart';

import 'package:graphite/core/design/colors.dart';
import 'package:graphite/core/design/spacing.dart';
import 'package:graphite/core/design/typography.dart';

/// A markdown controller that keeps raw markdown text editable while painting
/// common markdown syntax with live-preview styling.
class InlineMarkdownEditingController extends TextEditingController {
  InlineMarkdownEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final sourceStyle = style ?? GraphiteTypography.mono;
    final baseStyle = GraphiteTypography.body.copyWith(
      color: colorScheme.onSurface,
    );
    final tokenStyle = sourceStyle.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.45),
    );
    final strongStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
    final emphasisStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
    final strikeStyle = baseStyle.copyWith(
      decoration: TextDecoration.lineThrough,
    );
    final highlightStyle = baseStyle.copyWith(
      backgroundColor: colorScheme.tertiary.withValues(alpha: 0.18),
    );
    final inlineCodeStyle = GraphiteTypography.mono.copyWith(
      color: colorScheme.onSurface,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.55,
      ),
    );
    final codeBlockStyle = GraphiteTypography.mono.copyWith(
      color: colorScheme.onSurface,
    );
    final listMarkerStyle = sourceStyle.copyWith(
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
      backgroundColor: GraphiteColors.moss.withValues(alpha: 0.12),
    );
    final blockquoteStyle = baseStyle.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.78),
      fontStyle: FontStyle.italic,
    );
    final checkedTaskStyle = baseStyle.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.64),
      decoration: TextDecoration.lineThrough,
    );
    final headingStyles = List<TextStyle>.generate(
      6,
      (index) => _markdownHeadingStyle(colorScheme.onSurface, index + 1),
    );

    final children = <InlineSpan>[];
    final lines = text.split('\n');
    var inCodeFence = false;

    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        children.add(TextSpan(text: '\n', style: sourceStyle));
      }

      final line = lines[i];
      if (_isFenceLine(line)) {
        children.add(TextSpan(text: line, style: tokenStyle));
        inCodeFence = !inCodeFence;
        continue;
      }

      if (inCodeFence) {
        children.add(TextSpan(text: line, style: codeBlockStyle));
        continue;
      }

      _appendDecoratedLine(
        children,
        line,
        baseStyle,
        sourceStyle,
        tokenStyle,
        strongStyle,
        emphasisStyle,
        strikeStyle,
        highlightStyle,
        inlineCodeStyle,
        headingStyles,
        listMarkerStyle,
        linkStyle,
        tagStyle,
        blockquoteStyle,
        checkedTaskStyle,
      );
    }

    return TextSpan(style: sourceStyle, children: children);
  }

  static void _appendDecoratedLine(
    List<InlineSpan> children,
    String line,
    TextStyle baseStyle,
    TextStyle sourceStyle,
    TextStyle tokenStyle,
    TextStyle strongStyle,
    TextStyle emphasisStyle,
    TextStyle strikeStyle,
    TextStyle highlightStyle,
    TextStyle inlineCodeStyle,
    List<TextStyle> headingStyles,
    TextStyle listMarkerStyle,
    TextStyle linkStyle,
    TextStyle tagStyle,
    TextStyle blockquoteStyle,
    TextStyle checkedTaskStyle,
  ) {
    if (line.isEmpty) return;

    final headingMatch = RegExp(r'^(#{1,6})(\s+)').firstMatch(line);
    var start = 0;
    TextStyle lineBaseStyle = baseStyle;

    if (headingMatch != null) {
      children.add(TextSpan(text: headingMatch[1], style: tokenStyle));
      children.add(TextSpan(text: headingMatch[2], style: sourceStyle));
      start = headingMatch.end;
      lineBaseStyle = headingStyles[headingMatch[1]!.length - 1];
    } else {
      final quoteMatch = RegExp(r'^(\s*>+\s?)').firstMatch(line);
      if (quoteMatch != null) {
        children.add(TextSpan(text: quoteMatch[1], style: tokenStyle));
        start = quoteMatch.end;
        lineBaseStyle = blockquoteStyle;
      } else {
        final ruleMatch = RegExp(
          r'^\s{0,3}((?:[-*_]\s*){3,})$',
        ).firstMatch(line);
        if (ruleMatch != null) {
          children.add(TextSpan(text: line, style: tokenStyle));
          return;
        }

        final listMatch = RegExp(
          r'^(\s*)([-*+]|\d+[.)])(\s+)(\[[ xX]\])?(\s*)',
        ).firstMatch(line);
        if (listMatch != null) {
          children.add(TextSpan(text: listMatch[1], style: sourceStyle));
          children.add(TextSpan(text: listMatch[2], style: listMarkerStyle));
          children.add(TextSpan(text: listMatch[3], style: sourceStyle));
          final taskMarker = listMatch[4];
          if (taskMarker != null) {
            final checked = taskMarker.toLowerCase() == '[x]';
            children.add(
              TextSpan(
                text: taskMarker,
                style: checked ? listMarkerStyle : tokenStyle,
              ),
            );
            children.add(TextSpan(text: listMatch[5], style: sourceStyle));
            lineBaseStyle = checked ? checkedTaskStyle : baseStyle;
          }
          start = listMatch.end;
        }
      }
    }

    _appendInlineSpans(
      children,
      line.substring(start),
      lineBaseStyle,
      tokenStyle,
      strongStyle,
      emphasisStyle,
      strikeStyle,
      highlightStyle,
      inlineCodeStyle,
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
    TextStyle strikeStyle,
    TextStyle highlightStyle,
    TextStyle inlineCodeStyle,
    TextStyle linkStyle,
    TextStyle tagStyle,
  ) {
    final pattern = RegExp(
      r'(`[^`\n]+?`)|(\[\[[^\]\n]+\]\])|(\[[^\]\n]+?\]\([^) \n]+?\))|(\*\*[^*\n]+?\*\*)|(__[^_\n]+?__)|(?<!\*)\*[^*\n]+?\*(?!\*)|(?<!\w)_[^_\n]+?_(?!\w)|(~~[^~\n]+?~~)|(==[^=\n]+?==)|(?<!\w)#[a-zA-Z0-9_-]+',
    );
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        children.add(
          TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
        );
      }

      final token = match[0]!;
      if (token.startsWith('`')) {
        children.add(TextSpan(text: '`', style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: inlineCodeStyle,
          ),
        );
        children.add(TextSpan(text: '`', style: tokenStyle));
      } else if (token.startsWith('[[')) {
        children.add(TextSpan(text: '[[', style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: linkStyle,
          ),
        );
        children.add(TextSpan(text: ']]', style: tokenStyle));
      } else if (token.startsWith('[')) {
        final closeLabel = token.indexOf(']');
        children.add(TextSpan(text: '[', style: tokenStyle));
        children.add(
          TextSpan(text: token.substring(1, closeLabel), style: linkStyle),
        );
        children.add(
          TextSpan(text: token.substring(closeLabel), style: tokenStyle),
        );
      } else if (token.startsWith('**') || token.startsWith('__')) {
        final marker = token.substring(0, 2);
        children.add(TextSpan(text: marker, style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: strongStyle,
          ),
        );
        children.add(TextSpan(text: marker, style: tokenStyle));
      } else if (token.startsWith('*') || token.startsWith('_')) {
        final marker = token[0];
        children.add(TextSpan(text: marker, style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: emphasisStyle,
          ),
        );
        children.add(TextSpan(text: marker, style: tokenStyle));
      } else if (token.startsWith('~~')) {
        children.add(TextSpan(text: '~~', style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: strikeStyle,
          ),
        );
        children.add(TextSpan(text: '~~', style: tokenStyle));
      } else if (token.startsWith('==')) {
        children.add(TextSpan(text: '==', style: tokenStyle));
        children.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: highlightStyle,
          ),
        );
        children.add(TextSpan(text: '==', style: tokenStyle));
      } else {
        children.add(TextSpan(text: token, style: tagStyle));
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
  }

  static bool _isFenceLine(String line) {
    return RegExp(r'^\s*(```+|~~~+)').hasMatch(line);
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
  Timer? _undoDebounceTimer;
  String? _lastKnownText;
  String? _typingBatchStartText;
  bool _isApplyingHistory = false;

  @override
  void initState() {
    super.initState();
    _lastKnownText = widget.controller.text;
  }

  @override
  void didUpdateWidget(EditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _undoStack.clear();
      _redoStack.clear();
      _undoDebounceTimer?.cancel();
      _typingBatchStartText = null;
      _lastKnownText = widget.controller.text;
    } else {
      _lastKnownText ??= widget.controller.text;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    _undoDebounceTimer?.cancel();
    super.dispose();
  }

  void _pushUndoState() {
    _pushUndoText(widget.controller.text);
  }

  void _pushUndoText(String text) {
    if (_undoStack.isNotEmpty && _undoStack.last == text) return;
    _undoStack.add(text);
    _redoStack.clear();
  }

  void _recordTextEdit(String text) {
    if (_isApplyingHistory) return;

    final previous = _lastKnownText ?? widget.controller.text;
    if (text == previous) return;

    _typingBatchStartText ??= previous;
    if (_typingBatchStartText == previous) {
      _pushUndoText(previous);
    }

    _lastKnownText = text;
    _undoDebounceTimer?.cancel();
    _undoDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _typingBatchStartText = null;
    });
  }

  void _insertMarkup(String prefix, String suffix) {
    _undoDebounceTimer?.cancel();
    _typingBatchStartText = null;
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
    _lastKnownText = controller.text;
  }

  void _insertLinePrefix(String prefix) {
    _undoDebounceTimer?.cancel();
    _typingBatchStartText = null;
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
    _lastKnownText = controller.text;
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _undoDebounceTimer?.cancel();
    _typingBatchStartText = null;
    _redoStack.add(widget.controller.text);
    final previous = _undoStack.removeLast();
    _isApplyingHistory = true;
    widget.controller.value = TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    );
    _isApplyingHistory = false;
    _lastKnownText = previous;
    widget.onChanged?.call(previous);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoDebounceTimer?.cancel();
    _typingBatchStartText = null;
    _undoStack.add(widget.controller.text);
    final next = _redoStack.removeLast();
    _isApplyingHistory = true;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _isApplyingHistory = false;
    _lastKnownText = next;
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
                    onChanged: (text) {
                      _recordTextEdit(text);
                      widget.onChanged?.call(text);
                    },
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
