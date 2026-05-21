import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/utils/markdown_parser.dart';
import 'package:graphite/widgets/preview_pane.dart';

void main() {
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

    testWidgets('shows empty state when content is empty',
        (tester) async {
      await tester.pumpWidget(wrap(const PreviewPane(content: '')));
      expect(find.text('No content to preview'), findsOneWidget);
    });
  });
}
