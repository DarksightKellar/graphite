import 'package:flutter/material.dart';

import 'package:graphite/core/design/typography.dart';

/// A tappable wiki-link pill used in markdown preview.
///
/// Renders as a rounded pill with secondary-color background and underline,
/// matching the Graphite design system.
class GraphiteWikiLinkPill extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const GraphiteWikiLinkPill({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: scheme.secondary),
        ),
        child: Text(
          title,
          style: GraphiteTypography.body.copyWith(
            color: scheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
