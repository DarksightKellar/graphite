import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:graphite/core/design/components/tag_chip.dart';
import 'package:graphite/core/design/components/wiki_link.dart';

// ── Inline syntax definitions (flutter_markdown integration) ──────

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

class _TagSyntax extends md.InlineSyntax {
  _TagSyntax() : super(r'#[a-zA-Z0-9_-]+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('tag', match[0]!));
    return true;
  }
}

// ── Element builders (delegate to design-system components) ────────

class _WikiLinkBuilder extends MarkdownElementBuilder {
  final void Function(String title)? onTap;

  _WikiLinkBuilder({this.onTap});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final title = element.textContent;
    return GraphiteWikiLinkPill(
      title: title,
      onTap: onTap != null ? () => onTap!(title) : null,
    );
  }
}

class _TagBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return GraphiteTagChip(tag: element.textContent);
  }
}

// ── Preview pane ───────────────────────────────────────────────────

/// Renders markdown content with [[wiki-link]] and #tag support
/// via the Graphite design system.
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
          'wikilink': _WikiLinkBuilder(onTap: onLinkTap),
          'tag': _TagBuilder(),
        },
        inlineSyntaxes: [
          _WikiLinkSyntax(),
          _TagSyntax(),
        ],
      ),
    );
  }
}
