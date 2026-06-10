import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:graphite/features/home/usecases/delete_note_use_case.dart';
import 'package:graphite/features/home/usecases/note_list_use_case.dart';
import 'package:graphite/features/home/usecases/quick_note_use_case.dart';
import 'package:graphite/features/home/widgets/home_note_card.dart';
import 'package:graphite/features/home/widgets/home_search_bar.dart';
import 'package:graphite/features/home/widgets/home_tag_filter_bar.dart';
import 'package:graphite/features/home/widgets/quick_capture_dialog.dart';
import 'package:graphite/core/design/spacing.dart';
import 'package:graphite/core/design/typography.dart';
import 'package:graphite/core/models/note.dart';
import 'package:graphite/core/models/tag.dart';

/// Sort order for the note list.
enum NoteSortOrder { dateModified, dateCreated, titleAsc, titleDesc }

/// HomeScreen with quick note capture, file import, and tag navigation.
class HomeScreen extends StatefulWidget {
  final NoteListUseCase noteListUseCase;
  final QuickNoteUseCase quickNoteUseCase;
  final DeleteNoteUseCase deleteNoteUseCase;

  const HomeScreen({
    super.key,
    required this.noteListUseCase,
    required this.quickNoteUseCase,
    required this.deleteNoteUseCase,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  late final NoteListUseCase _noteListUseCase;
  late final QuickNoteUseCase _quickNoteUseCase;
  late final DeleteNoteUseCase _deleteNoteUseCase;
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  List<Note> _displayedNotes = [];
  List<Tag> _availableTags = [];
  bool _initialized = false;
  String? _activeTagFilter;
  int _filteredCount = 0;
  Map<String, int> _linkCounts = {};
  Timer? _debounceTimer;
  bool _isQuickCaptureOpen = false;
  final NoteSortOrder _sortOrder = NoteSortOrder.dateModified;
  final Set<String> _pinnedNoteIds = {};

  // Selection mode
  bool _selectionMode = false;
  final Set<String> _selectedNoteIds = {};

  void _enterSelectionMode(Note note) {
    setState(() {
      _selectionMode = true;
      _selectedNoteIds.add(note.id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  void _toggleSelection(Note note) {
    setState(() {
      if (_selectedNoteIds.contains(note.id)) {
        _selectedNoteIds.remove(note.id);
        if (_selectedNoteIds.isEmpty) {
          _selectionMode = false;
        }
      } else {
        _selectedNoteIds.add(note.id);
      }
    });
  }

  Future<void> _bulkDelete() async {
    final count = _selectedNoteIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notes'),
        content: Text(
          'Delete $count note${count == 1 ? '' : 's'}? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _deleteNoteUseCase.bulk(_selectedNoteIds);
        _exitSelectionMode();
        _loadNotes();
      } catch (e) {
        debugPrint('Failed to bulk delete: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _noteListUseCase = widget.noteListUseCase;
    _quickNoteUseCase = widget.quickNoteUseCase;
    _deleteNoteUseCase = widget.deleteNoteUseCase;
    _loadNotes();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await _noteListUseCase.loadAll();
      final tags = await _noteListUseCase.getAllTags();
      if (!mounted) return;
      setState(() {
        _displayedNotes = notes;
        _availableTags = tags;
        _applySort();
        _initialized = true;
      });
      // Load link counts for badge display (non-fatal)
      try {
        final counts = <String, int>{};
        for (final note in notes) {
          final count = await _noteListUseCase.linkCount(note.id);
          counts[note.id] = count;
        }
        if (!mounted) return;
        setState(() {
          _linkCounts = counts;
        });
      } catch (_) {
        // Link counts are best-effort; don't block the note list.
      }
    } catch (e) {
      debugPrint('Failed to load notes: $e');
      if (!mounted) return;
      setState(() => _initialized = true);
    }
  }

  Future<void> _performSearch(String query) async {
    _debounceTimer?.cancel();

    setState(() {
      _searchQuery = query;
    });

    if (query.isEmpty) {
      if (_activeTagFilter != null) {
        await filterByTag(_activeTagFilter!);
      } else {
        _loadNotes();
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);

      try {
        final results = await _noteListUseCase.search(query);
        if (!mounted) return;
        setState(() {
          _displayedNotes = results;
          _isSearching = false;
        });
      } catch (e) {
        debugPrint('Search failed: $e');
        if (!mounted) return;
        setState(() => _isSearching = false);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    if (_activeTagFilter != null) {
      filterByTag(_activeTagFilter!);
    } else {
      _loadNotes();
    }
  }

  void _applySort() {
    final notes = List<Note>.from(_displayedNotes);

    // Pinned notes always appear first
    notes.sort((a, b) {
      final aPinned = _pinnedNoteIds.contains(a.id);
      final bPinned = _pinnedNoteIds.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      switch (_sortOrder) {
        case NoteSortOrder.dateModified:
          return b.updatedAt.compareTo(a.updatedAt);
        case NoteSortOrder.dateCreated:
          return b.createdAt.compareTo(a.createdAt);
        case NoteSortOrder.titleAsc:
          return a.path.compareTo(b.path);
        case NoteSortOrder.titleDesc:
          return b.path.compareTo(a.path);
      }
    });

    _displayedNotes = notes;
  }

  Future<void> _selectTag(String? tag) async {
    if (tag == null) {
      clearTagFilter();
      return;
    }
    await filterByTag(tag);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
              title: Text('${_selectedNoteIds.length} selected'),
              backgroundColor:
                  Theme.of(context).appBarTheme.backgroundColor ??
                  Theme.of(context).colorScheme.surface,
              foregroundColor:
                  Theme.of(context).appBarTheme.foregroundColor ??
                  Theme.of(context).colorScheme.onSurface,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete selected',
                  onPressed: _bulkDelete,
                ),
              ],
            )
          : const PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: SizedBox.shrink(),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSearchBar(
              controller: _searchController,
              query: _searchQuery,
              onChanged: _performSearch,
              onClear: _clearSearch,
            ),
            if (_availableTags.isNotEmpty)
              HomeTagFilterBar(
                tags: _availableTags,
                selectedTag: _activeTagFilter,
                onTagSelected: _selectTag,
              ),
            Expanded(child: _buildNotesList()),
            if (_activeTagFilter != null) _buildTagFilterBanner(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickCapture,
        tooltip: 'Quick capture',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesList() {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_displayedNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.38),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'No notes yet. Tap + to create your first note.'
                  : 'No notes matching "$_searchQuery"',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: GraphiteSpacing.pageInset,
          vertical: GraphiteSpacing.sm,
        ),
        itemCount: _displayedNotes.length,
        itemBuilder: (context, index) {
          final note = _displayedNotes[index];
          final isPinned = _pinnedNoteIds.contains(note.id);
          return Dismissible(
            key: Key('note_${note.id}'),
            direction: DismissDirection.horizontal,
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                setState(() {
                  if (_pinnedNoteIds.contains(note.id)) {
                    _pinnedNoteIds.remove(note.id);
                  } else {
                    _pinnedNoteIds.add(note.id);
                  }
                  _applySort();
                });
                return false;
              } else {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Note'),
                    content: Text(
                      'Delete "${note.path}"? '
                      'This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  try {
                    await _deleteNoteUseCase.single(note.id);
                    _loadNotes();
                  } catch (e) {
                    debugPrint('Failed to delete note: $e');
                  }
                }
                return false;
              }
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              color: Theme.of(context).colorScheme.tertiary,
              child: Icon(
                Icons.push_pin,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Theme.of(context).colorScheme.error,
              child: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            child: HomeNoteCard(
              note: note,
              isPinned: isPinned,
              isSelected: _selectionMode && _selectedNoteIds.contains(note.id),
              linkCount: _linkCounts[note.id] ?? 0,
              selectionMode: _selectionMode,
              onTap: () =>
                  _selectionMode ? _toggleSelection(note) : _openNote(note),
              onLongPress: () =>
                  _selectionMode ? null : _enterSelectionMode(note),
            ),
          );
        },
      ),
    );
  }

  void _openNote(Note note) async {
    if (note.id.isNotEmpty) {
      await context.push('/editor/${note.id}');
      if (mounted) _loadNotes();
    }
  }

  Widget _buildTagFilterBanner() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GraphiteSpacing.pageInset,
        vertical: GraphiteSpacing.sm,
      ),
      color: scheme.secondary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 16, color: scheme.secondary),
          const SizedBox(width: GraphiteSpacing.sm),
          Expanded(
            child: Text(
              'Filtered by $_activeTagFilter ($_filteredCount note${_filteredCount == 1 ? '' : 's'})',
              style: GraphiteTypography.label.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: clearTagFilter,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void clearTagFilter() {
    setState(() {
      _activeTagFilter = null;
      _filteredCount = 0;
    });
    _loadNotes();
  }

  /// Filter the note list to only show notes with [tag].
  Future<void> filterByTag(String tag) async {
    try {
      final notes = await _noteListUseCase.filterByTag(tag);
      if (!mounted) return;
      setState(() {
        _activeTagFilter = tag;
        _displayedNotes = notes;
        _filteredCount = notes.length;
        _searchQuery = '';
      });
    } catch (e) {
      debugPrint('Failed to filter by tag: $e');
    }
  }

  void _showQuickCapture() {
    // Debounce: prevent opening multiple sheets simultaneously
    if (_isQuickCaptureOpen) return;
    _isQuickCaptureOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FadeTransition(
        opacity: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeIn,
        ),
        child: QuickCaptureDialog(
          onSave: (title, content, tags) async {
            _isQuickCaptureOpen = false;
            Navigator.pop(context); // close bottom sheet

            try {
              await _quickNoteUseCase.fromText(title, content, tags: tags);
              if (!mounted) return;
              _loadNotes(); // refresh list with new note at top
            } catch (e) {
              debugPrint('Quick capture save failed: $e');
              if (!mounted) return;
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(content: Text('Failed to save note')),
              );
            }
          },
          onCancel: () {
            _isQuickCaptureOpen = false;
          },
        ),
      ),
    ).whenComplete(() {
      _isQuickCaptureOpen = false;
    });
  }
}
