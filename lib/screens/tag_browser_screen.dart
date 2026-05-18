import 'package:flutter/material.dart';

/// TagBrowser: see all tags across your notes with clickable filters.
class TagBrowserScreen extends StatefulWidget {
  const TagBrowserScreen({super.key});

  @override
  State<TagBrowserScreen> createState() => _TagBrowserScreenState();
}

class _TagBrowserScreenState extends State<TagBrowserScreen> {
  final List<String> _allTags = <String>[]; // e.g., ['personal', 'journaling', 'ideas']
  String? _activeFilter; // currently selected tag

  @override
  void initState() {
    super.initState();
    _loadAllNotesAndExtractTags();
  }

  /// Parse all notes' content to extract unique tags (#tag syntax)
  Future<void> _loadAllNotesAndExtractTags() async {
    try {
      final notes = await getAllNotes();
      
      // TODO: read each note's full BLOB content and parse for #tag
      // For now, seed with demo data
      setState(() {
        _allTags.addAll([
          'personal', 'journaling', 'ideas', 'work', 'future',
          'getting-started', 'tutorial', 'learning', 'productivity'
        ]);
        // Sort alphabetically for consistent UI
        _allTags.sort();
      });
    } catch (e) {
      debugPrint('Tag extraction failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tags'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh tags',
            onPressed: _loadAllNotesAndExtractTags,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tag cloud / list
          Expanded(child: _buildTagList()),
        ],
      ),
    );
  }
}

Widget _buildTagList() {
  if (_allTags.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tag, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No tags yet', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('Type #tag in your notes to create tags'),
        ],
      ),
    );
  }

  return ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: _allTags.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final tag = _allTags[index];
      return _buildTagChip(context, tag);
    },
  );
}

Widget _buildTagChip(BuildContext context, String tag) {
  final isActive = _activeFilter == tag;
  
  // Hot tags (appear frequently across notes) get a stronger visual style
  final isHot = false; // TODO: calculate from note_count in database
  
  return InkWell(
    onTap: () {
      setState(() => _activeFilter = isActive ? null : tag);
      // Navigate to filtered notes list or show results
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isActive ? 'Cleared filter' : '#$tag')),
      );
    },
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blueGrey[300]
            : isHot // TODO: implement hot tag logic
                ? Colors.grey[100]
                : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow:
            isActive || isHot ? [BoxShadow(color: Colors.black12, blurRadius: 8)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag_rounded,
            color: isActive
                ? Colors.white70
                : isHot
                    ? Colors.blueGrey[500]
                    : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '#$tag',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHot || isActive ? 15 : 13,
              color:
                  isActive
                      ? Colors.white70
                      : isHot
                          ? Colors.blueGrey[800]
                          : Colors.grey[800],
            ),
          ),
          if (isHot) // TODO: show actual note count
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '142 notes',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    ),
  );
}
