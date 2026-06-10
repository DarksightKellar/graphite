import 'package:flutter/material.dart';
import 'package:graphite/core/design/components/tag_pill.dart';
import 'package:graphite/core/design/spacing.dart';
import 'package:graphite/core/design/typography.dart';
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
      appBar: AppBar(title: const Text('Tags')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tag_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
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
              padding: const EdgeInsets.fromLTRB(
                GraphiteSpacing.pageInset,
                38,
                GraphiteSpacing.pageInset,
                GraphiteSpacing.xxl,
              ),
              itemCount: _tags.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: GraphiteSpacing.xl)
                  : Divider(height: 32, color: colorScheme.outline),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    'ALL TAGS',
                    style: GraphiteTypography.overline.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                final tag = _tags[index - 1];
                return _buildTagRow(tag);
              },
            ),
    );
  }

  Widget _buildTagRow(Tag tag) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Navigator.pop(context, tag.id),
      borderRadius: BorderRadius.circular(GraphiteSpacing.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GraphiteSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 142,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GraphiteTagPill(
                  tag: tag.id,
                  filled: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  textStyle: GraphiteTypography.title,
                ),
              ),
            ),
            const SizedBox(width: GraphiteSpacing.xl),
            Text(
              '${tag.noteCount} note${tag.noteCount == 1 ? '' : 's'}',
              style: GraphiteTypography.body.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
