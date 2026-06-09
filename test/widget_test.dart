import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/core/models/note.dart';
import 'package:graphite/features/home/home_screen.dart';
import 'package:graphite/features/home/usecases/delete_note_use_case.dart';
import 'package:graphite/features/home/usecases/note_list_use_case.dart';
import 'package:graphite/features/home/usecases/quick_note_use_case.dart';
import 'helpers/fake_note_repository.dart';

/// The welcome note that GraphiteDB._onCreate would seed on first launch.
final _welcomeNote = Note(
  id: 'welcome',
  path: 'Welcome',
  filePath: '',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  content: '# Welcome to Graphite\n\n'
      'Your personal, local-first notes app. '
      'Everything stays on this device — no accounts, no cloud, no setup.\n\n'
      '## Getting Started\n'
      '• Create a new note by tapping the **+** button below\n'
      '• Write in markdown: use `# Headings`, **bold**, *italic*, and more\n'
      '• Link ideas with `[[double brackets]]` — connect notes like wiki pages\n'
      '• Tag notes with `#hashtags` to organize and filter your thoughts\n\n'
      'Happy note-taking!',
  tags: const ['welcome'],
);

/// Widget test: zero-config onboarding.
/// On first launch, the app shows the note list with the welcome note.
void main() {
  testWidgets('first launch shows welcome note in the note list', (
    WidgetTester tester,
  ) async {
    // Given: a fresh install with only the welcome note seeded
    final repo = FakeNoteRepository();
    repo.notes.add(_welcomeNote);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(
      noteListUseCase: NoteListUseCase(repo),
      quickNoteUseCase: QuickNoteUseCase(repo),
      deleteNoteUseCase: DeleteNoteUseCase(repo),
    )));

    // Allow async init to settle
    await tester.pump();
    await tester.pump();

    // Then: the welcome note title is extracted and displayed
    expect(find.text('Welcome to Graphite'), findsOneWidget);

    // And: the subtitle from the welcome note body is visible
    expect(
      find.textContaining('local-first notes app'),
      findsOneWidget,
    );
  });

  testWidgets('empty vault shows no notes placeholder', (
    WidgetTester tester,
  ) async {
    final repo = FakeNoteRepository();
    await tester.pumpWidget(MaterialApp(home: HomeScreen(
      noteListUseCase: NoteListUseCase(repo),
      quickNoteUseCase: QuickNoteUseCase(repo),
      deleteNoteUseCase: DeleteNoteUseCase(repo),
    )));

    await tester.pump();
    await tester.pump();

    expect(find.text('No notes yet. Tap + to create your first note.'),
        findsOneWidget);
  });
}
