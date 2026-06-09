import 'package:flutter/material.dart';

import 'package:graphite/core/models/tag.dart';

/// Horizontal tag filter row for the HomeScreen.
class HomeTagFilterBar extends StatelessWidget {
  final List<Tag> tags;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;

  const HomeTagFilterBar({super.key, required this.tags, required this.selectedTag, required this.onTagSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = selectedTag == null;
            return ChoiceChip(
              label: const Text('All'),
              selected: selected,
              selectedColor: scheme.secondary,
              backgroundColor: scheme.surface,
              labelStyle: TextStyle(color: selected ? scheme.onSecondary : scheme.onSurface, fontWeight: FontWeight.w600),
              side: BorderSide(color: selected ? scheme.secondary : scheme.outline),
              onSelected: (_) => onTagSelected(null),
            );
          }

          final tag = tags[index - 1];
          final label = '#${tag.id}';
          final selected = selectedTag == tag.id;

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            selectedColor: selected ? scheme.tertiary.withValues(alpha: 0.14) : scheme.surface,
            backgroundColor: scheme.surface,
            labelStyle: TextStyle(color: selected ? scheme.tertiary : scheme.tertiary, fontWeight: FontWeight.w600),
            side: BorderSide(color: selected ? scheme.tertiary : scheme.tertiary.withValues(alpha: 0.4)),
            onSelected: (_) => onTagSelected(tag.id),
          );
        },
      ),
    );
  }
}
