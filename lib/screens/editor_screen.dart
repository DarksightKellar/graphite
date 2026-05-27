import 'dart:async';
import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/note.dart';
import '../widgets/editor_pane.dart';
import '../widgets/preview_pane.dart';

/// Markdown editor screen with live preview and [[wiki-link]] navigation.
///
/// Features:
/// - Loads note content from GraphiteDB
/// - Two-pane layout: editor (left) + live preview (right)
/// - [[wiki-link]] rendering as tappable widgets in preview
/// - Tap [[link]]: navigate to note or offer to create
/// - Auto-save on pause (debounced, 2s after last keystroke)
/// - Save on app backgrounding (AppLifecycleState.paused)
/// - Link extraction on save
/// - Back navigation with unsaved changes warning
/// - Swipe from left edge to go back
/// - Saving/Saved status indicator
class EditorScreen extends StatefulWidget {
  final String noteId;
  final GraphiteDB? db;

  const EditorScreen({super.key, required this.noteId, this.db});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  late final GraphiteDB _db;

  String? _savedContent;
  Timer? _autoSaveTimer;
  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;
  bool _showSaved = false;
  Timer? _savedIndicatorTimer;

  bool get _hasUnsavedChanges => _controller.text != _savedContent;

  @override
  void initState() {
    super.initState();
    _db = widget.db ?? GraphiteDB();
    WidgetsBinding.instance.addObserver(this);
    _loadNote();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _savedIndicatorTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _save();
    }
  }

  Future<void> _loadNote() async {
    try {
      await _db.initialize();
      final note = await _db.readNote(widget.noteId);
      if (note != null && mounted) {
        _controller.text = note.content;
        _savedContent = note.content;
      }
    } catch (e) {
      if (mounted) {
        _loadError = '$e';
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onTextChanged(String text) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _save();
    });
    setState(() {});
  }

  Future<void> _save() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final content = _controller.text;
      final existing = await _db.readNote(widget.noteId);
      if (existing != null) {
        await _db.updateNote(existing.copyWith(
          content: content,
          updatedAt: DateTime.now(),
        ));
      } else {
        await _db.createNote(Note(
          id: widget.noteId,
          path: widget.noteId,
          filePath: widget.noteId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          content: content,
          tags: const [],
        ));
      }
      await _db.extractLinks(widget.noteId, content);
      _savedContent = content;

      // Show "Saved" indicator briefly
      if (mounted) {
        setState(() {
          _isSaving = false;
          _showSaved = true;
        });
        _savedIndicatorTimer?.cancel();
        _savedIndicatorTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showSaved = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _onLinkTap(String title) async {
    final note = await _db.findNoteByTitle(title);

    if (!mounted) return;

    if (note != null) {
      Navigator.pushNamed(context, '/editor/${note.id}');
    } else {
      final create = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Create "$title"?'),
          content: const Text('This note does not exist yet. Create it now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (create == true && mounted) {
        final newNote = await _db.createNote(Note(
          id: '',
          path: title,
          filePath: title,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          content: '# $title\n\n',
          tags: const [],
        ));
        if (mounted) {
          Navigator.pushNamed(context, '/editor/${newNote.id}');
        }
      }
    }
  }

  void _handleSwipeBack() {
    if (_hasUnsavedChanges) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Note'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          actions: [
            if (_showSaved)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check,
                        size: 18, color: colorScheme.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Saved',
                      style: TextStyle(
                        color: colorScheme.tertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (_isSaving)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                ),
              )
            else if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: _save,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Text(
                      'Failed to load: $_loadError',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  )
                : GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 300) {
                        _handleSwipeBack();
                      }
                    },
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: EditorPane(
                            controller: _controller,
                            onChanged: _onTextChanged,
                            showLineNumbers: false,
                          ),
                        ),
                        const VerticalDivider(thickness: 1, width: 1),
                        Expanded(
                          flex: 2,
                          child: PreviewPane(
                            content: _controller.text,
                            onLinkTap: _onLinkTap,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
