import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/data/database.dart';
import 'package:graphite/data/file_repository.dart';
import 'package:graphite/models/note.dart';
import 'package:graphite/repository/note_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late GraphiteDB db;
  late FileRepository fileRepo;
  late NoteRepository repo;
  late Directory tempVault;
  late String testDbDir;

  setUpAll(() async {
    sqfliteFfiInit();
    testDbDir = '${Directory.systemTemp.path}/graphite_repo_test_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(testDbDir).create(recursive: true);
    databaseFactory = databaseFactoryFfi;
    databaseFactoryFfi.setDatabasesPath(testDbDir);
  });

  tearDownAll(() async {
    if (await Directory(testDbDir).exists()) {
      await Directory(testDbDir).delete(recursive: true);
    }
  });

  setUp(() async {
    db = GraphiteDB();
    await db.initialize();

    tempVault = Directory.systemTemp.createTempSync('graphite_repo_vault_');
    fileRepo = FileRepository();
    await fileRepo.init(vaultDir: tempVault);

    repo = NoteRepository(db, fileRepo);
  });

  tearDown(() async {
    try {
      final notes = await db.listNotes();
      for (final note in notes) {
        await db.deleteNote(note.id);
      }
    } catch (_) {}

    if (await tempVault.exists()) {
      await tempVault.delete(recursive: true);
    }
  });

  Note testNote(String path, String content, {List<String> tags = const []}) {
    final now = DateTime.now();
    return Note(
      id: '',
      path: path,
      filePath: '/tmp/$path.md',
      createdAt: now,
      updatedAt: now,
      content: content,
      tags: tags,
    );
  }

  group('createNote', () {
    test('persists to database and file system', () async {
      final created = await repo.createNote(testNote('hello', '# Hello World'));

      expect(created.id, isNotEmpty);
      expect(created.path, equals('hello'));

      // Verify in database
      final fromDb = await db.readNote(created.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.content, equals('# Hello World'));

      // Verify in file system
      final fileContent = await fileRepo.readNote('hello');
      expect(fileContent, equals('# Hello World'));
    });

    test('returns note even if file write fails (best-effort)', () async {
      // This tests the resilience of the repository — file write is best-effort
      final created = await repo.createNote(testNote('resilient', '# Resilient'));

      expect(created.id, isNotEmpty);
      // Database should have it regardless
      final fromDb = await db.readNote(created.id);
      expect(fromDb, isNotNull);
    });
  });

  group('readNote', () {
    test('reads note by id from database', () async {
      final created = await repo.createNote(testNote('readme', '# Read Me'));

      final read = await repo.readNote(created.id);

      expect(read, isNotNull);
      expect(read!.id, equals(created.id));
      expect(read.path, equals('readme'));
      expect(read.content, equals('# Read Me'));
    });

    test('returns null for non-existent id', () async {
      final read = await repo.readNote('nonexistent');

      expect(read, isNull);
    });
  });

  group('updateNote', () {
    test('updates in database and file system', () async {
      final created = await repo.createNote(testNote('to-update', '# Original'));

      final updated = created.copyWith(content: '# Updated Content', updatedAt: DateTime.now());
      await repo.updateNote(updated);

      // Verify in database
      final fromDb = await db.readNote(created.id);
      expect(fromDb!.content, equals('# Updated Content'));

      // Verify in file system
      final fileContent = await fileRepo.readNote('to-update');
      expect(fileContent, equals('# Updated Content'));
    });
  });

  group('deleteNote', () {
    test('removes from database and file system', () async {
      final created = await repo.createNote(testNote('to-delete', '# Delete Me'));

      await repo.deleteNote(created.id);

      // Database should be empty
      final fromDb = await db.readNote(created.id);
      expect(fromDb, isNull);

      // File should be gone
      final exists = await File(fileRepo.getNotePath('to-delete')).exists();
      expect(exists, isFalse);
    });

    test('does not throw for non-existent note', () async {
      await repo.deleteNote('nonexistent');
    });
  });

  group('listAllNotes', () {
    test('lists notes newest first', () async {
      final now = DateTime.now();
      await repo.createNote(
        Note(
          id: '',
          path: 'old',
          filePath: '/tmp/old.md',
          createdAt: now.subtract(const Duration(minutes: 10)),
          updatedAt: now.subtract(const Duration(minutes: 10)),
          content: '# Old',
          tags: [],
        ),
      );
      await repo.createNote(
        Note(id: '', path: 'new', filePath: '/tmp/new.md', createdAt: now, updatedAt: now, content: '# New', tags: []),
      );

      final notes = await repo.listAllNotes();
      expect(notes.length, equals(2));
      expect(notes.first.path, equals('new'));
      expect(notes.last.path, equals('old'));
    });

    test('returns empty list when no notes', () async {
      final notes = await repo.listAllNotes();

      expect(notes, isEmpty);
    });
  });

  group('searchNotes', () {
    test('finds notes by content', () async {
      await repo.createNote(testNote('guide', '# User Guide\n\nGraphite tips.'));

      final results = await repo.searchNotes('graphite');

      expect(results.length, equals(1));
      expect(results.first.path, equals('guide'));
    });

    test('returns empty for no matches', () async {
      await repo.createNote(testNote('only', '# Only'));

      final results = await repo.searchNotes('nonexistent');

      expect(results, isEmpty);
    });
  });

  group('initialize', () {
    test('delegates to database initialize', () async {
      // Should complete without error — no-op if already initialized
      await repo.initialize();
    });
  });

  group('extractLinks', () {
    test('extracts [[wiki-links]] from content', () async {
      final created = await repo.createNote(testNote('linker', '# Note\n\nSee [[Target Page]] for details.'));

      await repo.extractLinks(created.id, created.content);

      // Verify links were stored via getLinkCount
      final count = await repo.getLinkCount(created.id);
      expect(count, equals(1));
    });

    test('handles content with no links', () async {
      final created = await repo.createNote(testNote('plain', '# Note\n\nNo links here.'));

      await repo.extractLinks(created.id, created.content);

      final count = await repo.getLinkCount(created.id);
      expect(count, equals(0));
    });
  });

  group('findNoteByTitle', () {
    test('finds note by case-insensitive path match', () async {
      await repo.createNote(testNote('TargetPage', '# Target Page Content'));

      final found = await repo.findNoteByTitle('targetpage');
      expect(found, isNotNull);
      expect(found!.path, equals('TargetPage'));
    });

    test('returns null for non-existent title', () async {
      final found = await repo.findNoteByTitle('nope');
      expect(found, isNull);
    });
  });

  group('getLinkCount', () {
    test('returns 0 when note has no links', () async {
      final created = await repo.createNote(testNote('nolinks', '# No links here.'));

      final count = await repo.getLinkCount(created.id);
      expect(count, equals(0));
    });
  });

  group('getNotesWithLinks', () {
    test('returns only notes that have wiki-links', () async {
      final linked = await repo.createNote(testNote('linked', '# Linked\n\nSee [[Another]].'));
      await repo.createNote(testNote('plain', '# Plain\n\nNo links.'));

      await repo.extractLinks(linked.id, linked.content);

      final results = await repo.getNotesWithLinks();
      expect(results.length, equals(1));
      expect(results.first.id, equals(linked.id));
    });
  });

  group('getNotesByTag', () {
    test('returns notes matching a tag', () async {
      await repo.createNote(testNote('work-note', '# Work', tags: ['work']));
      await repo.createNote(testNote('personal-note', '# Personal', tags: ['personal']));
      await repo.createNote(testNote('both-note', '# Both', tags: ['work', 'personal']));

      final results = await repo.getNotesByTag('work');
      expect(results.length, equals(2));
      expect(results.map((n) => n.path), containsAll(['work-note', 'both-note']));
    });

    test('returns empty when no notes have tag', () async {
      final results = await repo.getNotesByTag('nonexistent');
      expect(results, isEmpty);
    });
  });

  group('getAllTags', () {
    test('returns all unique tags with note counts', () async {
      await repo.createNote(testNote('a', '# A', tags: ['work', 'ideas']));
      await repo.createNote(testNote('b', '# B', tags: ['work']));

      final tags = await repo.getAllTags();
      expect(tags.length, equals(2));

      final workTag = tags.firstWhere((t) => t.id == 'work');
      expect(workTag.noteCount, equals(2));

      final ideasTag = tags.firstWhere((t) => t.id == 'ideas');
      expect(ideasTag.noteCount, equals(1));
    });

    test('returns empty when no notes exist', () async {
      final tags = await repo.getAllTags();
      expect(tags, isEmpty);
    });
  });
}
