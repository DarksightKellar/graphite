import 'package:flutter/material.dart';

/// A #tag chip styled with tertiary (moss) color.
///
/// Used in markdown preview inside [WidgetSpan] and in the tag browser list.
class GraphiteTagChip extends StatelessWidget {
  final String tag;
  final double fontSize;

  const GraphiteTagChip({
    super.key,
    required this.tag,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      tag,
      style: TextStyle(
        color: scheme.tertiary,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
