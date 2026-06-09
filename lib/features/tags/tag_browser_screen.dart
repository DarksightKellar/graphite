import 'package:flutter/material.dart';
import 'package:graphite/core/models/tag.dart';
import 'package:graphite/features/home/usecases/note_list_use_case.dart';

/// TagBrowserScreen — lists all tags with note counts, tappable to filter.
class TagBrowserScreen extends StatefulWidget {
  final NoteListUseCase noteListUseCase;

  const TagBrowserScreen({super.key, required this.noteListUseCase});

  @override
  State<TagBrowserScreen> createState() => _TagBrowserScreenState();
}

class _TagBrowserScreenState extends State<TagBrowserScreen> {
  late final NoteListUseCase _noteListUseCase;
  List<Tag> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _noteListUseCase = widget.noteListUseCase;
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _noteListUseCase.getAllTags();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
        // Use theme's AppBar styling, previously had transparent bg + white text bug
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tag_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.38)),
                      const SizedBox(height: 16),
                      Text(
                        'No tags found',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.60),
                        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Navigator.pop(context, tag.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.tag, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tag.id,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ),
            Text(
              '${tag.noteCount} note${tag.noteCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.50),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.38)),
          ],
        ),
      ),
    );
  }
}
