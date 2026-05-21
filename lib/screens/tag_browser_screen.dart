import 'package:flutter/material.dart';
import '../data/database.dart';
import '../models/tag.dart';

/// TagBrowserScreen — lists all tags with note counts, tappable to filter.
class TagBrowserScreen extends StatefulWidget {
  /// Optional injected database for testing. When null, creates a real [GraphiteDB].
  final GraphiteDB? db;

  const TagBrowserScreen({super.key, this.db});

  @override
  State<TagBrowserScreen> createState() => _TagBrowserScreenState();
}

class _TagBrowserScreenState extends State<TagBrowserScreen> {
  late final GraphiteDB db;
  List<Tag> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    db = widget.db ?? GraphiteDB();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await db.getAllTags();
      if (!mounted) return;
      setState(() {
        _tags = tags;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load tags: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tag_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No tags found',
                        style:
                            TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tags.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tag = _tags[index];
                    return _buildTagRow(tag);
                  },
                ),
    );
  }

  Widget _buildTagRow(Tag tag) {
    return InkWell(
      onTap: () => Navigator.pop(context, tag.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.tag, color: Colors.blueGrey[700], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tag.id,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
            Text(
              '${tag.noteCount} note${tag.noteCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
