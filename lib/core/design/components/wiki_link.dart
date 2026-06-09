import 'package:flutter/material.dart';

/// A tappable wiki-link pill used in markdown preview.
///
/// Renders as a rounded pill with secondary-color background and underline,
/// matching the Graphite design system.
class GraphiteWikiLinkPill extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const GraphiteWikiLinkPill({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: scheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: scheme.secondary.withValues(alpha: 0.3)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: scheme.secondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: scheme.secondary,
          ),
        ),
      ),
    );
  }
}
