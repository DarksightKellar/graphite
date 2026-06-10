import 'package:flutter/material.dart';

import 'package:graphite/core/design/spacing.dart';
import 'package:graphite/core/design/typography.dart';

/// Rounded filter chip used in horizontal tag filters.
class GraphiteFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool primary;
  final VoidCallback onTap;

  const GraphiteFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = primary ? scheme.secondary : scheme.tertiary;
    final foreground = selected && primary ? scheme.onSecondary : activeColor;
    final background = selected
        ? (primary ? activeColor : activeColor.withValues(alpha: 0.10))
        : scheme.surface;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GraphiteSpacing.inputRadius),
        side: BorderSide(
          color: selected ? activeColor : activeColor.withValues(alpha: 0.80),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GraphiteSpacing.inputRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: GraphiteTypography.bodyBold.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}
