import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:graphite/core/data/database.dart';
import 'package:graphite/core/models/note.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late GraphiteDB db;

  setUp(() async {
    db = GraphiteDB();
    await db.initialize();
  });

  tearDown(() async {
    final notes = await db.listNotes();
    for (final note in notes) {
      await db.deleteLinksForNote(note.id);
      await db.deleteNote(note.id);
    }
  });

  Note testNote(String path, String content, {List<String> tags = const []}) {
    return Note(
      id: '',
      path: path,
      filePath: '/tmp/$path',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: content,
      tags: tags,
    );
  }

  group('link CRUD', () {
    test('extractLinks stores links and getOutgoingLinks retrieves them',
        () async {
      final note = await db.createNote(
        testNote('test', 'See [[Note A]] and [[Note B]].'),
      );

      await db.extractLinks(note.id, note.content);

      final links = await db.getOutgoingLinks(note.id);
      expect(links.length, equals(2));
      expect(
        links.map((l) => l['to_note_title']),
        containsAll(['Note A', 'Note B']),
      );
    });

    test('extractLinks replaces old links on re-save', () async {
      final note = await db.createNote(
        testNote('test', 'See [[Note A]].'),
      );

      await db.extractLinks(note.id, note.content);
      var links = await db.getOutgoingLinks(note.id);
      expect(links.length, equals(1));
      expect(links.first['to_note_title'], equals('Note A'));

      final updated = note.copyWith(content: 'See [[Note B]].');
      await db.updateNote(updated);
      await db.extractLinks(note.id, 'See [[Note B]].');

      links = await db.getOutgoingLinks(note.id);
      expect(links.length, equals(1));
      expect(links.first['to_note_title'], equals('Note B'));
    });

    test('getIncomingLinks finds notes linking to a title', () async {
      final noteA = await db.createNote(
        testNote('a', 'See [[Shared]].'),
      );
      final noteB = await db.createNote(
        testNote('b', 'Also [[Shared]] and [[Other]].'),
      );

      await db.extractLinks(noteA.id, noteA.content);
      await db.extractLinks(noteB.id, noteB.content);

      final incoming = await db.getIncomingLinks('Shared');
      expect(incoming.length, equals(2));
      expect(
        incoming.map((l) => l['from_note_id']),
        containsAll([noteA.id, noteB.id]),
      );
    });

    test('getLinkCount returns count of outgoing links', () async {
      final note = await db.createNote(
        testNote('test', '[[A]] [[B]] [[C]]'),
      );

      await db.extractLinks(note.id, note.content);

      final count = await db.getLinkCount(note.id);
      expect(count, equals(3));
    });

    test('getLinkCount returns 0 for note with no links', () async {
      final note = await db.createNote(
        testNote('test', 'No links here.'),
      );

      final count = await db.getLinkCount(note.id);
      expect(count, equals(0));
    });

    test('deleteLinksForNote removes all links for a note', () async {
      final note = await db.createNote(
        testNote('test', '[[A]] [[B]]'),
      );

      await db.extractLinks(note.id, note.content);

      var links = await db.getOutgoingLinks(note.id);
      expect(links.length, equals(2));

      await db.deleteLinksForNote(note.id);
      links = await db.getOutgoingLinks(note.id);
      expect(links, isEmpty);
    });
  });

  group('findNoteByTitle', () {
    test('locates note by its path', () async {
      await db.createNote(
        testNote('My Project Ideas', '# Ideas'),
      );

      final result = await db.findNoteByTitle('My Project Ideas');
      expect(result, isNotNull);
      expect(result!.path, equals('My Project Ideas'));
    });

    test('returns null for non-existent title', () async {
      final result = await db.findNoteByTitle('Nonexistent');
      expect(result, isNull);
    });

    test('matches case-insensitively', () async {
      await db.createNote(
        testNote('Meeting Notes', '# Meeting'),
      );

      final result = await db.findNoteByTitle('meeting notes');
      expect(result, isNotNull);
      expect(result!.path, equals('Meeting Notes'));
    });
  });
}
