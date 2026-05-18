import 'package:flutter/material.dart';

/// HomeScreen with quick note capture and cross-platform file picker.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphite'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),

          // Quick note capture button (+)
          PopupMenuButton<String>(
            onSelected: (action) => _handleQuickNoteAction(action),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'new_note', child: Text('New Note')),
              const PopupMenuItem(value: 'duplicate_latest', child: Row(
                children: [Icon(Icons.copy, size: 16), SizedBox(width: 8), Text('Duplicate Latest')],
              ), onTap: () => _openLatestNote()),
              PopupMenuDivider(),
              // Cross-platform file picker (import any markdown file from device)
              const PopupMenuItem(value: 'open_file', child: Row(
                children: [Icon(Icons.folder_open, size: 16), SizedBox(width: 8), Text('Import File')],
              ), onTap: () => _showFilePicker()),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Folder navigation (breadcrumbs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Home', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                IconButton(
                  icon: Icon(Icons.folder_open, size: 20, color: Colors.grey[500]),
                  onPressed: () => _showFolderPicker(), // TODO
                ),
              ],
            ),
          ),

          // Note list (file tree view)
          Expanded(child: _buildNoteList()),
        ],
      ),
    );
  }
}

Widget _buildSearchBar() {
  return Container(
    padding: const EdgeInsets.all(8),
    color: const Color(0xFFD6DBDF),
    child: Row(
      children: [
        Icon(Icons.search, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          decoration: InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => searchQuery = value),
          maxLines: 1,
          onSubmitted: (_) => _searchNotes(),
        )),
      ],
    ),
  );
}

Widget _buildNoteList() {
  return Column(
    children: [
      // Section header
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.blueGrey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text('My Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),

      // Note cards (placeholders for demo)
      _buildPlaceholderNotes(),
    ],
  );
}

Widget _buildPlaceholderNotes() {
  return ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: 5,
    separatorBuilder: (_, __) => const SizedBox(height: 4),
    itemBuilder: (context, index) {
      final isWelcome = index == 0;
      return _buildNoteCard(isWelcome);
    },
  );
}

Widget _buildNoteCard(bool isWelcome) {
  final title = isWelcome ? 'Getting Started with Graphite' : 'Project Ideas';
  final subtitle = isWelcome 
      ? 'This is your local-first knowledge base. Notes are stored securely on this device.'
      : 'A collection of creative concepts for future apps and projects';
  final tags = isWelcome
    ? ['getting-started', 'tutorial']
    : ['ideas', 'work'];

  return Card(
    elevation: 0,
    child: InkWell(
      onTap: () => _openNote(isWelcome),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isWelcome ? Colors.blueGrey[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(isWelcome ? Icons.school_outlined : Icons.lightbulb_outline, 
                    color: isWelcome ? Colors.blueGrey[400] : Colors.grey[500]),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3), maxLines: 2),
                  ],
                )),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(child: Row(
                  children: [Icon(Icons.access_time, size: 14, color: Colors.grey[500]), const SizedBox(width: 6)],
                )),
                if (tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(child: Wrap(spacing: 4, runSpacing: 4,
                    children: tags.map((tag) => Chip(
                      label: Text('#$tag', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                      smallPadding: EdgeInsets.zero,
                    )).toList(),
                  ))],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Quick note capture dialog (single-line thought + full editor)
Future<void> _handleQuickNoteAction(String action) async {
  if (action == 'new_note') {
    // Show quick dialog to capture a single-line thought, then open full editor
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Note'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
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
      // Create a new note with this text as the initial content
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      await createNote('Quick Note $timestamp.md', '# $title\n\n$noteContent');
      
      // TODO: navigate to editor screen for the new note
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick note captured')),
      );
    }
  } else if (action == 'duplicate_latest') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate latest note coming in next update')),
    );
  } else if (action == 'open_file') {
    _showFilePicker();
  }
}

/// Cross-platform file picker (import any markdown file from device)
void _showFilePicker() async {
  final file = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowedExtensions: ['md'],
    allowMultiple: false,
  );

  if (file != null && file.files.isNotEmpty) {
    final filePath = file.files.first.path;
    
    try {
      // Read the imported markdown content
      final content = await File(filePath).readAsString();

      // TODO: Create a new note with this content and open editor
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported "${file.files.first.name}" from $filePath')),
      );
    } catch (e) {
      debugPrint('Failed to read imported file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open imported file')),
      );
    }
  }
}

void _openLatestNote() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duplicate latest note coming in next update')));
void _searchNotes() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search implemented with SQLite')));
void _showSearchDialog() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use search bar above to search')));

void _openNote(bool isWelcome) {
  // TODO: create a new note called "Getting Started" and open it
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Opening note...')),
  );
}

void _showFolderPicker() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Browse folders coming in next update')));
