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
    if (content.isEmpty) {
      return Container(
        color: const Color(0xFFF5F6FA),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No content to preview',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      );
    }

    final spans = buildPreviewSpans(content, onLinkTap: onLinkTap);

    return Container(
      color: const Color(0xFFF5F6FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RichText(
          text: TextSpan(
            children: spans,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
