import 'package:flutter/material.dart';

import 'package:graphite/core/design/spacing.dart';

/// Standard elevated paper card used for note-like content.
class GraphiteCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const GraphiteCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.padding = GraphiteSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(GraphiteSpacing.cardRadius);

    return Card(
      elevation: selected ? 2 : 1,
      color: selected
          ? scheme.primary.withValues(alpha: 0.08)
          : theme.cardColor,
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
