import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/core/design/typography.dart';
import 'package:graphite/features/editor/widgets/editor_pane.dart';

void main() {
  group('EditorPane', () {
    testWidgets('accepts a TextEditingController', (tester) async {
      final controller = TextEditingController(text: '# Hello\n\nWorld');
      await tester.pumpWidget(
        _wrapWithMaterialApp(EditorPane(controller: controller)),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(controller.text, equals('# Hello\n\nWorld'));
    });

    testWidgets('uses monospace font for editor text', (tester) async {
      final controller = TextEditingController(text: 'code');
      await tester.pumpWidget(
        _wrapWithMaterialApp(EditorPane(controller: controller)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final style = textField.style;
      expect(style, isNotNull);
      expect(style!.fontFamily, isNotNull);
    });

    testWidgets('calls onChanged when text is modified', (tester) async {
      String? changedText;
      final controller = TextEditingController(text: 'initial');
      await tester.pumpWidget(
        _wrapWithMaterialApp(
          EditorPane(
            controller: controller,
            onChanged: (text) => changedText = text,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'updated');
      expect(changedText, equals('updated'));
    });

    testWidgets('inline markdown controller preserves markdown text', (
      tester,
    ) async {
      final controller = InlineMarkdownEditingController(
        text: '# Title\n\nA **bold** [[Link]] with #tag',
      );
      await tester.pumpWidget(
        _wrapWithMaterialApp(EditorPane(controller: controller)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        style: textField.style,
        withComposing: false,
      );

      expect(span.toPlainText(), equals(controller.text));
      expect(span.toPlainText(), contains('[[Link]]'));
      expect(span.toPlainText(), contains('#tag'));
    });

    testWidgets('inline markdown controller styles wiki links and tags', (
      tester,
    ) async {
      final controller = InlineMarkdownEditingController(
        text: 'See [[Roadmap]] and #planning',
      );
      await tester.pumpWidget(
        _wrapWithMaterialApp(EditorPane(controller: controller)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        style: textField.style,
        withComposing: false,
      );
      final childSpans = span.children!.whereType<TextSpan>().toList();

      final link = childSpans.firstWhere((child) => child.text == 'Roadmap');
      final tag = childSpans.firstWhere((child) => child.text == '#planning');

      expect(link.style!.decoration, TextDecoration.underline);
      expect(tag.style!.fontWeight, FontWeight.w600);
    });

    testWidgets('inline markdown controller uses document body typography', (
      tester,
    ) async {
      final controller = InlineMarkdownEditingController(text: 'plain body');
      await tester.pumpWidget(
        _wrapWithMaterialApp(EditorPane(controller: controller)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        style: textField.style,
        withComposing: false,
      );
      final body = span.children!.whereType<TextSpan>().first;

      expect(body.style!.fontSize, GraphiteTypography.body.fontSize);
      expect(body.style!.fontFamily, GraphiteTypography.fontFamily);
    });

    testWidgets('inline markdown controller styles additional inline syntax', (
      tester,
    ) async {
      final controller = InlineMarkdownEditingController(
        text:
            'Use `code`, __bold__, _italic_, ~~old~~, ==mark==, and [site](https://example.com).',
      );
      await tester.pumpWidget(
        _wrapWithMaterialApp(EditorPane(controller: controller)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        style: textField.style,
        withComposing: false,
      );
      final childSpans = span.children!.whereType<TextSpan>().toList();

      final code = childSpans.firstWhere((child) => child.text == 'code');
      final bold = childSpans.firstWhere((child) => child.text == 'bold');
      final italic = childSpans.firstWhere((child) => child.text == 'italic');
      final strike = childSpans.firstWhere((child) => child.text == 'old');
      final highlight = childSpans.firstWhere((child) => child.text == 'mark');
      final link = childSpans.firstWhere((child) => child.text == 'site');

      expect(code.style!.fontFamily, GraphiteTypography.mono.fontFamily);
      expect(bold.style!.fontWeight, FontWeight.w700);
      expect(italic.style!.fontStyle, FontStyle.italic);
      expect(strike.style!.decoration, TextDecoration.lineThrough);
      expect(highlight.style!.backgroundColor, isNotNull);
      expect(link.style!.decoration, TextDecoration.underline);
      expect(span.toPlainText(), equals(controller.text));
    });

    testWidgets('inline markdown controller styles block syntax', (
      tester,
    ) async {
      final controller = InlineMarkdownEditingController(
        text:
            '> Quote\n- [x] Done\n- [ ] Todo\n---\n```dart\nfinal x = 1;\n```',
      );
      await tester.pumpWidget(
        _wrapWithMaterialApp(EditorPane(controller: controller)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        style: textField.style,
        withComposing: false,
      );
      final childSpans = span.children!.whereType<TextSpan>().toList();

      final quote = childSpans.firstWhere((child) => child.text == 'Quote');
      final done = childSpans.firstWhere((child) => child.text == 'Done');
      final todo = childSpans.firstWhere((child) => child.text == 'Todo');
      final code = childSpans.firstWhere(
        (child) => child.text == 'final x = 1;',
      );
      final rule = childSpans.firstWhere((child) => child.text == '---');

      expect(quote.style!.fontStyle, FontStyle.italic);
      expect(done.style!.decoration, TextDecoration.lineThrough);
      expect(todo.style!.decoration, isNot(TextDecoration.lineThrough));
      expect(code.style!.fontFamily, GraphiteTypography.mono.fontFamily);
      expect(rule.style!.color, isNot(GraphiteTypography.body.color));
      expect(span.toPlainText(), equals(controller.text));
    });

    testWidgets('inline markdown controller sizes heading levels', (
      tester,
    ) async {
      final controller = InlineMarkdownEditingController(
        text: '# Main\n## Section\n### Detail',
      );
      await tester.pumpWidget(
        _wrapWithMaterialApp(EditorPane(controller: controller)),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        style: textField.style,
        withComposing: false,
      );
      final childSpans = span.children!.whereType<TextSpan>().toList();

      final h1 = childSpans.firstWhere((child) => child.text == 'Main');
      final h2 = childSpans.firstWhere((child) => child.text == 'Section');
      final h3 = childSpans.firstWhere((child) => child.text == 'Detail');

      expect(h1.style!.fontSize, GraphiteTypography.markdownH1.fontSize);
      expect(h2.style!.fontSize, GraphiteTypography.markdownH2.fontSize);
      expect(h3.style!.fontSize, GraphiteTypography.markdownH3.fontSize);
      expect(h1.style!.fontSize, greaterThan(h2.style!.fontSize!));
      expect(h2.style!.fontSize, greaterThan(h3.style!.fontSize!));
    });

    testWidgets('hides line-number column when showLineNumbers is false', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'line');
      await tester.pumpWidget(
        _wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: false),
        ),
      );

      expect(find.text('1 lines'), findsNothing);
    });

    group('Formatting toolbar', () {
      testWidgets('renders formatting buttons', (tester) async {
        final controller = TextEditingController();
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        expect(find.byIcon(Icons.format_bold), findsOneWidget);
        expect(find.byIcon(Icons.format_italic), findsOneWidget);
        expect(find.byIcon(Icons.title), findsOneWidget);
        expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
      });

      testWidgets('bold button inserts ** markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();

        expect(controller.text, contains('**'));
      });

      testWidgets('italic button inserts * markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_italic));
        await tester.pump();

        expect(controller.text, contains('*'));
      });

      testWidgets('heading button inserts # markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.title));
        await tester.pump();

        expect(controller.text, contains('# '));
      });

      testWidgets('list button inserts - markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_list_bulleted));
        await tester.pump();

        expect(controller.text, contains('- '));
      });

      testWidgets('link button inserts [[]] markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.link));
        await tester.pump();

        expect(controller.text, contains('[['));
        expect(controller.text, contains(']]'));
      });

      testWidgets('bold button with selected text wraps selection', (
        tester,
      ) async {
        final controller = TextEditingController(text: 'hello world');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 5,
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();

        expect(controller.text, contains('**hello**'));
      });
    });

    group('Undo/redo', () {
      testWidgets('undo and redo buttons are present in toolbar', (
        tester,
      ) async {
        final controller = TextEditingController();
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byIcon(Icons.redo), findsOneWidget);
      });

      testWidgets('undo reverts toolbar formatting action', (tester) async {
        final controller = TextEditingController(text: 'original');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        await tester.tap(find.byType(TextField));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();

        expect(controller.text, isNot(equals('original')));

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();

        expect(controller.text, equals('original'));
      });

      testWidgets('redo restores undone formatting action', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        await tester.tap(find.byType(TextField));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();
        final afterBold = controller.text;

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();
        expect(controller.text, equals('hello'));

        await tester.tap(find.byIcon(Icons.redo));
        await tester.pump();
        expect(controller.text, equals(afterBold));
      });

      testWidgets('undo and redo work for typed text', (tester) async {
        final controller = TextEditingController(text: 'original');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        await tester.enterText(find.byType(TextField), 'changed');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();
        expect(controller.text, equals('original'));

        await tester.tap(find.byIcon(Icons.redo));
        await tester.pump();
        expect(controller.text, equals('changed'));
      });

      testWidgets('new typing after undo clears redo history', (tester) async {
        final controller = TextEditingController(text: 'original');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        await tester.enterText(find.byType(TextField), 'changed');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();
        expect(controller.text, equals('original'));

        await tester.enterText(find.byType(TextField), 'new edit');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.redo));
        await tester.pump();

        expect(controller.text, equals('new edit'));
      });
    });

    group('Footer counts', () {
      testWidgets('shows word and character count', (tester) async {
        final controller = TextEditingController(text: 'one two three');
        await tester.pumpWidget(
          _wrapWithMaterialApp(
            EditorPane(controller: controller, showLineNumbers: true),
          ),
        );

        await tester.pump();
        expect(find.textContaining('3 words'), findsOneWidget);
        expect(find.textContaining('13 chars'), findsOneWidget);
        expect(find.textContaining('1 lines'), findsOneWidget);
      });
    });

    group('Keyboard dismiss on scroll', () {
      testWidgets('TextField is configured for multiline editing', (
        tester,
      ) async {
        final controller = TextEditingController();
        await tester.pumpWidget(
          _wrapWithMaterialApp(EditorPane(controller: controller)),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.maxLines, isNull);
        expect(textField.textInputAction, equals(TextInputAction.newline));
      });
    });
  });
}

Widget _wrapWithMaterialApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}
