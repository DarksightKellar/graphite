import 'package:flutter/material.dart';

/// A clean, distraction-free markdown editor pane.
/// Accepts a TextEditingController to bind content.
class EditorPane extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool showLineNumbers;

  const EditorPane({
    super.key,
    required this.controller,
    this.onChanged,
    this.showLineNumbers = true,
  });

  @override
  State<EditorPane> createState() => _EditorPaneState();
}

class _EditorPaneState extends State<EditorPane> {
  final FocusNode _focusNode = FocusNode();
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  @override
  void dispose() {
    _focusNode.dispose();
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
      final newText = text.replaceRange(
        cursorPos,
        cursorPos,
        '$prefix$suffix',
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: cursorPos + prefix.length,
        ),
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
      final newText = text.replaceRange(
        lineStart,
        lineStart,
        prefixWithSpace,
      );
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
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.6,
                color: colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
          if (widget.showLineNumbers) _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ),
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
          const Spacer(),
          _toolbarButton(
            icon: Icons.undo,
            tooltip: 'Undo',
            onPressed: _undo,
          ),
          _toolbarButton(
            icon: Icons.redo,
            tooltip: 'Redo',
            onPressed: _redo,
          ),
        ],
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
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.70),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: colorScheme.surfaceContainerHighest,
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
