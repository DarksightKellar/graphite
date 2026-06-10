import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:graphite/core/design/typography.dart';
import 'package:graphite/features/editor/widgets/preview_pane.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PreviewPane', () {
    testWidgets('renders wiki-link as tappable text', (tester) async {
      String? tappedTitle;

      await tester.pumpWidget(
        wrap(
          PreviewPane(
            content: 'See [[My Note]] for details.',
            onLinkTap: (title) => tappedTitle = title,
          ),
        ),
      );

      expect(find.text('My Note'), findsOneWidget);

      await tester.tap(find.text('My Note'));
      await tester.pump();

      expect(tappedTitle, equals('My Note'));
    });

    testWidgets('shows empty state when content is empty', (tester) async {
      await tester.pumpWidget(wrap(const PreviewPane(content: '')));
      expect(find.text('No content to preview'), findsOneWidget);
    });

    testWidgets('renders heading via Markdown widget', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: '# Main Title\n\nSome content.')),
      );

      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('uses document-scale markdown heading styles', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PreviewPane(
            content: '# Main Title\n\n## Section\n\n### Detail',
          ),
        ),
      );

      final markdown = tester.widget<Markdown>(find.byType(Markdown));
      final styleSheet = markdown.styleSheet!;

      expect(styleSheet.h1!.fontSize, GraphiteTypography.markdownH1.fontSize);
      expect(styleSheet.h2!.fontSize, GraphiteTypography.markdownH2.fontSize);
      expect(styleSheet.h3!.fontSize, GraphiteTypography.markdownH3.fontSize);
      expect(styleSheet.h1!.fontSize, lessThan(40));
      expect(styleSheet.h1!.fontSize, greaterThan(styleSheet.h2!.fontSize!));
      expect(styleSheet.h2!.fontSize, greaterThan(styleSheet.h3!.fontSize!));
    });

    testWidgets('renders bold via Markdown widget', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: 'This is **bold** text.')),
      );

      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('renders italic via Markdown widget', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: 'This is *italic* text.')),
      );

      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('renders bullet list via Markdown widget', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: '- Item A\n- Item B')),
      );

      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('preserves paragraph breaks', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: 'hello\n\nworld')),
      );

      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('renders multiple wiki-links', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: 'See [[Note A]] and [[Note B]].')),
      );

      expect(find.text('Note A'), findsOneWidget);
      expect(find.text('Note B'), findsOneWidget);
    });

    testWidgets('handles empty brackets without crashing', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: 'Empty [[]] here.')),
      );

      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('renders #tags', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: 'Check #todo item.')),
      );

      expect(find.text('#todo'), findsOneWidget);
    });

    testWidgets('renders multiple #tags', (tester) async {
      await tester.pumpWidget(
        wrap(const PreviewPane(content: '#work #personal task.')),
      );

      expect(find.text('#work'), findsOneWidget);
      expect(find.text('#personal'), findsOneWidget);
    });
  });
}
