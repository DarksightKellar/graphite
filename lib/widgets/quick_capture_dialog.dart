import 'package:flutter/material.dart';

/// A bottom sheet dialog for quickly capturing a note in ≤2 taps.
///
/// Shows:
/// - Auto-focused title field
/// - Optional content field with markdown hints and inline #tag extraction
/// - Tag chips (live-updating as content is typed)
/// - Character/word count
/// - Save and Cancel buttons
/// - Keyboard Done action saves
/// - Dismiss confirmation when unsaved content exists
class QuickCaptureDialog extends StatefulWidget {
  /// Called when the user taps Save.
  ///
  /// [title] is the text from the title field (never null, may be empty).
  /// [content] is the text from the content field (never null, may be empty).
  /// [tags] is the list of extracted #tag strings (with # prefix).
  final void Function(String title, String content, List<String> tags)? onSave;

  /// Called when the user taps Cancel.
  final VoidCallback? onCancel;

  const QuickCaptureDialog({super.key, this.onSave, this.onCancel});

  @override
  State<QuickCaptureDialog> createState() => _QuickCaptureDialogState();
}

class _QuickCaptureDialogState extends State<QuickCaptureDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _tags = [];
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    _extractTags();
    setState(() {}); // trigger rebuild for char/word count
  }

  void _extractTags() {
    final text = _contentController.text;
    final tagPattern = RegExp(r'#[a-zA-Z0-9_-]+');
    final tags =
        tagPattern.allMatches(text).map((m) => m.group(0)!).toSet().toList();
    setState(() {
      _tags = tags;
    });
  }

  void _handleSave() {
    widget.onSave?.call(
      _titleController.text,
      _contentController.text,
      _tags,
    );
  }

  void _handleCancel() {
    widget.onCancel?.call();
  }

  bool _hasUnsavedContent() =>
      _titleController.text.isNotEmpty || _contentController.text.isNotEmpty;

  void _showDismissConfirmDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard note?'),
        content: const Text('You have unsaved content. Discard it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    ).then((discard) {
      if (discard == true && mounted) {
        setState(() => _allowPop = true);
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedContent() || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasUnsavedContent() && !_allowPop) {
          _showDismissConfirmDialog();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText:
                    'Content — supports **bold**, *italic*, #tags, [[links]] markdown',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            if (_contentController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${_contentController.text.length} chars · '
                '${_contentController.text.split(RegExp(r'\\s+')).where((w) => w.isNotEmpty).length} words',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children:
                    _tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _handleCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
