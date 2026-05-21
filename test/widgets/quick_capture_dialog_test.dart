import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/widgets/quick_capture_dialog.dart';

/// Tests for the QuickCaptureDialog bottom sheet widget.
void main() {
  group('QuickCaptureDialog', () {
    testWidgets('shows title field auto-focused', (tester) async {
      await tester.pumpWidget(_wrapWithMaterialApp(
        const QuickCaptureDialog(),
      ));

      // Title field exists and is a TextField
      expect(find.byType(TextField), findsWidgets);

      // The first TextField should have autofocus
      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.autofocus, isTrue);
    });

    testWidgets('shows content field as optional second input', (tester) async {
      await tester.pumpWidget(_wrapWithMaterialApp(
        const QuickCaptureDialog(),
      ));

      // Should have two TextFields (title + content)
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('shows Save button', (tester) async {
      await tester.pumpWidget(_wrapWithMaterialApp(
        const QuickCaptureDialog(),
      ));

      // Should have a Save button
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('extracts tags from content and shows as chips', (tester) async {
      await tester.pumpWidget(_wrapWithMaterialApp(
        const QuickCaptureDialog(),
      ));

      // Type content and title
      await tester.enterText(find.byType(TextField).first, 'My Note');
      await tester.enterText(find.byType(TextField).last, 'Some text #work #ideas');

      // Pump to allow tag extraction to update
      await tester.pump();

      // Tag chips should appear with #work and #ideas
      expect(find.text('#work'), findsOneWidget);
      expect(find.text('#ideas'), findsOneWidget);
    });

    testWidgets('calls onSave with title, content, and tags', (tester) async {
      String? savedTitle;
      String? savedContent;
      List<String>? savedTags;

      await tester.pumpWidget(_wrapWithMaterialApp(
        QuickCaptureDialog(
          onSave: (title, content, tags) {
            savedTitle = title;
            savedContent = content;
            savedTags = tags;
          },
        ),
      ));

      // Enter title and content
      await tester.enterText(find.byType(TextField).first, 'Shopping List');
      await tester.enterText(find.byType(TextField).last, 'Buy milk #groceries #urgent');

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedTitle, equals('Shopping List'));
      expect(savedContent, equals('Buy milk #groceries #urgent'));
      expect(savedTags, containsAll(['#groceries', '#urgent']));
    });

    testWidgets('passes empty tags when content has no hashtags', (tester) async {
      List<String>? savedTags;

      await tester.pumpWidget(_wrapWithMaterialApp(
        QuickCaptureDialog(
          onSave: (title, content, tags) {
            savedTags = tags;
          },
        ),
      ));

      // Enter content with no hashtags
      await tester.enterText(find.byType(TextField).first, 'Plain note');
      await tester.enterText(find.byType(TextField).last, 'Just some text without tags');

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedTags, isEmpty);
    });

    testWidgets('shows Cancel button and calls onCancel when tapped', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(_wrapWithMaterialApp(
        QuickCaptureDialog(
          onSave: (title, content, tags) {},
          onCancel: () => cancelled = true,
        ),
      ));

      // Cancel button should exist
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(cancelled, isTrue);
    });

    testWidgets('shows character and word count when content is entered',
        (tester) async {
      await tester.pumpWidget(_wrapWithMaterialApp(
        const QuickCaptureDialog(),
      ));

      // Type content
      final contentField = find.byType(TextField).last;
      await tester.enterText(contentField, 'Hello world #test');
      await tester.pump();

      // Character/word count should appear
      expect(find.textContaining('chars'), findsOneWidget);
      expect(find.textContaining('words'), findsOneWidget);
    });

    testWidgets('submitting title field triggers onSave', (tester) async {
      String? savedTitle;
      String? savedContent;

      await tester.pumpWidget(_wrapWithMaterialApp(
        QuickCaptureDialog(
          onSave: (title, content, tags) {
            savedTitle = title;
            savedContent = content;
          },
        ),
      ));

      // Type title and submit via keyboard Done action
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Quick note');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(savedTitle, equals('Quick note'));
      expect(savedContent, equals(''));
    });

    testWidgets('content field shows markdown hints', (tester) async {
      await tester.pumpWidget(_wrapWithMaterialApp(
        const QuickCaptureDialog(),
      ));

      // Content field hint should mention markdown features
      final contentHint = find.textContaining('markdown');
      expect(contentHint, findsOneWidget);
    });

    testWidgets('prevents dismiss when content is entered', (tester) async {
      await tester.pumpWidget(_wrapWithMaterialApp(
        const QuickCaptureDialog(),
      ));

      // Type some content
      final contentField = find.byType(TextField).last;
      await tester.enterText(contentField, 'Some content');

      // The widget should be wrapped in PopScope that can prevent dismissal
      expect(find.byWidgetPredicate((w) => w is PopScope), findsOneWidget);
    });

    testWidgets('saves with empty title (emits empty string to onSave)',
        (tester) async {
      String? savedTitle;
      String? savedContent;

      await tester.pumpWidget(_wrapWithMaterialApp(
        QuickCaptureDialog(
          onSave: (title, content, tags) {
            savedTitle = title;
            savedContent = content;
          },
        ),
      ));

      // Don't enter title, just enter content
      await tester.enterText(find.byType(TextField).last, 'Content only');

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pump();

      // onSave should be called with empty title, content passed through
      expect(savedTitle, equals(''));
      expect(savedContent, equals('Content only'));
    });
  });
}

/// Helper: wraps a widget in MaterialApp + Scaffold for testing.
Widget _wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}
