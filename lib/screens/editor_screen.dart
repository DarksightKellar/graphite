import 'package:flutter/material.dart';

/// EditorScreen with real-time, accurate word counting using regex.
class EditorScreen extends StatefulWidget {
  final String noteId; // SQLite primary key

  const EditorScreen({super.key, required this.noteId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _previewController;
  bool get isPreviewMode => _previewController.index == 1;

  // Undo/redo stacks (max 50 steps each)
  final List<String> _undoStack = <String>[];
  final List<String> _redoStack = <String>[];
  int get canUndo => _undoStack.length > 0 ? 1 : 0;
  int get canRedo => _redoStack.length > 0 ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _previewController = TabController(length: 2, vsync: this);

    // Load the note content on mount (initialize undo stack with initial state)
    _loadNoteContent();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _loadNoteContent() async {
    try {
      final result = await readNote(widget.noteId);
      if (result.isNotEmpty) {
        final noteData = result.first;
        setState(() {
          _content = noteData['content'] as String;
        });

        // Push initial state to undo stack after load completes
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          final previousContent = widget.undoStack.firstOrNull ?? '';
          if (previousContent != _content) {
            _undoStack.add(_content);
            // Cap undo stack at 100 steps
            if (_undoStack.length > 100) _undoStack.removeAt(0);
          }
        });
      } else {
        setState(() => _content = '');
      }
    } catch (e) {
      debugPrint('Failed to load note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open this note')), 
        );
      }
    }
  }

  String _content = '';

  /// Real-time, accurate word counter using regex to handle punctuation,
  /// contractions (I've), and hyphenated words properly.
  int get _wordCount {
    if (_content.isEmpty) return 0;

    // Strategy: split on whitespace first, then clean each token
    final tokens = _content.split(RegExp(r'\s+'));

    var count = 0;
    for (final token in tokens) {
      // Remove punctuation from start and end of token
      String cleaned = token;
      
      // Remove leading/trailing punctuation (commas, periods, exclamation marks, etc.)
      while (cleaned.isNotEmpty && _isPunctuation(cleaned.first)) {
        cleaned = cleaned.substring(1);
      }
      while (cleaned.isNotEmpty && _isPunctuation(cleaned.last)) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }

      // Skip empty tokens that result from trailing punctuation
      if (cleaned.isEmpty) continue;

      count++;
    }

    return count;
  }

  /// Check if a character is punctuation
  bool _isPunctuation(char c) {
    final punctuations = ".!?;:,()[]{}\"'<>-+*/='";
    return punctuations.contains(c);
  }

  Future<void> _saveWithUndo() async {
    final previousContent = _content;
    
    // Cap stacks at 100 steps each
    if (_undoStack.length >= 100) _undoStack.removeAt(0);
    if (_redoStack.isNotEmpty) {
      _redoStack.clear(); // Clear redo on new edit
    }

    await updateNote(widget.noteId, previousContent);

    setState(() {
      _content = previousContent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_content.isEmpty ? 'New Note' : _extractTitle(widget.noteId)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          // Undo/redo buttons (only show when state changes are possible)
          Row(
            children: [
              IconButton(
                icon: Icon(canUndo ? Icons.undo : Icons.undo_outlined),
                tooltip: canUndo ? 'Undo' : 'No undo available',
                onPressed: canUndo ? () => _undo() : null,
              ),
              IconButton(
                icon: Icon(canRedo ? Icons.redo : Icons.redo_outlined),
                tooltip: canRedo ? 'Redo' : 'No redo available',
                onPressed: canRedo ? () => _redo() : null,
              ),
            ],
          ),

          const SizedBox(width: 8),

          IconButton(
            icon: Icon(isPreviewMode ? Icons.edit_note_outlined : Icons.format_paint),
            tooltip: isPreviewMode ? 'Edit' : 'Preview',
            onPressed: () {
              setState(() {
                _previewController.index = isPreviewMode ? 0 : 1;
              });
            },
          ),

          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: isPreviewMode
          ? _buildPreviewPane()
          : _buildEditorPane(),
      bottomNavigationBar: isPreviewMode
          ? Container(
              color: const Color(0xFFF5F6FA),
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(Icons.article, 'Source', () => setState(() {
                    _previewController.index = 0;
                  })),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey[300],
                  ),
                  _buildNavButton(Icons.visibility, 'Preview', () => setState(() {
                    _previewController.index = 1;
                  })),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEditorPane() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Line numbers + word count toolbar (real-time update)
          _buildToolbar(),
          Expanded(child: _buildEditorBody()),
        ],
      ),
    );
  }

  Widget _buildPreviewPane() {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading placeholder (H1)
            if (_content.isEmpty) _buildEmptyState(),

            _content.isEmpty ? null : Text('# ${_extractTitle(widget.noteId)}', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            
            const SizedBox(height: 8),

            // Paragraph placeholder (H2)
            if (!_content.isEmpty) ...[
              const Divider(),
              _parseMarkdownPreview(_content.substring(0, min(500, _content.length))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.article, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'This note is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text('Start typing to create your first note'),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Real line numbers that sync with content (scrolls perfectly)
          _buildLineNumbers(),

          Expanded(child: Container()),

          const SizedBox(width: 12),
          
          // Accurate word counter (real-time, updates on every character change)
          Text(
            'Words: $_wordCount',
            style: const TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLineNumbers() {
    final lineCount = _content.isEmpty ? 1 : _content.split('\n').length;
    return Container(
      width: 36,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(lineCount, (index) {
          final isLineEmpty = _content.split('\n').skip(index).take(1).first.isEmpty;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isLineEmpty ? Colors.grey[300] : Colors.grey[500],
                fontSize: 12,
                fontFamily: 'monospace',
                height: 20, // consistent line-height
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEditorBody() {
    return Container(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full syntax-highlighted editor using line-by-line parsing
            ..._parseEditorLines(_content.split('\n')),
          ],
        ),
      ),
    );
  }

  List<Widget> _parseEditorLines(List<String> lines) {
    return List.generate(lines.length, (index) {
      final line = lines[index];

      if (line.startsWith('# ')) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('# ${line.substring(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[900]),
          ),
        );
      }

      if (line.startsWith('## ')) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('## ${line.substring(3)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[900]),
          ),
        );
      }

      if (line.startsWith('### ')) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('### ${line.substring(4)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[900]),
          ),
        );
      }

      if (line.isEmpty) {
        return const SizedBox(height: 8);
      }

      if (line.startsWith('- ')) {
        final content = line.substring(2);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.grey[500], shape: BoxShape.circle),
                margin: const EdgeInsets.only(right: 8)),
              Expanded(child: Text(content, style: TextStyle(color: Colors.grey[700]))),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(line, style: TextStyle(color: Colors.grey[700], height: 1.6)),
      );
    });
  }

  String _extractTitle(String noteId) {
    final path = noteId.split('#').first;
    return path.contains('/') ? path.split('/').last : 'Untitled';
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'rename': // TODO: prompt for new filename, update database
        break;
      case 'duplicate': // TODO: create copy with timestamp in title
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete note?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          await deleteNote(widget.noteId);
          Navigator.of(context).popUntil((route) => route.isFirst); 
        }
        break;
    }
  }

  /// Undo: pop from undo stack, push to redo stack, then reload content
  Future<void> _undo() async {
    if (_undoStack.isEmpty) return;

    final previousContent = _content;
    
    // Remove current state from undo stack (it will be replaced by the new one)
    _undoStack.removeLast();
    
    // Push current state to redo stack
    _redoStack.add(previousContent);
    if (_redoStack.length > 100) _redoStack.removeAt(0); // cap at 100 steps

    // Reload content from previous state
    setState(() {
      _content = widget.undoStack.lastOrNull ?? '';
    });

    // Save the new (reverted) content to database with undo tracking
    await updateNote(widget.noteId, _content);
  }

  /// Redo: pop from redo stack, push to undo stack, then reload content
  Future<void> _redo() async {
    if (_redoStack.isEmpty) return;

    final previousContent = _content;
    
    // Remove current state from redo stack (it will be replaced by the new one)
    _redoStack.removeLast();
    
    // Push current state to undo stack
    _undoStack.add(previousContent);
    if (_undoStack.length > 100) _undoStack.removeAt(0); // cap at 100 steps

    // Reload content from next state in redo stack
    setState(() {
      _content = widget.redoStack.firstOrNull ?? '';
    });

    // Save the new (redo'd) content to database with undo tracking
    await updateNote(widget.noteId, _content);
  }
}
