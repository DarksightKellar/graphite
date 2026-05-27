import 'package:flutter/material.dart';
import '../utils/markdown_parser.dart';

/// Renders markdown content in a modern, readable format.
/// [[wiki-links]] are rendered as tappable widgets.
class PreviewPane extends StatelessWidget {
  final String content;
  final void Function(String title)? onLinkTap;

  const PreviewPane({
    super.key,
    required this.content,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (content.isEmpty) {
      return Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No content to preview',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.38),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final spans = buildPreviewSpans(
      content,
      onLinkTap: onLinkTap,
      colorScheme: colorScheme,
    );

    return Container(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RichText(
          text: TextSpan(
            children: spans,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
