import 'package:flutter/material.dart';

import 'package:graphite/core/design/components/tag_pill.dart';
import 'package:graphite/core/models/note.dart';

/// A styled note card for the HomeScreen.
class HomeNoteCard extends StatelessWidget {
  final Note note;
  final bool isPinned;
  final bool isSelected;
  final int linkCount;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const HomeNoteCard({
    super.key,
    required this.note,
    required this.isPinned,
    required this.isSelected,
    required this.linkCount,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  String get _title {
    final lines = note.content.split('\n').map((line) => line.trim()).toList();
    if (lines.isNotEmpty) {
      final first = lines.first;
      if (first.startsWith('# ')) {
        return first.substring(2);
      }
      if (first.startsWith('## ')) {
        return first.substring(3);
      }
      if (first.isNotEmpty) {
        return first.length > 60 ? '${first.substring(0, 57)}...' : first;
      }
    }
    return note.path;
  }

  String get _subtitle {
    final lines = note.content.split('\n').map((line) => line.trim()).toList();
    if (lines.isEmpty) return '';

    final first = lines.first;
    if (first.startsWith('# ')) {
      for (var index = 1; index < lines.length; index += 1) {
        final candidate = lines[index];
        if (candidate.isNotEmpty) {
          return candidate.length > 100 ? '${candidate.substring(0, 97)}...' : candidate;
        }
      }
    }

    return '';
  }

  int get _wordCount {
    return note.content.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tag = note.tags.isNotEmpty ? '#${note.tags.first}' : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isSelected ? scheme.primary.withValues(alpha: 0.08) : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: selectionMode ? null : onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _title,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPinned) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.push_pin, size: 16, color: scheme.secondary),
                            ],
                          ],
                        ),
                        if (_subtitle.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface.withValues(alpha: 0.64),
                              height: 1.4,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _formatDate(note.updatedAt),
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(width: 6),
                  Text('•', style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(width: 6),
                  Text(
                    '$_wordCount words',
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                  if (linkCount > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 12, color: scheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '$linkCount',
                            style: TextStyle(fontSize: 11, color: scheme.secondary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (tag != null) ...[
                    const Spacer(),
                    GraphiteTagPill(tag: tag),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[date.month - 1];

    if (date.year == now.year) {
      return '$monthStr ${date.day}';
    }
    return '$monthStr ${date.day}, ${date.year}';
  }
}
