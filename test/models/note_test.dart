import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/models/note.dart';

void main() {
  final sampleJson = <String, dynamic>{
    'id': 'note-1',
    'path': 'Ideas/Project Alpha',
    'file_path': '/vault/Ideas/Project Alpha.md',
    'created_at': '2026-05-20T12:00:00.000',
    'updated_at': '2026-05-21T14:30:00.000',
    'content': '# Project Alpha\n\nThis is a test note.',
    'tags': ['project', 'alpha'],
  };

  final sampleNote = Note(
    id: 'note-1',
    path: 'Ideas/Project Alpha',
    filePath: '/vault/Ideas/Project Alpha.md',
    createdAt: DateTime.utc(2026, 5, 20, 12, 0, 0),
    updatedAt: DateTime.utc(2026, 5, 21, 14, 30, 0),
    content: '# Project Alpha\n\nThis is a test note.',
    tags: ['project', 'alpha'],
  );

  group('Note.fromJson', () {
    test('parses all fields from JSON map', () {
      final note = Note.fromJson(sampleJson);

      expect(note.id, equals('note-1'));
      expect(note.path, equals('Ideas/Project Alpha'));
      expect(note.filePath, equals('/vault/Ideas/Project Alpha.md'));
      expect(note.createdAt, equals(DateTime.parse('2026-05-20T12:00:00.000')));
      expect(note.updatedAt, equals(DateTime.parse('2026-05-21T14:30:00.000')));
      expect(note.content, equals('# Project Alpha\n\nThis is a test note.'));
      expect(note.tags, equals(['project', 'alpha']));
    });

    test('handles empty tags list', () {
      final json = Map<String, dynamic>.from(sampleJson)..['tags'] = [];

      final note = Note.fromJson(json);

      expect(note.tags, isEmpty);
    });

    test('handles null tags gracefully (defaults to empty list)', () {
      final json = Map<String, dynamic>.from(sampleJson)..['tags'] = null;

      final note = Note.fromJson(json);

      expect(note.tags, isEmpty);
    });

    test('throws when a date field is null (null assertion in constructor)',
        () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['created_at'] = null;

      expect(
        () => Note.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('Note.toJson', () {
    test('serializes all fields to JSON map', () {
      final json = sampleNote.toJson();

      expect(json['id'], equals('note-1'));
      expect(json['path'], equals('Ideas/Project Alpha'));
      expect(json['file_path'], equals('/vault/Ideas/Project Alpha.md'));
      expect(json['created_at'], isA<String>());
      expect(json['updated_at'], isA<String>());
      expect(json['content'], equals('# Project Alpha\n\nThis is a test note.'));
      expect(json['tags'], equals(['project', 'alpha']));
    });

    test('round-trip fromJson → toJson preserves data', () {
      final note = Note.fromJson(sampleJson);
      final json = note.toJson();

      expect(json['id'], equals(sampleJson['id']));
      expect(json['path'], equals(sampleJson['path']));
      expect(json['file_path'], equals(sampleJson['file_path']));
      expect(json['content'], equals(sampleJson['content']));
      expect(json['tags'], equals(sampleJson['tags']));
    });
  });

  group('Note.copyWith', () {
    test('returns same note when no fields changed', () {
      final copy = sampleNote.copyWith();

      expect(copy.id, equals(sampleNote.id));
      expect(copy.path, equals(sampleNote.path));
      expect(copy.content, equals(sampleNote.content));
      expect(copy.tags, equals(sampleNote.tags));
    });

    test('updates a single field while preserving others', () {
      final copy = sampleNote.copyWith(content: 'Updated content');

      expect(copy.id, equals(sampleNote.id));
      expect(copy.path, equals(sampleNote.path));
      expect(copy.content, equals('Updated content'));
      expect(copy.tags, equals(sampleNote.tags));
    });

    test('updates multiple fields', () {
      final newTags = ['updated'];
      final copy = sampleNote.copyWith(
        path: 'New Path',
        content: 'New content',
        tags: newTags,
      );

      expect(copy.path, equals('New Path'));
      expect(copy.content, equals('New content'));
      expect(copy.tags, equals(newTags));
      expect(copy.id, equals(sampleNote.id));
      expect(copy.filePath, equals(sampleNote.filePath));
    });

    test('updates timestamps independently', () {
      final newTime = DateTime.utc(2026, 6, 1);
      final copy = sampleNote.copyWith(
        createdAt: newTime,
        updatedAt: newTime,
      );

      expect(copy.createdAt, equals(newTime));
      expect(copy.updatedAt, equals(newTime));
      expect(copy.id, equals(sampleNote.id));
    });
  });

  group('Note equality', () {
    test('notes with same id are equal', () {
      final a = Note(
        id: 'same-id',
        path: 'A',
        filePath: '/a.md',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: 'A',
        tags: [],
      );
      final b = Note(
        id: 'same-id',
        path: 'B',
        filePath: '/b.md',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: 'B',
        tags: ['different'],
      );

      expect(a, equals(b));
    });

    test('notes with different ids are not equal', () {
      final a = sampleNote;
      final b = sampleNote.copyWith(id: 'different-id');

      expect(a, isNot(equals(b)));
    });

    test('hashCode matches id', () {
      // Notes with same id have same hashCode
      expect(sampleNote.hashCode, equals(sampleNote.copyWith().hashCode));
      // Notes with different ids (may) have different hashCodes
      expect(sampleNote.hashCode, equals('note-1'.hashCode));
    });
  });

  group('Note.toString', () {
    test('includes id, path, content length, and tag count', () {
      final str = sampleNote.toString();

      expect(str, contains('note-1'));
      expect(str, contains('Ideas/Project Alpha'));
      expect(str, contains('37 chars'));
      expect(str, contains('2)'));
    });
  });

  group('Note edge cases', () {
    test('handles empty content', () {
      final note = Note(
        id: 'empty',
        path: 'Empty Note',
        filePath: '/vault/Empty Note.md',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: '',
        tags: [],
      );

      expect(note.content, equals(''));
      expect(note.toString(), contains('0 chars'));
    });

    test('handles special characters in id', () {
      final note = Note(
        id: '!@#-special_id',
        path: 'special',
        filePath: '/vault/special.md',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: 'Special',
        tags: [],
      );

      expect(note.id, equals('!@#-special_id'));
    });

    test('handles Unicode content', () {
      final note = Note(
        id: 'unicode',
        path: 'unicode',
        filePath: '/vault/unicode.md',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: 'こんにちは世界 🎉 émoji café',
        tags: [],
      );

      expect(note.content, isNotEmpty);
    });

    test('handles very long content', () {
      final longContent = 'a' * 10000;
      final note = Note(
        id: 'long',
        path: 'Long Note',
        filePath: '/vault/Long Note.md',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: longContent,
        tags: [],
      );

      expect(note.content.length, equals(10000));
    });

    test('handles tags with special characters', () {
      final note = Note(
        id: 'tagged',
        path: 'Tagged',
        filePath: '/vault/Tagged.md',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: '#tagged',
        tags: ['project-ideas_v2', 'status:done', 'priority!high'],
      );

      expect(note.tags.length, equals(3));
      expect(note.tags, contains('project-ideas_v2'));
      expect(note.tags, contains('status:done'));
      expect(note.tags, contains('priority!high'));
    });
  });

  group('Note.fromJson edge cases', () {
    test('handles malformed date string gracefully', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['created_at'] = 'not-a-real-date';

      // DateTime.tryParse returns null for malformed strings,
      // and the null-assert (!) causes an error
      expect(
        () => Note.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('throws when content is missing', () {
      final json = <String, dynamic>{
        'id': 'note-1',
        'path': 'test',
        'file_path': '/vault/test.md',
        'created_at': '2026-05-20T12:00:00.000',
        'updated_at': '2026-05-21T14:30:00.000',
        // content is missing
        'tags': [],
      };

      expect(
        () => Note.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('handles content with newlines and markdown', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['content'] = '# Title\n\n## Section\n\n- item 1\n- item 2\n\n```dart\nprint("hello");\n```';

      final note = Note.fromJson(json);

      expect(note.content, contains('# Title'));
      expect(note.content, contains('```dart'));
      expect(note.content, contains('item 1'));
    });

    test('handles empty tags array from JSON', () {
      final json = Map<String, dynamic>.from(sampleJson)..['tags'] = [];

      final note = Note.fromJson(json);

      expect(note.tags, isEmpty);
    });
  });

  group('Note.toJson edge cases', () {
    test('serializes empty content correctly', () {
      final note = sampleNote.copyWith(content: '', tags: []);
      final json = note.toJson();

      expect(json['content'], equals(''));
      expect(json['tags'], isEmpty);
    });

    test('serializes Unicode content correctly', () {
      final note = sampleNote.copyWith(content: '日本語テスト');
      final json = note.toJson();

      expect(json['content'], equals('日本語テスト'));
    });

    test('round-trip preserves special characters in tags', () {
      final note = sampleNote.copyWith(
        tags: ['project-ideas_v2', 'status:done'],
      );
      final json = note.toJson();
      final restored = Note.fromJson(json);

      expect(restored.tags, equals(['project-ideas_v2', 'status:done']));
    });
  });

  group('Note.copyWith edge cases', () {
    test('copyWith preserves identity when no fields changed', () {
      final copy = sampleNote.copyWith();

      expect(copy, equals(sampleNote));
    });

    test('copyWith each field individually', () {
      expect(sampleNote.copyWith(id: 'new-id').id, equals('new-id'));
      expect(sampleNote.copyWith(path: 'new-path').path, equals('new-path'));
      expect(sampleNote.copyWith(filePath: '/new/file.md').filePath,
          equals('/new/file.md'));
      expect(sampleNote.copyWith(content: 'new').content, equals('new'));
      expect(sampleNote.copyWith(tags: ['new-tag']).tags, equals(['new-tag']));
    });

    test('updatedAt changes on copyWith do not affect createdAt', () {
      final newUpdated = DateTime.utc(2027, 1, 1);
      final copy = sampleNote.copyWith(updatedAt: newUpdated);

      expect(copy.updatedAt, equals(newUpdated));
      expect(copy.createdAt, equals(sampleNote.createdAt));
    });
  });
}
