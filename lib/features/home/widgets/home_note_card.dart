import 'package:flutter/material.dart';

import 'package:graphite/core/design/components/graphite_card.dart';
import 'package:graphite/core/design/components/link_count_badge.dart';
import 'package:graphite/core/design/components/tag_pill.dart';
import 'package:graphite/core/design/spacing.dart';
import 'package:graphite/core/design/typography.dart';
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
        final heading = first.substring(2).trim();
        if (heading.isNotEmpty) return heading;
      }
      if (first.startsWith('## ')) {
        final heading = first.substring(3).trim();
        if (heading.isNotEmpty) return heading;
      }
      if (first.isNotEmpty) {
        return first.length > 60 ? '${first.substring(0, 57)}...' : first;
      }
      for (var index = 1; index < lines.length; index += 1) {
        final candidate = lines[index];
        if (candidate.isNotEmpty) {
          return candidate.length > 60 ? '${candidate.substring(0, 57)}...' : candidate;
        }
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
    final tag = note.tags.isNotEmpty ? note.tags.first : null;

    return GraphiteCard(
      selected: isSelected,
      margin: const EdgeInsets.only(bottom: GraphiteSpacing.cardGap),
      onTap: onTap,
      onLongPress: selectionMode ? null : onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _title,
                  style: GraphiteTypography.title.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPinned) ...[
                const SizedBox(width: GraphiteSpacing.sm),
                Icon(Icons.push_pin, size: 18, color: scheme.secondary),
              ],
            ],
          ),
          if (_subtitle.isNotEmpty) ...[
            const SizedBox(height: GraphiteSpacing.xs),
            Text(
              _subtitle,
              style: GraphiteTypography.body.copyWith(color: scheme.onSurface.withValues(alpha: 0.62)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: GraphiteSpacing.lg),
          Row(
            children: [
              Text(
                _formatDate(note.updatedAt),
                style: GraphiteTypography.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.62)),
              ),
              _MetadataDot(color: scheme.onSurface.withValues(alpha: 0.62)),
              Text(
                '$_wordCount words',
                style: GraphiteTypography.caption.copyWith(color: scheme.onSurface.withValues(alpha: 0.62)),
              ),
              if (linkCount > 0) ...[const SizedBox(width: GraphiteSpacing.md), LinkCountBadge(count: linkCount)],
              if (tag != null) ...[const Spacer(), GraphiteTagPill(tag: tag)],
            ],
          ),
        ],
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

class _MetadataDot extends StatelessWidget {
  final Color color;

  const _MetadataDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GraphiteSpacing.md),
      child: Text('•', style: GraphiteTypography.caption.copyWith(color: color)),
    );
  }
}
