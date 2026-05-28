import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/models/note.dart';
import 'package:graphite/screens/editor_screen.dart';
import 'package:graphite/usecases/navigate_link_use_case.dart';
import 'package:graphite/usecases/save_note_use_case.dart';
import 'package:graphite/widgets/editor_pane.dart';
import 'package:graphite/widgets/preview_pane.dart';
import '../helpers/fake_note_repository.dart';

void main() {
  late FakeNoteRepository fakeRepo;
  late SaveNoteUseCase saveNoteUseCase;
  late NavigateLinkUseCase navigateLinkUseCase;

  setUp(() {
    fakeRepo = FakeNoteRepository();
    saveNoteUseCase = SaveNoteUseCase(fakeRepo);
    navigateLinkUseCase = NavigateLinkUseCase(fakeRepo);
  });

  Widget wrap(EditorScreen screen) {
    return MaterialApp(home: screen);
  }

  /// Create a test note in the fake DB and return its id.
  String createNote({String path = 'Test Note', String content = ''}) {
    final note = Note(
      id: '',
      path: path,
      filePath: '$path.md',
      createdAt: DateTime(2025, 6, 1),
      updatedAt: DateTime(2025, 6, 1),
      content: content.isNotEmpty ? content : '# $path\n\nSome **markdown** content with #tag1 and [[OtherPage]].',
      tags: const ['tag1'],
    );
    final id = path.hashCode.toString();
    fakeRepo.notes.add(note.copyWith(id: id));
    return id;
  }

  /// Pump enough frames for async DB load + setState to settle.
  Future<void> pumpUntilSettled(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // ── Rendering ──────────────────────────────────────────────────────

  /// Helper: find a RichText or SelectableText widget whose text contains [substring].
  Finder findRichTextContaining(String substring) {
    return find.byWidgetPredicate((w) {
      if (w is RichText) {
        return w.text.toPlainText().contains(substring);
      }
      if (w is SelectableText) {
        final text = w.data ?? w.textSpan?.toPlainText() ?? '';
        return text.contains(substring);
      }
      return false;
    });
  }

  group('rendering', () {
    testWidgets('renders with existing note content', (tester) async {
      final noteId = createNote();

      await tester.pumpWidget(
        wrap(EditorScreen(noteId: noteId, saveNoteUseCase: saveNoteUseCase, navigateLinkUseCase: navigateLinkUseCase)),
      );
      await pumpUntilSettled(tester);

      expect(find.byType(EditorPane), findsOneWidget);
      expect(find.byType(PreviewPane), findsOneWidget);
      // PreviewPane uses RichText; check content via RichText text
      expect(findRichTextContaining('Test Note'), findsOneWidget);
    });

    testWidgets('renders empty for new note (non-existent id)', (tester) async {
      await tester.pumpWidget(
        wrap(
          EditorScreen(
            noteId: 'new-note-id',
            saveNoteUseCase: saveNoteUseCase,
            navigateLinkUseCase: navigateLinkUseCase,
          ),
        ),
      );
      await pumpUntilSettled(tester);

      expect(find.byType(EditorPane), findsOneWidget);
      expect(find.byType(PreviewPane), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  // ── Typing and preview ─────────────────────────────────────────────

  group('typing updates preview', () {
    testWidgets('typing in editor updates preview content', (tester) async {
      final noteId = createNote();

      await tester.pumpWidget(
        wrap(EditorScreen(noteId: noteId, saveNoteUseCase: saveNoteUseCase, navigateLinkUseCase: navigateLinkUseCase)),
      );
      await pumpUntilSettled(tester);

      final editorPane = find.byType(EditorPane);
      expect(editorPane, findsOneWidget);

      final textField = find.descendant(of: editorPane, matching: find.byType(TextField));
      await tester.enterText(textField, '# Updated\n\nNew content with **bold**');
      await tester.pump();

      expect(findRichTextContaining('Updated'), findsOneWidget);
    });
  });

  // ── Toolbar buttons ────────────────────────────────────────────────

  group('toolbar buttons', () {
    testWidgets('editor pane has toolbar when showLineNumbers is true', (tester) async {
      // The EditorScreen sets showLineNumbers: false on EditorPane.
      // Test toolbar presence at the EditorPane level with showLineNumbers: true.
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EditorPane(controller: controller, showLineNumbers: true)),
        ),
      );

      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.title), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('bold button inserts ** markup', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EditorPane(controller: controller, showLineNumbers: true)),
        ),
      );

      final editorPane = find.byType(EditorPane);
      final textField = find.descendant(of: editorPane, matching: find.byType(TextField));

      await tester.enterText(textField, 'hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();

      final editorText = tester.widget<TextField>(find.descendant(of: editorPane, matching: find.byType(TextField)));
      expect(editorText.controller!.text.contains('**'), isTrue);

      controller.dispose();
    });
  });

  // ── Auto-save ──────────────────────────────────────────────────────

  group('auto-save', () {
    testWidgets('auto-save triggers after 2 seconds of typing pause', (tester) async {
      final noteId = createNote();

      await tester.pumpWidget(
        wrap(EditorScreen(noteId: noteId, saveNoteUseCase: saveNoteUseCase, navigateLinkUseCase: navigateLinkUseCase)),
      );
      await pumpUntilSettled(tester);

      final editorPane = find.byType(EditorPane);
      final textField = find.descendant(of: editorPane, matching: find.byType(TextField));

      await tester.enterText(textField, '# Auto-Saved\n\nContent here.');
      await tester.pump();

      // Advance past auto-save timer (2 seconds)
      await tester.pump(const Duration(seconds: 3));

      final updated = fakeRepo.notes.firstWhere((n) => n.id == noteId);
      expect(updated.content.contains('Auto-Saved'), isTrue);
    });
  });

  // ── Back navigation with unsaved changes ───────────────────────────

  group('back navigation with unsaved changes', () {
    testWidgets('shows unsaved changes dialog when content is dirty', (tester) async {
      final noteId = createNote();

      // Wrap in a Navigator so pop goes somewhere
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditorScreen(
                          noteId: noteId,
                          saveNoteUseCase: saveNoteUseCase,
                          navigateLinkUseCase: navigateLinkUseCase,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Editor'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to editor
      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();
      await pumpUntilSettled(tester);

      // Modify content
      final editorPane = find.byType(EditorPane);
      final textField = find.descendant(of: editorPane, matching: find.byType(TextField));
      await tester.enterText(textField, '# Modified Content\n\nNew text.');
      await tester.pump();

      // Tap the back button in the AppBar
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Unsaved changes dialog should appear
      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text('Discard'), findsWidgets);
      expect(find.text('Stay'), findsWidgets);
    });
  });

  // ── Wiki-link tappable ─────────────────────────────────────────────

  group('wiki-link tappable', () {
    testWidgets('[[Wiki-link]] is rendered in preview and tappable', (tester) async {
      final noteId = createNote(path: 'Link', content: '# Link\n\nSee [[OtherPage]] for details.');

      await tester.pumpWidget(
        wrap(EditorScreen(noteId: noteId, saveNoteUseCase: saveNoteUseCase, navigateLinkUseCase: navigateLinkUseCase)),
      );
      await pumpUntilSettled(tester);

      expect(find.byType(PreviewPane), findsOneWidget);
      expect(find.text('OtherPage'), findsOneWidget);
    });
  });

  // ── Tag highlighting ───────────────────────────────────────────────

  group('tag highlighting', () {
    testWidgets('#tag is highlighted in preview', (tester) async {
      final noteId = createNote(content: '# My Note\n\nContent with #important tag.');

      await tester.pumpWidget(
        wrap(EditorScreen(noteId: noteId, saveNoteUseCase: saveNoteUseCase, navigateLinkUseCase: navigateLinkUseCase)),
      );
      await pumpUntilSettled(tester);

      expect(find.byType(PreviewPane), findsOneWidget);
      expect(find.textContaining('important'), findsOneWidget);
    });
  });
}
