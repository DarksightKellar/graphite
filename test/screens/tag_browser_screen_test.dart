import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/models/note.dart';
import 'package:graphite/screens/tag_browser_screen.dart';
import '../helpers/fake_note_repository.dart';

void main() {
  late FakeNoteRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeNoteRepository();
  });

  Widget _wrap(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  // ── Lists all tags with counts ─────────────────────────────────────

  group('tag list', () {
    testWidgets('lists all tags with note counts', (tester) async {
      fakeRepo.notes.add(Note(
        id: 'a',
        path: 'Note A',
        filePath: 'a.md',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        content: '# Note A\n\nContent with #work and #ideas.',
        tags: const ['work', 'ideas'],
      ));
      fakeRepo.notes.add(Note(
        id: 'b',
        path: 'Note B',
        filePath: 'b.md',
        createdAt: DateTime(2025, 1, 2),
        updatedAt: DateTime(2025, 1, 2),
        content: '# Note B\n\nMore #work stuff.',
        tags: const ['work'],
      ));

      await tester.pumpWidget(
          _wrap(TagBrowserScreen(repo: fakeRepo)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('work'), findsOneWidget);
      expect(find.text('ideas'), findsOneWidget);
      expect(find.textContaining('2 notes'), findsOneWidget);
    });
  });

  // ── Tap tag → filters notes ────────────────────────────────────────

  group('tap tag', () {
    testWidgets('tapping a tag pops with the tag id', (tester) async {
      fakeRepo.notes.add(Note(
        id: 't1',
        path: 'Tagged Note',
        filePath: 'tagged.md',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        content: '# Tagged\n\nHas #personal tag.',
        tags: const ['personal'],
      ));

      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TagBrowserScreen(repo: fakeRepo)),
                  );
                },
                child: const Text('Open Tags'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open Tags'));
      await tester.pumpAndSettle();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('personal'), findsOneWidget);

      await tester.tap(find.text('personal'));
      await tester.pumpAndSettle();

      expect(find.text('Tags'), findsNothing);
      expect(find.text('Open Tags'), findsOneWidget);
    });
  });

  // ── Empty state ────────────────────────────────────────────────────

  group('empty state', () {
    testWidgets('shows empty state when no tags exist', (tester) async {
      // No notes = no tags
      await tester.pumpWidget(
          _wrap(TagBrowserScreen(repo: fakeRepo)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No tags found'), findsOneWidget);
      expect(find.byIcon(Icons.tag_outlined), findsOneWidget);
    });
  });
}
