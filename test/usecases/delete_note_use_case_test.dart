import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/core/models/note.dart';
import 'package:graphite/features/home/usecases/delete_note_use_case.dart';

import '../helpers/fake_graphite_db.dart';
import '../helpers/fake_note_repository.dart';

/// Helper to create predictable test notes.
Note _makeNote({
  required String id,
  required String path,
  String content = '',
  List<String> tags = const [],
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2025, 6, 1);
  return Note(
    id: id,
    path: path,
    filePath: '/vault/$path.md',
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    content: content,
    tags: tags,
  );
}

/// A FakeGraphiteDB that throws on delete for specific note IDs,
/// used to test partial-failure handling in bulk deletions.
class _ThrowingFakeDB extends FakeGraphiteDB {
  final Set<String> _throwOnIds;
  _ThrowingFakeDB(this._throwOnIds);

  @override
  Future<void> deleteNote(String noteId) async {
    if (_throwOnIds.contains(noteId)) {
      throw Exception('Forced delete failure for $noteId');
    }
    return super.deleteNote(noteId);
  }
}

void main() {
  group('DeleteNoteUseCase', () {
    late FakeNoteRepository repo;
    late DeleteNoteUseCase useCase;

    setUp(() {
      repo = FakeNoteRepository();
      useCase = DeleteNoteUseCase(repo);
    });

    group('single', () {
      test('deletes note by id', () async {
        // Arrange
        final note = _makeNote(id: 'abc-123', path: 'my-note', content: 'Hello');
        repo.notes.add(note);

        // Act
        await useCase.single('abc-123');

        // Assert
        expect(repo.notes, isEmpty);
      });

      test('is no-op for nonexistent id', () async {
        // Arrange
        final note = _makeNote(id: 'real', path: 'real', content: 'keep me');
        repo.notes.add(note);

        // Act — delete a nonexistent id
        await useCase.single('nonexistent');

        // Assert — existing note should remain
        expect(repo.notes, hasLength(1));
        expect(repo.notes.single.id, 'real');
      });
    });

    group('bulk', () {
      test('deletes all notes and returns count', () async {
        // Arrange
        repo.notes.addAll([
          _makeNote(id: 'a', path: 'alpha'),
          _makeNote(id: 'b', path: 'beta'),
          _makeNote(id: 'c', path: 'gamma'),
        ]);

        // Act
        final count = await useCase.bulk(['a', 'b', 'c']);

        // Assert
        expect(count, 3);
        expect(repo.notes, isEmpty);
      });

      test('returns count of deleted (handles nonexistent ids silently)', () async {
        // Arrange
        repo.notes.addAll([_makeNote(id: 'a', path: 'alpha'), _makeNote(id: 'b', path: 'beta')]);

        // Act — 'c' and 'd' are nonexistent; they should be no-ops
        final count = await useCase.bulk(['a', 'nonexistent', 'b', 'also-gone']);

        // Assert — only 2 of the 4 IDs were real, so count = 2
        expect(count, 2);
        expect(repo.notes, isEmpty);
      });

      test('still completes when some deletions fail', () async {
        // Arrange
        final throwingDb = _ThrowingFakeDB({'bad'});
        final throwingRepo = FakeNoteRepository(throwingDb);
        final uc = DeleteNoteUseCase(throwingRepo);
        throwingRepo.notes.addAll([
          _makeNote(id: 'good-a', path: 'alpha'),
          _makeNote(id: 'bad', path: 'problem-child'),
          _makeNote(id: 'good-b', path: 'beta'),
        ]);

        // Act
        final count = await uc.bulk(['good-a', 'bad', 'good-b']);

        // Assert
        // 'bad' should fail, but 'good-a' and 'good-b' should succeed
        expect(count, 2);
        // The 'bad' note should still be in the repo (delete failed)
        expect(throwingRepo.notes, hasLength(1));
        expect(throwingRepo.notes.single.id, 'bad');
      });

      test('returns 0 when the iterable is empty', () async {
        // Arrange
        repo.notes.add(_makeNote(id: 'a', path: 'alpha'));

        // Act
        final count = await useCase.bulk([]);

        // Assert
        expect(count, 0);
        expect(repo.notes, hasLength(1));
      });
    });
  });
}
