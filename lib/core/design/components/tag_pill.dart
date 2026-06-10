import 'package:flutter/material.dart';

import 'package:graphite/core/design/typography.dart';

/// A rounded tag pill used in note cards and filter chips.
///
/// Matches the Graphite design system with a light border and subtle tint.
class GraphiteTagPill extends StatelessWidget {
  final String tag;
  final bool filled;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  const GraphiteTagPill({
    super.key,
    required this.tag,
    this.filled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = tag.startsWith('#') ? tag : '#$tag';

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: filled
            ? scheme.tertiary
            : scheme.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: filled
            ? null
            : Border.all(color: scheme.tertiary.withValues(alpha: 0.60)),
      ),
      child: Text(
        label,
        style: (textStyle ?? GraphiteTypography.caption).copyWith(
          color: filled ? scheme.onTertiary : scheme.tertiary,
          fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
