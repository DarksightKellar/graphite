import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/utils/markdown_parser.dart';
import 'package:graphite/widgets/preview_pane.dart';

void main() {
  group('extractWikiLinks', () {
    test('extracts single [[Title]] from markdown', () {
      final result = extractWikiLinks('See [[My Note]] for details.');
      expect(result, equals(['My Note']));
    });

    test('extracts multiple [[links]] from markdown', () {
      final result = extractWikiLinks(
        'See [[Note A]] and [[Note B]] for info.',
      );
      expect(result, equals(['Note A', 'Note B']));
    });

    test('extracts links with special characters in title', () {
      final result = extractWikiLinks(
        'Link to [[Project: Ideas]] and [[2024-Q1 Report]]',
      );
      expect(result, equals(['Project: Ideas', '2024-Q1 Report']));
    });

    test('ignores empty brackets [[]]', () {
      final result = extractWikiLinks('Empty [[]] should not be a link.');
      expect(result, isEmpty);
    });

    test('ignores whitespace-only brackets [[   ]]', () {
      final result = extractWikiLinks('Blank [[   ]] is not valid.');
      expect(result, isEmpty);
    });

    test('ignores escaped brackets', () {
      final result = extractWikiLinks(
        r'This \[[escaped]] is not a link but [[real]] is.',
      );
      expect(result, equals(['real']));
    });

    test('handles nested brackets gracefully', () {
      final result = extractWikiLinks('Nested [[[inner]]] brackets.');
      expect(result, equals(['[inner']));
    });

    test('trims whitespace from extracted titles', () {
      final result = extractWikiLinks('Link to [[  spaced title  ]] here.');
      expect(result, equals(['spaced title']));
    });

    test('returns empty list when no links present', () {
      final result = extractWikiLinks('Just plain text with no links.');
      expect(result, isEmpty);
    });

    test('extracts links across multiple lines', () {
      final result = extractWikiLinks(
        '# Heading\n\nSee [[Page One]].\n\nAlso check [[Page Two]].',
      );
      expect(result, equals(['Page One', 'Page Two']));
    });

    test('extracts duplicate titles', () {
      final result = extractWikiLinks('[[same]] and [[same]] again.');
      expect(result, equals(['same', 'same']));
    });

    test('handles single bracket inside double brackets', () {
      final result = extractWikiLinks('Edge case [[a]b]] end.');
      expect(result, equals(['a]b']));
    });

    test('extracts links from code block content (not parsed as code here)', () {
      final result = extractWikiLinks('```\n[[code-link]]\n```');
      expect(result, equals(['code-link']));
    });
  });

  group('extractTags', () {
    test('extracts single #tag from text', () {
      final result = extractTags('My note about #work things.');
      expect(result, equals(['#work']));
    });

    test('extracts multiple #tags from text', () {
      final result = extractTags('Shopping list #groceries #urgent');
      expect(result, equals(['#groceries', '#urgent']));
    });

    test('extracts tags with underscores and hyphens', () {
      final result = extractTags('See #my_tag and #project-ideas here.');
      expect(result, equals(['#my_tag', '#project-ideas']));
    });

    test('returns empty list when no tags present', () {
      final result = extractTags('Just plain text without any hashtags.');
      expect(result, isEmpty);
    });

    test('extracts tag at start of line', () {
      final result = extractTags('#todo Buy milk\n#done Laundry');
      expect(result, equals(['#todo', '#done']));
    });
  });

  group('parseMarkdown inline highlighting', () {
    test('wiki-link in text line produces wiki-link span type', () {
      final spans = parseMarkdown('See [[My Note]] here.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      final hasWikiLink = children!.any((s) {
        if (s is TextSpan) {
          return s.style?.color == Colors.blue &&
              s.style?.decoration == TextDecoration.underline;
        }
        return false;
      });
      expect(hasWikiLink, isTrue);
    });

    test('#tag in text line produces tag span type', () {
      final spans = parseMarkdown('Check #todo item.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      final hasTag = children!.any((s) {
        if (s is TextSpan) {
          return s.style?.color == Colors.green;
        }
        return false;
      });
      expect(hasTag, isTrue);
    });

    test('bold (**text**) renders with bold font weight', () {
      final spans = parseMarkdown('This is **bold** text.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      final hasBold = children!.any((s) {
        if (s is TextSpan) {
          return s.style?.fontWeight == FontWeight.bold;
        }
        return false;
      });
      expect(hasBold, isTrue);
    });

    test('italic (*text*) renders with italic font style', () {
      final spans = parseMarkdown('This is *italic* text.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      final hasItalic = children!.any((s) {
        if (s is TextSpan) {
          return s.style?.fontStyle == FontStyle.italic;
        }
        return false;
      });
      expect(hasItalic, isTrue);
    });

    test('code block (```...```) renders with monospace background', () {
      final spans = parseMarkdown('```\ncode here\n```');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      final hasCode = children!.any((s) {
        if (s is TextSpan) {
          return s.style?.fontFamily == 'monospace';
        }
        return false;
      });
      expect(hasCode, isTrue);
    });

    test('unordered list (- item) renders as bulleted', () {
      final spans = parseMarkdown('- First item\n- Second item');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      // At least one item with bullet prefix
      final hasBullet = children!.any((s) {
        if (s is TextSpan && s.text != null) {
          return s.text!.contains('\u2022');
        }
        return false;
      });
      expect(hasBullet, isTrue);
    });

    test('handles bold mixed with italic in same line', () {
      final spans = parseMarkdown('Mix **bold** and *italic* together.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      final hasBold = children!.any((s) {
        if (s is TextSpan) {
          return s.style?.fontWeight == FontWeight.bold;
        }
        return false;
      });
      final hasItalic = children.any((s) {
        if (s is TextSpan) {
          return s.style?.fontStyle == FontStyle.italic;
        }
        return false;
      });
      expect(hasBold, isTrue);
      expect(hasItalic, isTrue);
    });

    test('H3 heading (###) renders with heading type', () {
      final spans = parseMarkdown('### Section Name\n\nContent.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      // The first span should be a heading with level 3
      final headings = children!
          .where((s) => s is TextSpan && s.style?.fontSize == 18);
      expect(headings, isNotEmpty);
    });

    test('H2 heading (##) produces heading span', () {
      final spans = parseMarkdown('## Subtitle\n\nText.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      final headings = children!
          .where((s) => s is TextSpan && s.style?.fontSize == 22);
      expect(headings, isNotEmpty);
    });

    test('ordered list (1. item) produces list span', () {
      final spans = parseMarkdown('1. First item\n2. Second item');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      expect(children, isNotNull);
      final hasBullet = children!.any((s) {
        if (s is TextSpan && s.text != null) {
          return s.text!.contains('\u2022');
        }
        return false;
      });
      expect(hasBullet, isTrue);

      // Verify both items are present
      final bulletSpans = children
          .where((s) => s is TextSpan && s.text != null && s.text!.contains('\u2022'))
          .toList();
      expect(bulletSpans.length, equals(2));
    });

    test('handles empty input', () {
      final spans = parseMarkdown('');
      expect(spans, isNotEmpty);
      // Empty input produces a TextSpan with empty or null children
      final children = spans.first.children;
      if (children != null) {
        expect(children, isEmpty);
      }
    });

    test('handles whitespace-only input', () {
      final spans = parseMarkdown('   \n  \n  ');
      expect(spans, isNotEmpty);
    });

    test('handles unclosed code block (treated as code until EOF)', () {
      final spans = parseMarkdown('```\nunclosed code block');
      expect(spans, isNotEmpty);
    });

    test('handles bold spanning multiple words', () {
      final spans = parseMarkdown('This is **very bold text** here.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      final hasBold = children!.any((s) {
        if (s is TextSpan) {
          return s.style?.fontWeight == FontWeight.bold &&
              s.text == 'very bold text';
        }
        return false;
      });
      expect(hasBold, isTrue);
    });

    test('handles italic with single character', () {
      final spans = parseMarkdown('Italic *a* single letter.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      final hasItalic = children!.any((s) {
        if (s is TextSpan) {
          return s.style?.fontStyle == FontStyle.italic && s.text == 'a';
        }
        return false;
      });
      expect(hasItalic, isTrue);
    });

    test('handles multiple hashtags in one line (#work #personal)', () {
      final spans = parseMarkdown('Tags #work #personal here.');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      final tagSpans = children!
          .where((s) => s is TextSpan && s.style?.color == Colors.green)
          .toList();
      expect(tagSpans.length, equals(2));
    });

    test('handles multiple wiki-links in one line', () {
      final spans = parseMarkdown('See [[Note A]] and [[Note B]].');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      final wikiSpans = children!
          .where((s) =>
              s is TextSpan &&
              s.style?.color == Colors.blue &&
              s.style?.decoration == TextDecoration.underline)
          .toList();
      expect(wikiSpans.length, equals(2));
    });

    test('unordered list with asterisk (*)', () {
      final spans = parseMarkdown('* Item A\n* Item B');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      final bulletCount = children!
          .where((s) => s is TextSpan && s.text != null && s.text!.contains('\u2022'))
          .length;
      expect(bulletCount, equals(2));
    });

    test('unordered list with plus sign (+)', () {
      final spans = parseMarkdown('+ Item A\n+ Item B');
      expect(spans, isNotEmpty);
      final children = spans.first.children;
      final bulletCount = children!
          .where((s) => s is TextSpan && s.text != null && s.text!.contains('\u2022'))
          .length;
      expect(bulletCount, equals(2));
    });

    test('skips blank lines between content', () {
      final spans = parseMarkdown(
        '# Title\n\n\n\n## Subtitle\n\n\nContent.',
      );
      expect(spans, isNotEmpty);
    });

    test('heading with level >3 not parsed as heading', () {
      final spans = parseMarkdown('#### Not A Heading\n\nText.');
      expect(spans, isNotEmpty);
      // #### should be treated as regular text, not a heading
      final children = spans.first.children;
      if (children != null) {
        // Should not find a heading in the H1-H3 size range
        final largeTexts = children.where((s) {
          if (s is TextSpan && s.text != null) {
            return s.text!.contains('####');
          }
          return false;
        });
        expect(largeTexts, isNotEmpty);
      }
    });
  });

  group('buildPreviewSpans', () {
    test('produces WidgetSpan for [[wiki-link]]', () {
      final spans = buildPreviewSpans('See [[My Note]] here.');
      final hasWidgetSpan = spans.any((s) => s is WidgetSpan);
      expect(hasWidgetSpan, isTrue);
    });

    test('produces TextSpan for text without links', () {
      final spans = buildPreviewSpans('Just plain text.');
      final allTextSpans = spans.every((s) => s is TextSpan);
      expect(allTextSpans, isTrue);
    });

    test('handles multiple wiki-links in one line', () {
      final spans = buildPreviewSpans('[[A]] and [[B]].');
      final widgetSpans = spans.whereType<WidgetSpan>();
      expect(widgetSpans.length, equals(2));
    });

    test('handles headings without breaking', () {
      final spans =
          buildPreviewSpans('# Heading\n\nText with [[Link]].');
      expect(spans.length, greaterThanOrEqualTo(2));
    });

    test('handles escaped brackets as plain text', () {
      final spans = buildPreviewSpans(r'This \[[escaped]] is text.');
      final widgetSpans = spans.whereType<WidgetSpan>();
      expect(widgetSpans, isEmpty);
    });

    test('skips empty brackets', () {
      final spans = buildPreviewSpans('Empty [[]] here.');
      final widgetSpans = spans.whereType<WidgetSpan>();
      expect(widgetSpans, isEmpty);
    });

    test('renders bold text with bold style', () {
      final spans = buildPreviewSpans('This is **bold** text.');
      final hasBold = spans.any((s) {
        if (s is TextSpan) {
          return s.style?.fontWeight == FontWeight.bold;
        }
        return false;
      });
      expect(hasBold, isTrue);
    });

    test('renders italic text with italic style', () {
      final spans = buildPreviewSpans('This is *italic* text.');
      final hasItalic = spans.any((s) {
        if (s is TextSpan) {
          return s.style?.fontStyle == FontStyle.italic;
        }
        return false;
      });
      expect(hasItalic, isTrue);
    });

    test('renders code block with monospace', () {
      final spans = buildPreviewSpans('```\ncode block\n```');
      final hasMonospace = spans.any((s) {
        if (s is TextSpan) {
          return s.style?.fontFamily == 'monospace';
        }
        return false;
      });
      expect(hasMonospace, isTrue);
    });

    test('renders unordered list with bullets', () {
      final spans = buildPreviewSpans('- First item\n- Second item');
      final hasBullet = spans.any((s) {
        if (s is TextSpan && s.text != null) {
          return s.text!.contains('\u2022');
        }
        return false;
      });
      expect(hasBullet, isTrue);
    });

    test('handles very long content without crashing', () {
      final longText = 'long text ' * 500;
      final spans = buildPreviewSpans(longText);
      expect(spans, isNotEmpty);
    });

    test('handles special characters correctly', () {
      final spans = buildPreviewSpans('Special chars: @#%^&*()[]{}');
      expect(spans, isNotEmpty);
    });

    test('renders #tag with green color', () {
      final spans = buildPreviewSpans('Check #todo item.');
      final hasTag = spans.any((s) {
        if (s is TextSpan) {
          return s.style?.color == Colors.green;
        }
        return false;
      });
      expect(hasTag, isTrue);
    });

    test('handles ordered list (1. item) in preview', () {
      final spans = buildPreviewSpans('1. First item\n2. Second item');
      // Ordered lists now render with their actual numbers (e.g., "1. ", "2. ")
      final numberedCount = spans
          .where((s) => s is TextSpan && s.text != null &&
              RegExp(r'^\d+\.').hasMatch(s.text!))
          .length;
      expect(numberedCount, equals(2));
    });

    test('H3 heading (###) renders as heading in preview', () {
      final spans = buildPreviewSpans('### Section\n\nContent.');
      expect(spans.length, greaterThanOrEqualTo(2));
    });

    test('handles bold text correctly in preview', () {
      final spans = buildPreviewSpans('This is **bold** content.');
      final hasBold = spans.any((s) {
        if (s is TextSpan) {
          return s.style?.fontWeight == FontWeight.bold;
        }
        return false;
      });
      expect(hasBold, isTrue);
    });
  });

  group('PreviewPane widget', () {
    Widget wrap(Widget child) => MaterialApp(
          home: Scaffold(body: child),
        );

    testWidgets('renders wiki-link as tappable text', (tester) async {
      String? tappedTitle;

      await tester.pumpWidget(wrap(PreviewPane(
        content: 'See [[My Note]] for details.',
        onLinkTap: (title) => tappedTitle = title,
      )));

      expect(find.text('My Note'), findsOneWidget);

      await tester.tap(find.text('My Note'));
      await tester.pump();

      expect(tappedTitle, equals('My Note'));
    });

    testWidgets('shows empty state when content is empty', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const PreviewPane(content: '')));
      expect(find.text('No content to preview'), findsOneWidget);
    });

    testWidgets('renders bold markdown', (tester) async {
      await tester.pumpWidget(wrap(const PreviewPane(
        content: 'This is **bold** text.',
      )));

      // RichText should render with content
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders italic markdown', (tester) async {
      await tester.pumpWidget(wrap(const PreviewPane(
        content: 'This is *italic* text.',
      )));

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders headings correctly', (tester) async {
      await tester.pumpWidget(wrap(const PreviewPane(
        content: '# Main Title\n\nSome content.',
      )));

      expect(find.byType(RichText), findsOneWidget);
    });
  });
}
