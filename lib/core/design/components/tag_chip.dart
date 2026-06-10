import 'package:flutter/material.dart';

import 'package:graphite/core/design/typography.dart';

/// A #tag chip styled with tertiary (moss) color.
///
/// Used in markdown preview inside [WidgetSpan] and in the tag browser list.
class GraphiteTagChip extends StatelessWidget {
  final String tag;
  final double fontSize;

  const GraphiteTagChip({super.key, required this.tag, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      tag.startsWith('#') ? tag : '#$tag',
      style: GraphiteTypography.bodyBold.copyWith(
        color: scheme.tertiary,
        fontSize: fontSize,
      ),
    );
  }
}
