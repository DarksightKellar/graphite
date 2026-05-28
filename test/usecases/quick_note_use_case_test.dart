import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/usecases/quick_note_use_case.dart';

import '../helpers/fake_note_repository.dart';

void main() {
  group('QuickNoteUseCase', () {
    late FakeNoteRepository repo;
    late QuickNoteUseCase useCase;

    setUp(() {
      repo = FakeNoteRepository();
      useCase = QuickNoteUseCase(repo);
    });

    group('fromText', () {
      test('creates note with title, content, and tags', () async {
        final note = await useCase.fromText('My Note', 'Some content here', tags: ['personal', 'journal']);

        expect(note.path, 'My Note');
        expect(note.content, '# My Note\n\nSome content here');
        expect(note.tags, ['personal', 'journal']);
        expect(note.id, isNotEmpty);

        // Verify the note is persisted in the repository
        final reloaded = await repo.readNote(note.id);
        expect(reloaded, isNotNull);
        expect(reloaded!.content, '# My Note\n\nSome content here');
        expect(reloaded.tags, ['personal', 'journal']);
      });

      test('creates note with content-only heading when content is empty', () async {
        final note = await useCase.fromText('My Note', '', tags: ['draft']);

        expect(note.content, '# My Note');
        expect(note.tags, ['draft']);
      });

      test('uses fallback title when title is empty', () async {
        final note = await useCase.fromText('', 'Some body');

        expect(note.path, startsWith('Untitled '));
        expect(note.content, startsWith('# Untitled '));
        expect(note.content, contains('\n\nSome body'));
      });

      test('uses fallback title when title is whitespace only', () async {
        final note = await useCase.fromText('   ', 'Body text');

        expect(note.path, startsWith('Untitled '));
        expect(note.content, startsWith('# Untitled '));
      });

      test('tags default to empty list when not provided', () async {
        final note = await useCase.fromText('Simple Note', 'Just text');

        expect(note.tags, isEmpty);
      });

      test('trims leading and trailing whitespace from title', () async {
        final note = await useCase.fromText('  Padded Title  ', 'Content');

        expect(note.path, 'Padded Title');
        expect(note.content, '# Padded Title\n\nContent');
      });

      test('each call produces a unique id', () async {
        final note1 = await useCase.fromText('Note A', 'Content A');
        final note2 = await useCase.fromText('Note B', 'Content B');

        expect(note1.id, isNot(note2.id));
      });
    });

    group('importFile', () {
      test('creates note from imported file with metadata header', () async {
        final note = await useCase.importFile('/vault/imports/meeting-notes.md', '# Topics\n\n- Budget\n- Timeline');

        expect(note.path, 'Imported meeting-notes');
        expect(note.filePath, '/vault/imports/meeting-notes.md');
        expect(note.tags, isEmpty);

        // Content should have metadata header
        expect(note.content, contains('# meeting-notes'));
        expect(note.content, contains('> Imported from: /vault/imports/meeting-notes.md'));
        expect(note.content, contains('> Imported at:'));
        expect(note.content, contains('# Topics'));
        expect(note.content, contains('- Budget'));
        expect(note.content, contains('- Timeline'));

        // Verify persisted
        final reloaded = await repo.readNote(note.id);
        expect(reloaded, isNotNull);
        expect(reloaded!.path, 'Imported meeting-notes');
      });

      test('strips .md extension from display name', () async {
        final note = await useCase.importFile('/path/to/My File.md', 'file content');

        expect(note.path, 'Imported My File');
        expect(note.content, contains('# My File'));
      });

      test('handles file path without .md extension', () async {
        final note = await useCase.importFile('/path/to/notes', 'some content');

        expect(note.path, 'Imported notes');
        expect(note.content, contains('# notes'));
      });

      test('each imported file produces a unique id', () async {
        final note1 = await useCase.importFile('/a/file1.md', 'content1');
        final note2 = await useCase.importFile('/b/file2.md', 'content2');

        expect(note1.id, isNot(note2.id));
      });

      test('imported note has no tags', () async {
        final note = await useCase.importFile('/f.md', 'content');

        expect(note.tags, isEmpty);
      });
    });
  });
}
