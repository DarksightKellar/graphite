import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:graphite/core/design/components/tag_chip.dart';
import 'package:graphite/core/design/components/wiki_link.dart';
import 'package:graphite/core/design/spacing.dart';
import 'package:graphite/core/design/typography.dart';

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

  const PreviewPane({super.key, required this.content, this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (content.isEmpty) {
      return Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.all(GraphiteSpacing.xxl),
        child: Center(
          child: Text(
            'No content to preview',
            style: GraphiteTypography.caption.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      );
    }

    return Container(
      color: colorScheme.surface,
      child: Markdown(
        padding: const EdgeInsets.fromLTRB(44, 44, 44, 32),
        data: content,
        selectable: true,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          h1: GraphiteTypography.markdownH1.copyWith(
            color: colorScheme.onSurface,
          ),
          h1Padding: const EdgeInsets.only(bottom: GraphiteSpacing.xs),
          h2: GraphiteTypography.markdownH2.copyWith(
            color: colorScheme.onSurface,
          ),
          h2Padding: const EdgeInsets.only(bottom: GraphiteSpacing.xs),
          h3: GraphiteTypography.markdownH3.copyWith(
            color: colorScheme.onSurface,
          ),
          h3Padding: const EdgeInsets.only(bottom: GraphiteSpacing.xs),
          h4: GraphiteTypography.markdownH4.copyWith(
            color: colorScheme.onSurface,
          ),
          h5: GraphiteTypography.markdownH5.copyWith(
            color: colorScheme.onSurface,
          ),
          h6: GraphiteTypography.markdownH6.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.78),
          ),
          p: GraphiteTypography.body.copyWith(color: colorScheme.onSurface),
          listBullet: GraphiteTypography.body.copyWith(
            color: colorScheme.onSurface,
          ),
          blockSpacing: GraphiteSpacing.sm,
        ),
        builders: {
          'wikilink': _WikiLinkBuilder(onTap: onLinkTap),
          'tag': _TagBuilder(),
        },
        inlineSyntaxes: [_WikiLinkSyntax(), _TagSyntax()],
      ),
    );
  }
}
