import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/core/models/note.dart';
import 'package:graphite/features/editor/usecases/navigate_link_use_case.dart';

import '../helpers/fake_note_repository.dart';

void main() {
  group('NavigateLinkUseCase', () {
    late FakeNoteRepository repo;
    late NavigateLinkUseCase useCase;

    setUp(() {
      repo = FakeNoteRepository();
      useCase = NavigateLinkUseCase(repo);
    });

    test('returns existing note when found by title', () async {
      // Arrange: an existing note with a known path (title)
      final existingNote = Note(
        id: 'note-abc',
        path: 'My Wiki Page',
        filePath: '/vault/My Wiki Page.md',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        content: '# My Wiki Page\n\nSome content here.',
        tags: ['wiki'],
      );
      repo.notes.add(existingNote);

      // Act: find or create by the same title
      final result = await useCase.findOrCreate('My Wiki Page');

      // Assert: the existing note is returned unchanged
      expect(result.id, 'note-abc');
      expect(result.path, 'My Wiki Page');
      expect(result.content, '# My Wiki Page\n\nSome content here.');
      expect(result.tags, ['wiki']);

      // Assert: no new note was created in the repository
      expect(repo.notes.length, 1);
    });

    test('creates new note when title not found', () async {
      // Act: find or create a title that doesn't exist
      final result = await useCase.findOrCreate('New Page');

      // Assert: a new note was created with the correct content
      expect(result.path, 'New Page');
      expect(result.filePath, 'New Page');
      expect(result.content, '# New Page\n\n');
      expect(result.tags, isEmpty);

      // Assert: the new note is now in the repository
      expect(repo.notes.length, 1);
      final reloaded = await repo.readNote(result.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.content, '# New Page\n\n');
    });

    test('finds note case-insensitively', () async {
      // Arrange: a note with title "Case Sensitive"
      final existingNote = Note(
        id: 'note-case',
        path: 'Case Sensitive',
        filePath: '/vault/Case Sensitive.md',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        content: '# Case Sensitive\n\nContent.',
        tags: const [],
      );
      repo.notes.add(existingNote);

      // Act: search with different casing
      final result = await useCase.findOrCreate('case sensitive');

      // Assert: the existing note is found despite case difference
      expect(result.id, 'note-case');
      expect(result.path, 'Case Sensitive');
    });
  });

  group('find', () {
    late FakeNoteRepository repo;
    late NavigateLinkUseCase useCase;

    setUp(() {
      repo = FakeNoteRepository();
      useCase = NavigateLinkUseCase(repo);
    });
    test('returns existing note', () async {
      final existing = Note(
        id: 'n1',
        path: 'Target',
        filePath: '/vault/Target.md',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        content: '# Target\n\nBody.',
        tags: const [],
      );
      repo.notes.add(existing);

      final result = await useCase.find('Target');
      expect(result, isNotNull);
      expect(result!.id, 'n1');
      expect(result.path, 'Target');
    });

    test('returns null for non-existent title', () async {
      final result = await useCase.find('Missing');
      expect(result, isNull);
    });

    test('is case-insensitive', () async {
      final existing = Note(
        id: 'n2',
        path: 'CaseTest',
        filePath: '/vault/CaseTest.md',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
        content: '# CaseTest\n\n.',
        tags: const [],
      );
      repo.notes.add(existing);

      final result = await useCase.find('casetest');
      expect(result, isNotNull);
      expect(result!.id, 'n2');
    });
  });

  group('create', () {
    late FakeNoteRepository repo;
    late NavigateLinkUseCase useCase;

    setUp(() {
      repo = FakeNoteRepository();
      useCase = NavigateLinkUseCase(repo);
    });
    test('makes new note with correct content', () async {
      final result = await useCase.create('Brand New');

      expect(result.path, 'Brand New');
      expect(result.filePath, 'Brand New');
      expect(result.content, '# Brand New\n\n');
      expect(result.tags, isEmpty);

      // Verify it is persisted in the repository
      expect(repo.notes.length, 1);
      final reloaded = await repo.readNote(result.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.content, '# Brand New\n\n');
    });
  });
}
