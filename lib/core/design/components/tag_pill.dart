import 'package:flutter/material.dart';

/// A rounded tag pill used in note cards and filter chips.
///
/// Matches the Graphite design system with a light border and subtle tint.
class GraphiteTagPill extends StatelessWidget {
  final String tag;

  const GraphiteTagPill({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.22)),
      ),
      child: Text(
        tag,
        style: TextStyle(color: scheme.tertiary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
