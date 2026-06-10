import 'package:flutter/material.dart';

import 'package:graphite/core/design/components/graphite_filter_chip.dart';
import 'package:graphite/core/design/spacing.dart';
import 'package:graphite/core/models/tag.dart';

/// Horizontal tag filter row for the HomeScreen.
class HomeTagFilterBar extends StatelessWidget {
  final List<Tag> tags;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;

  const HomeTagFilterBar({
    super.key,
    required this.tags,
    required this.selectedTag,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          GraphiteSpacing.pageInset,
          0,
          GraphiteSpacing.pageInset,
          GraphiteSpacing.lg,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: GraphiteSpacing.lg),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = selectedTag == null;
            return GraphiteFilterChip(
              label: 'All',
              selected: selected,
              primary: true,
              onTap: () => onTagSelected(null),
            );
          }

          final tag = tags[index - 1];
          final label = tag.id.startsWith('#') ? tag.id : '#${tag.id}';
          final selected = selectedTag == tag.id;

          return GraphiteFilterChip(
            label: label,
            selected: selected,
            onTap: () => onTagSelected(tag.id),
          );
        },
      ),
    );
  }
}
