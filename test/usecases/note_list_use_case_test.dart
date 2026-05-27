import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/models/note.dart';
import 'package:graphite/usecases/note_list_use_case.dart';

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

void main() {
  group('NoteListUseCase', () {
    late FakeNoteRepository repo;
    late NoteListUseCase useCase;

    setUp(() {
      repo = FakeNoteRepository();
      useCase = NoteListUseCase(repo);
    });

    group('loadAll', () {
      test('initializes repo and returns all notes', () async {
        // Arrange: pre-populate notes
        final noteA = _makeNote(id: 'a', path: 'alpha', content: 'Hello');
        final noteB = _makeNote(id: 'b', path: 'beta', content: 'World');
        repo.notes.addAll([noteA, noteB]);

        // Act
        final result = await useCase.loadAll();

        // Assert
        expect(result, hasLength(2));
        expect(result.map((n) => n.id), containsAll(['a', 'b']));
      });

      test('returns empty list when no notes exist', () async {
        // Act
        final result = await useCase.loadAll();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('search', () {
      test('returns notes matching the query in content', () async {
        // Arrange
        repo.notes.addAll([
          _makeNote(id: '1', path: 'one', content: 'Flutter is great'),
          _makeNote(id: '2', path: 'two', content: 'Dart is awesome'),
          _makeNote(id: '3', path: 'three', content: 'Python rocks'),
        ]);

        // Act
        final result = await useCase.search('dart');

        // Assert
        expect(result, hasLength(1));
        expect(result.single.id, '2');
      });

      test('returns empty list when no notes match', () async {
        // Arrange
        repo.notes.addAll([
          _makeNote(id: '1', path: 'one', content: 'Flutter'),
        ]);

        // Act
        final result = await useCase.search('nonexistent');

        // Assert
        expect(result, isEmpty);
      });

      test('case-insensitive search', () async {
        // Arrange
        repo.notes.addAll([
          _makeNote(id: '1', path: 'one', content: 'FLUTTER'),
        ]);

        // Act
        final result = await useCase.search('flutter');

        // Assert
        expect(result, hasLength(1));
        expect(result.single.id, '1');
      });
    });

    group('filterByTag', () {
      test('returns notes that have the given tag', () async {
        // Arrange
        repo.notes.addAll([
          _makeNote(id: '1', path: 'one', tags: ['dart', 'flutter']),
          _makeNote(id: '2', path: 'two', tags: ['python']),
          _makeNote(id: '3', path: 'three', tags: ['dart', 'testing']),
        ]);

        // Act
        final result = await useCase.filterByTag('dart');

        // Assert
        expect(result, hasLength(2));
        expect(result.map((n) => n.id), containsAll(['1', '3']));
      });

      test('returns empty list when no notes have the tag', () async {
        // Arrange
        repo.notes.addAll([
          _makeNote(id: '1', path: 'one', tags: ['flutter']),
        ]);

        // Act
        final result = await useCase.filterByTag('nonexistent');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('filterWithLinks', () {
      test('returns notes that have outgoing wiki-links', () async {
        // Arrange
        repo.notes.addAll([
          _makeNote(id: 'linked', path: 'linked', content: 'See [[target]]'),
          _makeNote(id: 'orphan', path: 'orphan', content: 'No links here'),
          _makeNote(id: 'another', path: 'another', content: 'See [[other]]'),
        ]);
        repo.addLinks('linked', {'target'});
        repo.addLinks('another', {'other'});
        // 'orphan' has no links

        // Act
        final result = await useCase.filterWithLinks();

        // Assert
        expect(result, hasLength(2));
        expect(result.map((n) => n.id), containsAll(['linked', 'another']));
      });

      test('returns empty list when no notes have links', () async {
        // Arrange
        repo.notes.addAll([
          _makeNote(id: '1', path: 'one', content: 'No links'),
        ]);
        // No links injected for any note

        // Act
        final result = await useCase.filterWithLinks();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('linkCount', () {
      test('returns the number of outgoing links for a note', () async {
        // Arrange
        repo.notes.add(_makeNote(id: 'linked', path: 'linked'));
        repo.addLinks('linked', {'a', 'b', 'c'});

        // Act
        final count = await useCase.linkCount('linked');

        // Assert
        expect(count, 3);
      });

      test('returns 0 for a note with no links', () async {
        // Arrange
        repo.notes.add(_makeNote(id: 'orphan', path: 'orphan'));

        // Act
        final count = await useCase.linkCount('orphan');

        // Assert
        expect(count, 0);
      });

      test('returns 0 for a non-existent note id', () async {
        // Act
        final count = await useCase.linkCount('nonexistent');

        // Assert
        expect(count, 0);
      });
    });
  });
}
