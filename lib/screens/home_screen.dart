import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/file_picker.dart';
import '../models/note.dart';
import '../usecases/delete_note_use_case.dart';
import '../usecases/note_list_use_case.dart';
import '../usecases/quick_note_use_case.dart';
import '../widgets/quick_capture_dialog.dart';

/// Sort order for the note list.
enum NoteSortOrder { dateModified, dateCreated, titleAsc, titleDesc }

/// Filter mode for the note list.
enum NoteFilter { allNotes, byTag, withLinks }

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
  final GraphiteFilePicker _filePicker = GraphiteFilePicker();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  List<Note> _displayedNotes = [];
  bool _initialized = false;
  String? _activeTagFilter;
  int _filteredCount = 0;
  Map<String, int> _linkCounts = {};
  Timer? _debounceTimer;
  bool _isQuickCaptureOpen = false;
  NoteSortOrder _sortOrder = NoteSortOrder.dateModified;
  NoteFilter _activeFilter = NoteFilter.allNotes;
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
      if (!mounted) return;
      setState(() {
        _displayedNotes = notes;
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
      _loadNotes();
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

  void _setSortOrder(NoteSortOrder order) {
    if (_sortOrder == order) return;
    setState(() {
      _sortOrder = order;
      _applySort();
    });
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _loadNotes();
  }

  Future<void> _setFilter(NoteFilter filter) async {
    if (filter == _activeFilter) return;
    setState(() => _activeFilter = filter);

    switch (filter) {
      case NoteFilter.allNotes:
        _activeTagFilter = null;
        await _loadNotes();
      case NoteFilter.byTag:
        await _navigateToTags();
      case NoteFilter.withLinks:
        await _loadNotesWithLinks();
    }
  }

  Future<void> _loadNotesWithLinks() async {
    try {
      final notes = await _noteListUseCase.filterWithLinks();
      if (!mounted) return;
      setState(() {
        _activeTagFilter = null;
        _displayedNotes = notes;
        _applySort();
      });
    } catch (e) {
      debugPrint('Failed to load notes with links: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectionMode
            ? Text('${_selectedNoteIds.length} selected')
            : const Text('Graphite'),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        foregroundColor:
            Theme.of(context).appBarTheme.foregroundColor ??
            Theme.of(context).colorScheme.onSurface,
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete selected',
                  onPressed: _bulkDelete,
                ),
              ]
            : [
                PopupMenuButton<NoteSortOrder>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort notes',
                  onSelected: _setSortOrder,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: NoteSortOrder.dateModified,
                      child: Text('Date Modified'),
                    ),
                    const PopupMenuItem(
                      value: NoteSortOrder.dateCreated,
                      child: Text('Date Created'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: NoteSortOrder.titleAsc,
                      child: Text('Title A-Z'),
                    ),
                    const PopupMenuItem(
                      value: NoteSortOrder.titleDesc,
                      child: Text('Title Z-A'),
                    ),
                  ],
                ),
                PopupMenuButton<NoteFilter>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter notes',
                  onSelected: _setFilter,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: NoteFilter.allNotes,
                      child: Text('All Notes'),
                    ),
                    const PopupMenuItem(
                      value: NoteFilter.byTag,
                      child: Text('By Tag'),
                    ),
                    const PopupMenuItem(
                      value: NoteFilter.withLinks,
                      child: Text('With Links'),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: _handleQuickNoteAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'new_note',
                      child: Text('New Note'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'tags',
                      child: Row(
                        children: [
                          Icon(Icons.tag, size: 16),
                          SizedBox(width: 8),
                          Text('Browse Tags'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'open_file',
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, size: 16),
                          SizedBox(width: 8),
                          Text('Import File'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isEmpty ? 'Home' : 'Search Results',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildNoteList()),
          if (_activeTagFilter != null) _buildTagFilterBanner(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickCapture,
        tooltip: 'Quick capture',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 20,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.87),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search notes...',
                border: InputBorder.none,
              ),
              onChanged: _performSearch,
              maxLines: 1,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: _clearSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteList() {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'My Notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(child: _buildNotesList()),
      ],
    );
  }

  Widget _buildNotesList() {
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _displayedNotes.length,
        itemBuilder: (context, index) {
          final note = _displayedNotes[index];
          final isPinned = _pinnedNoteIds.contains(note.id);
          return Dismissible(
            key: Key('note_${note.id}'),
            direction: DismissDirection.horizontal,
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Swipe right → pin
                setState(() {
                  if (_pinnedNoteIds.contains(note.id)) {
                    _pinnedNoteIds.remove(note.id);
                  } else {
                    _pinnedNoteIds.add(note.id);
                  }
                  _applySort();
                });
                return false; // Don't dismiss, just pin
              } else {
                // Swipe left → delete with confirmation
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
                return false; // Handle deletion manually
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
            child: _buildNoteCard(note, isPinned: isPinned),
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(Note note, {bool isPinned = false}) {
    // Extract title from first heading or first line of content
    final lines = note.content.split('\n');
    String title = note.path;
    String subtitle = '';
    if (lines.isNotEmpty) {
      final first = lines.first.trim();
      if (first.startsWith('# ')) {
        title = first.substring(2);
        // Find first non-empty line after the heading for subtitle
        for (var i = 1; i < lines.length; i++) {
          final candidate = lines[i].trim();
          if (candidate.isNotEmpty) {
            subtitle = candidate;
            break;
          }
        }
      } else if (first.startsWith('## ')) {
        title = first.substring(3);
        subtitle = '';
      } else {
        title = first.length > 60 ? '${first.substring(0, 57)}...' : first;
        subtitle = '';
      }
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 4),
      color: _selectionMode && _selectedNoteIds.contains(note.id)
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: () => _selectionMode ? _toggleSelection(note) : _openNote(note),
        onLongPress: () => _selectionMode ? null : _enterSelectionMode(note),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPinned)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.push_pin,
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (note.tags.isNotEmpty || (_linkCounts[note.id] ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    // "N links" badge
                    if ((_linkCounts[note.id] ?? 0) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_linkCounts[note.id]} link${(_linkCounts[note.id] ?? 0) == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ...note.tags
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        ,
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuickNoteAction(String action) async {
    if (action == 'new_note') {
      final title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quick Note'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type your note...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onSubmitted: (value) {
              Navigator.pop(context, value);
            },
          ),
        ),
      );

      if (title != null && title.trim().isNotEmpty) {
        try {
          final created = await _quickNoteUseCase.fromText(
            title,
            'Quick note captured at ${DateTime.now()}.',
          );
          if (!mounted) return;
          context.push('/editor/${created.id}');

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note created'),
              duration: const Duration(seconds: 1),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        } catch (e) {
          debugPrint('Failed to create quick note: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to save note')));
        }
      }
    } else if (action == 'tags') {
      _navigateToTags();
    } else if (action == 'open_file') {
      _showFilePicker();
    }
  }

  Future<void> _showFilePicker() async {
    final file = await _filePicker.pickMarkdownFile();

    if (file != null) {
      try {
        final fileContent = await file.readAsString();
        debugPrint('Imported file: ${file.path}');

        final created = await _quickNoteUseCase.importFile(
          file.path,
          fileContent,
        );

        if (!mounted) return;
        context.push('/editor/${created.id}');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note imported successfully'),
            duration: const Duration(seconds: 1),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      } catch (e) {
        debugPrint('Failed to read/import file: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to import file')));
      }
    }
  }

  Future<void> _navigateToTags() async {
    final tag = await context.push<String>('/tags');
    if (tag != null && tag is String && mounted) {
      filterByTag(tag);
    }
  }

  void _openNote(Note note) async {
    if (note.id.isNotEmpty) {
      await context.push('/editor/${note.id}');
      if (mounted) _loadNotes();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[date.month - 1];

    if (date.year == now.year) {
      return '$monthStr ${date.day}';
    }
    return '$monthStr ${date.day}, ${date.year}';
  }

  Widget _buildTagFilterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtered by $_activeTagFilter ($_filteredCount note${_filteredCount == 1 ? '' : 's'})',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
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
