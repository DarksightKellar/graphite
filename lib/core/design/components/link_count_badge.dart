import 'package:flutter/material.dart';

import 'package:graphite/core/design/typography.dart';

/// Small blue link-count badge used on note cards.
class LinkCountBadge extends StatelessWidget {
  final int count;

  const LinkCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.secondary.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 14, color: scheme.secondary),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GraphiteTypography.label.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
