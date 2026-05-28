import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// Custom inline syntax for [[wiki-links]].
class _WikiLinkSyntax extends md.InlineSyntax {
  _WikiLinkSyntax() : super(r'\[\[(.+?)\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final title = match[1]!.trim();
    if (title.isEmpty) return false;
    parser.addNode(md.Element.text('wikilink', title));
    return true;
  }
}

/// Builder for wiki-link elements — renders as a tappable pill.
class _WikiLinkBuilder extends MarkdownElementBuilder {
  final void Function(String title)? onTap;
  final ColorScheme colorScheme;

  _WikiLinkBuilder({this.onTap, required this.colorScheme});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final title = element.textContent;
    final scheme = colorScheme;
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(title) : null,
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

/// Custom inline syntax for #hashtags.
class _TagSyntax extends md.InlineSyntax {
  _TagSyntax() : super(r'#[a-zA-Z0-9_-]+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('tag', match[0]!));
    return true;
  }
}

/// Builder for #tag elements — tertiary color, medium weight.
class _TagBuilder extends MarkdownElementBuilder {
  final ColorScheme colorScheme;

  _TagBuilder({required this.colorScheme});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Text(
      element.textContent,
      style: TextStyle(
        color: colorScheme.tertiary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Renders markdown content with [[wiki-link]] and #tag support.
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

    return Container(
      color: colorScheme.surface,
      child: Markdown(
        data: content,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        builders: {
          'wikilink': _WikiLinkBuilder(
            onTap: onLinkTap,
            colorScheme: colorScheme,
          ),
          'tag': _TagBuilder(colorScheme: colorScheme),
        },
        inlineSyntaxes: [
          _WikiLinkSyntax(),
          _TagSyntax(),
        ],
      ),
    );
  }
}
