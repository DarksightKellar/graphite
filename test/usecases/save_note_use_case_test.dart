import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/models/note.dart';
import 'package:graphite/usecases/save_note_use_case.dart';

import '../helpers/fake_note_repository.dart';

void main() {
  group('SaveNoteUseCase', () {
    late FakeNoteRepository repo;
    late SaveNoteUseCase useCase;

    setUp(() {
      repo = FakeNoteRepository();
      useCase = SaveNoteUseCase(repo);
    });

    test(
      'updates existing note in place preserving original metadata',
      () async {
        // Arrange: pre-populate with an existing note
        final originalNote = Note(
          id: 'note-123',
          path: 'projects/my-note',
          filePath: '/vault/projects/my-note.md',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          content: '# Old Content',
          tags: ['important', 'draft'],
        );
        repo.notes.add(originalNote);

        // Act: save with new content
        final saved = await useCase('note-123', '# New Content');

        // Assert: the saved note has new content but preserved metadata
        expect(saved.id, 'note-123');
        expect(saved.path, 'projects/my-note');
        expect(saved.filePath, '/vault/projects/my-note.md');
        expect(saved.createdAt, DateTime(2025, 1, 1));
        expect(saved.content, '# New Content');
        expect(saved.tags, ['important', 'draft']);
        expect(saved.updatedAt.isAfter(DateTime(2025, 1, 1)), isTrue);

        // Assert: the note in the repository was updated
        final reloaded = await repo.readNote('note-123');
        expect(reloaded, isNotNull);
        expect(reloaded!.content, '# New Content');
      },
    );

    test('creates new note when note does not exist', () async {
      // Act: save a note that doesn't exist
      final saved = await useCase('fresh-note', '# Fresh Content');

      // Assert: a new note was created
      expect(saved.path, 'fresh-note');
      expect(saved.filePath, 'fresh-note');
      expect(saved.content, '# Fresh Content');
      expect(saved.tags, isEmpty);

      // Assert: the note is now in the repository
      final reloaded = await repo.readNote(saved.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.content, '# Fresh Content');
    });

    test('extracts links after save', () async {
      // Arrange
      final originalNote = Note(
        id: 'note-links',
        path: 'note-links',
        filePath: 'note-links',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        content: 'old',
        tags: const [],
      );
      repo.notes.add(originalNote);

      // Act: save content with wiki-links
      await useCase(
        'note-links',
        '# Title\n\nSee [[other-note]] and [[second-note]].',
      );

      // Assert: links were extracted
      final linkCount = await repo.getLinkCount('note-links');
      expect(linkCount, 2);
    });

    test('initialize delegates to repository', () async {
      expect(repo.initialized, isFalse);
      await useCase.initialize();
      expect(repo.initialized, isTrue);
    });

    test('readNote delegates to repository', () async {
      final note = Note(
        id: 'read-test',
        path: 'read-test',
        filePath: 'read-test',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        content: '# Read Test',
        tags: const [],
      );
      repo.notes.add(note);

      final result = await useCase.readNote('read-test');
      expect(result, isNotNull);
      expect(result!.id, 'read-test');
      expect(result.content, '# Read Test');

      // Non-existent note returns null
      final missing = await useCase.readNote('nonexistent');
      expect(missing, isNull);
    });
  });
}
