import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/features/editor/widgets/editor_pane.dart';

void main() {
  group('EditorPane', () {
    testWidgets('accepts a TextEditingController', (tester) async {
      final controller = TextEditingController(text: '# Hello\n\nWorld');
      await tester.pumpWidget(_wrapWithMaterialApp(
        EditorPane(controller: controller),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(controller.text, equals('# Hello\n\nWorld'));
    });

    testWidgets('uses monospace font for editor text', (tester) async {
      final controller = TextEditingController(text: 'code');
      await tester.pumpWidget(_wrapWithMaterialApp(
        EditorPane(controller: controller),
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      final style = textField.style;
      expect(style, isNotNull);
      expect(style!.fontFamily, isNotNull);
    });

    testWidgets('calls onChanged when text is modified', (tester) async {
      String? changedText;
      final controller = TextEditingController(text: 'initial');
      await tester.pumpWidget(_wrapWithMaterialApp(
        EditorPane(
          controller: controller,
          onChanged: (text) => changedText = text,
        ),
      ));

      await tester.enterText(find.byType(TextField), 'updated');
      expect(changedText, equals('updated'));
    });

    testWidgets('hides line-number column when showLineNumbers is false', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'line');
      await tester.pumpWidget(_wrapWithMaterialApp(
        EditorPane(controller: controller, showLineNumbers: false),
      ));

      expect(find.text('1 lines'), findsNothing);
    });

    group('Formatting toolbar', () {
      testWidgets('renders formatting buttons', (tester) async {
        final controller = TextEditingController();
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

        expect(find.byIcon(Icons.format_bold), findsOneWidget);
        expect(find.byIcon(Icons.format_italic), findsOneWidget);
        expect(find.byIcon(Icons.title), findsOneWidget);
        expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
      });

      testWidgets('bold button inserts ** markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();

        expect(controller.text, contains('**'));
      });

      testWidgets('italic button inserts * markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_italic));
        await tester.pump();

        expect(controller.text, contains('*'));
      });

      testWidgets('heading button inserts # markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.title));
        await tester.pump();

        expect(controller.text, contains('# '));
      });

      testWidgets('list button inserts - markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

        final textField = find.byType(TextField);
        await tester.tap(textField);
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_list_bulleted));
        await tester.pump();

        expect(controller.text, contains('- '));
      });

      testWidgets('link button inserts [[]] markup at cursor', (tester) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

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
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

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
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

        expect(find.byIcon(Icons.undo), findsOneWidget);
        expect(find.byIcon(Icons.redo), findsOneWidget);
      });

      testWidgets('undo reverts toolbar formatting action', (
        tester,
      ) async {
        final controller = TextEditingController(text: 'original');
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

        await tester.tap(find.byType(TextField));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();

        expect(controller.text, isNot(equals('original')));

        await tester.tap(find.byIcon(Icons.undo));
        await tester.pump();

        expect(controller.text, equals('original'));
      });

      testWidgets('redo restores undone formatting action', (
        tester,
      ) async {
        final controller = TextEditingController(text: 'hello');
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

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
    });

    group('Footer counts', () {
      testWidgets('shows word and character count', (tester) async {
        final controller = TextEditingController(text: 'one two three');
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller, showLineNumbers: true),
        ));

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
        await tester.pumpWidget(_wrapWithMaterialApp(
          EditorPane(controller: controller),
        ));

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.maxLines, isNull);
        expect(textField.textInputAction, equals(TextInputAction.newline));
      });
    });
  });
}

Widget _wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}
