import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/data/database.dart';
import 'package:graphite/models/note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late GraphiteDB db;
  late String testDbDir;

  setUpAll(() async {
    sqfliteFfiInit();
    testDbDir =
        '${Directory.systemTemp.path}/graphite_test_${DateTime.now().millisecondsSinceEpoch}';
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
  });

  tearDown(() async {
    try {
      final notes = await db.listNotes();
      for (final note in notes) {
        await db.deleteNote(note.id);
      }
    } catch (_) {}
  });

  Note testNote(
    String path,
    String content, {
    List<String> tags = const [],
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return Note(
      id: '',
      path: path,
      filePath: '/tmp/$path.md',
      createdAt: now,
      updatedAt: updatedAt ?? now,
      content: content,
      tags: tags,
    );
  }

  group('Tag extraction on createNote', () {
    test('extracts #tags from content and stores them', () async {
      final note = await db.createNote(testNote(
        'tagged',
        '# My Note\n\nThis is about #work and #personal stuff.',
        tags: ['#work', '#personal'],
      ));

      final read = await db.readNote(note.id);
      expect(read, isNotNull);
      expect(read!.tags, containsAll(['#work', '#personal']));
    });

    test('stores empty tags for content without hashtags', () async {
      final note = await db.createNote(testNote(
        'notags',
        '# Plain note\n\nNo hashtags here.',
      ));

      final read = await db.readNote(note.id);
      expect(read, isNotNull);
      expect(read!.tags, isEmpty);
    });
  });

  group('Tag querying', () {
    test('getAllTags returns unique tags with counts', () async {
      await db.createNote(testNote('a', '#work stuff', tags: ['#work']));
      await db.createNote(testNote(
        'b', 'More #work and #personal',
        tags: ['#work', '#personal'],
      ));
      await db.createNote(testNote('c', '#personal journal', tags: ['#personal']));

      final tags = await db.getAllTags();
      expect(tags.length, equals(2));

      final workTag = tags.firstWhere((t) => t.id == '#work');
      final personalTag = tags.firstWhere((t) => t.id == '#personal');
      expect(workTag.noteCount, equals(2));
      expect(personalTag.noteCount, equals(2));
    });

    test('getAllTags returns empty for no tags', () async {
      await db.createNote(testNote('plain', 'No tags'));

      final tags = await db.getAllTags();
      expect(tags, isEmpty);
    });

    test('getNotesByTag returns only notes with that tag', () async {
      await db.createNote(testNote('work', '#work stuff', tags: ['#work']));
      await db.createNote(testNote('personal', '#personal journal', tags: ['#personal']));
      await db.createNote(testNote('both', '#work #personal', tags: ['#work', '#personal']));

      final workNotes = await db.getNotesByTag('#work');
      expect(workNotes.length, equals(2));
      final paths = workNotes.map((n) => n.path).toSet();
      expect(paths, containsAll(['work', 'both']));
    });

    test('getNotesByTag returns empty for unused tag', () async {
      await db.createNote(testNote('only', 'Just #here', tags: ['#here']));

      final results = await db.getNotesByTag('#nowhere');
      expect(results, isEmpty);
    });
  });

  group('Tag update on updateNote', () {
    test('updating note content updates its tags', () async {
      final note = await db.createNote(testNote(
        'change', 'Initial #old-tag',
        tags: ['#old-tag'],
      ));

      final updated = note.copyWith(
        content: 'Changed to #new-tag',
        tags: ['#new-tag'],
        updatedAt: DateTime.now(),
      );
      await db.updateNote(updated);

      final read = await db.readNote(note.id);
      expect(read, isNotNull);
      expect(read!.tags, equals(['#new-tag']));
    });
  });

  group('searchNotes', () {
    test('returns empty list when no notes match query', () async {
      await db.createNote(testNote('alpha', '# Alpha'));
      final results = await db.searchNotes('nonexistent');
      expect(results, isEmpty);
    });

    test('finds note by content match', () async {
      await db.createNote(testNote('alpha', '# Getting Started\n\nLearn Graphite.'));
      await db.createNote(testNote('beta', '# Project Ideas\n\nBuild a mobile app.'));

      final results = await db.searchNotes('graphite');
      expect(results.length, equals(1));
      expect(results.first.path, equals('alpha'));
    });

    test('finds note by path match', () async {
      await db.createNote(testNote('alpha', '# Alpha'));
      await db.createNote(testNote('projects', '# Projects'));

      final results = await db.searchNotes('projects');
      expect(results.length, equals(1));
      expect(results.first.path, equals('projects'));
    });

    test('finds notes matching either content or path (OR semantics)', () async {
      await db.createNote(testNote('alpha', '# Alpha\n\nThis is about projects.'));
      await db.createNote(testNote('projects', '# Projects\n\nProject tracking.'));
      await db.createNote(testNote('journal', '# Journal\n\nDaily log.'));

      final results = await db.searchNotes('projects');
      expect(results.length, equals(2));
      final paths = results.map((r) => r.path).toSet();
      expect(paths, containsAll(['alpha', 'projects']));
    });

    test('case-insensitive matching', () async {
      await db.createNote(testNote('note', '# Work Log\n\nImportant notes.'));

      expect((await db.searchNotes('work')).length, equals(1));
      expect((await db.searchNotes('WORK')).length, equals(1));
      expect((await db.searchNotes('WoRk')).length, equals(1));
    });

    test('returns results ordered by updatedAt DESC', () async {
      await db.createNote(testNote('old', '# Old Note',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10))));
      await db.createNote(testNote('mid', '# Mid Note',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5))));
      final recent = await db.createNote(testNote('new', '# New Note',
          updatedAt: DateTime.now()));

      await db.updateNote(recent.copyWith(
        content: '# Updated New Note',
        updatedAt: DateTime.now(),
      ));

      final results = await db.searchNotes('note');
      expect(results.length, equals(3));
      expect(results.first.path, equals('new'));
    });

    test('limits results to 50', () async {
      for (var i = 0; i < 55; i++) {
        final padded = i.toString().padLeft(3, '0');
        await db.createNote(testNote('note$padded', '# Note $i\n\nContent for note $i.'));
      }

      final results = await db.searchNotes('note');
      expect(results.length, equals(50));
    });

    test('partial substring matching within content', () async {
      await db.createNote(testNote('guide', '# Setup Guide\n\nInstall Graphite on your device.'));
      final results = await db.searchNotes('graph');
      expect(results.length, equals(1));
    });

    test('empty query returns all notes', () async {
      await db.createNote(testNote('a', '# A'));
      await db.createNote(testNote('b', '# B'));
      expect((await db.searchNotes('')).length, equals(2));
    });

    test('special characters in query handled safely', () async {
      await db.createNote(testNote('specials', '# Hashtags\\n\\nUsing #tags and @people.'));
      expect((await db.searchNotes('#tags')).length, equals(1));
    });
  });

  group('createNote', () {
    test('persists note and returns it with an id', () async {
      final note = testNote('note', '# Test');
      final created = await db.createNote(note);

      expect(created.id, isNotEmpty);
      expect(created.path, equals('note'));
      expect(created.content, equals('# Test'));
    });

    test('generates unique ids for different notes', () async {
      final a = await db.createNote(testNote('alpha', 'A'));
      final b = await db.createNote(testNote('beta', 'B'));

      expect(a.id, isNot(equals(b.id)));
    });

    test('generates deterministic ids for same path', () async {
      // Delete the first inserted note so UNIQUE constraint doesn't hit
      final first = await db.createNote(testNote('same', 'First'));
      await db.deleteNote(first.id);

      final second = await db.createNote(testNote('same', 'Second'));
      expect(second.id, equals(first.id));
    });
  });

  group('readNote', () {
    test('returns note when it exists', () async {
      final created = await db.createNote(
        testNote('note', '# Test', tags: ['test']),
      );

      final read = await db.readNote(created.id);
      expect(read, isNotNull);
      expect(read!.id, equals(created.id));
      expect(read.path, equals('note'));
      expect(read.content, equals('# Test'));
      expect(read.tags, equals(['test']));
    });

    test('returns null when note does not exist', () async {
      final read = await db.readNote('nonexistent-id');
      expect(read, isNull);
    });
  });

  group('updateNote', () {
    test('changes note content and metadata', () async {
      final created = await db.createNote(testNote('note', '# Original'));

      final updated = created.copyWith(
        content: '# Updated',
        tags: ['updated'],
        updatedAt: DateTime.now(),
      );
      await db.updateNote(updated);

      final read = await db.readNote(created.id);
      expect(read!.content, equals('# Updated'));
      expect(read.tags, equals(['updated']));
    });

    test('does not throw when updating non-existent note (no-op)', () async {
      final ghost = Note(
        id: 'ghost-id',
        path: 'ghost',
        filePath: '/tmp/ghost.md',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: '# Ghost',
        tags: [],
      );

      // Should complete without throwing
      await db.updateNote(ghost);
    });
  });

  group('deleteNote', () {
    test('removes note from database', () async {
      final created = await db.createNote(testNote('temp', '# To delete'));

      await db.deleteNote(created.id);

      final read = await db.readNote(created.id);
      expect(read, isNull);
    });

    test('does not throw when deleting non-existent note', () async {
      await db.deleteNote('nonexistent-id');
      // Should complete without throwing
    });
  });

  group('listNotes', () {
    test('returns empty list when no notes exist', () async {
      final notes = await db.listNotes();
      expect(notes, isEmpty);
    });

    test('returns all notes ordered by updatedAt DESC', () async {
      await db.createNote(testNote('oldest', 'Old',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10))));
      await db.createNote(testNote('middle', 'Mid',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5))));
      await db.createNote(testNote('newest', 'New',
          updatedAt: DateTime.now()));

      final notes = await db.listNotes();
      expect(notes.length, equals(3));
      expect(notes[0].path, equals('newest'));
      expect(notes[1].path, equals('middle'));
      expect(notes[2].path, equals('oldest'));
    });

    test('returns full Note objects with all fields populated', () async {
      await db.createNote(
        testNote('full', '# Full Note', tags: ['a', 'b']),
      );

      final notes = await db.listNotes();
      expect(notes.length, equals(1));

      final note = notes.first;
      expect(note.id, isNotEmpty);
      expect(note.path, equals('full'));
      expect(note.filePath, equals('/tmp/full.md'));
      expect(note.content, equals('# Full Note'));
      expect(note.tags, equals(['a', 'b']));
      expect(note.createdAt, isA<DateTime>());
      expect(note.updatedAt, isA<DateTime>());
    });
  });

  group('Edge cases', () {
    test('creates note with empty content', () async {
      final note = await db.createNote(testNote('empty', ''));

      final read = await db.readNote(note.id);
      expect(read, isNotNull);
      expect(read!.content, equals(''));
    });

    test('creates note with Unicode content', () async {
      final note = await db.createNote(
        testNote('unicode', 'こんにちは世界 🎉 café'),
      );

      final read = await db.readNote(note.id);
      expect(read, isNotNull);
      expect(read!.content, equals('こんにちは世界 🎉 café'));
    });

    test('creates note with very long content', () async {
      final longContent = 'x' * 5000;
      final note = await db.createNote(testNote('long', longContent));

      final read = await db.readNote(note.id);
      expect(read, isNotNull);
      expect(read!.content.length, equals(5000));
    });

    test('updating note with empty content', () async {
      final created = await db.createNote(
        testNote('to-empty', 'Original content'),
      );

      final updated = created.copyWith(
        content: '',
        tags: [],
        updatedAt: DateTime.now(),
      );
      await db.updateNote(updated);

      final read = await db.readNote(created.id);
      expect(read!.content, equals(''));
    });

    test('read after delete returns null', () async {
      final created = await db.createNote(testNote('gone', 'Temporary'));

      await db.deleteNote(created.id);

      final read = await db.readNote(created.id);
      expect(read, isNull);

      // Delete again should not throw
      await db.deleteNote(created.id);
    });

    test('listNotes respects order after update', () async {
      final a = await db.createNote(testNote('a', 'A',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10))));
      await db.createNote(testNote('b', 'B',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5))));

      // Update note A so it becomes the most recent
      await db.updateNote(a.copyWith(
        content: 'A updated',
        updatedAt: DateTime.now(),
      ));

      final notes = await db.listNotes();
      expect(notes.length, equals(2));
      expect(notes.first.path, equals('a')); // A is now most recent
    });

    test('search handles empty content note', () async {
      await db.createNote(testNote('empty', ''));

      // Empty query returns all notes
      final results = await db.searchNotes('');
      expect(results.length, equals(1));
    });

    test('search handles special regex characters safely', () async {
      await db.createNote(testNote('specials',
          'Testing (parentheses) and [brackets] and \$dollar signs.'));

      final results = await db.searchNotes('(parentheses)');
      expect(results.length, equals(1));
    });

    test('getAllTags with Unicode tag content', () async {
      await db.createNote(testNote('uni',
          '#テスト #日本語',
          tags: ['テスト', '日本語']));

      final tags = await db.getAllTags();
      expect(tags.length, equals(2));
      expect(tags.map((t) => t.id), containsAll(['テスト', '日本語']));
    });

    test('initialization is idempotent (calling initialize twice)', () async {
      // First initialize already called in setUp
      // Second initialize should not throw
      await db.initialize();

      // Verify database still works after re-initialize
      final note = await db.createNote(testNote('after', 'After re-init'));
      expect(note.id, isNotEmpty);
    });
  });
}
