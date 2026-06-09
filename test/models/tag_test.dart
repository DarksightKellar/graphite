import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/core/models/tag.dart';

void main() {
  final sampleJson = <String, dynamic>{
    'id': 'work',
    'note_count': 5,
  };

  final sampleTag = const Tag(
    id: 'work',
    noteCount: 5,
  );

  group('Tag.fromJson', () {
    test('parses all fields from JSON map', () {
      final tag = Tag.fromJson(sampleJson);

      expect(tag.id, equals('work'));
      expect(tag.noteCount, equals(5));
    });

    test('defaults noteCount to 0 when missing from JSON', () {
      final json = <String, dynamic>{'id': 'personal'};

      final tag = Tag.fromJson(json);

      expect(tag.id, equals('personal'));
      expect(tag.noteCount, equals(0));
    });

    test('defaults noteCount to 0 when null in JSON', () {
      final json = <String, dynamic>{
        'id': 'personal',
        'note_count': null,
      };

      final tag = Tag.fromJson(json);

      expect(tag.id, equals('personal'));
      expect(tag.noteCount, equals(0));
    });

    test('handles zero note_count', () {
      final json = <String, dynamic>{
        'id': 'empty',
        'note_count': 0,
      };

      final tag = Tag.fromJson(json);

      expect(tag.noteCount, equals(0));
    });

    test('handles large note_count', () {
      final json = <String, dynamic>{
        'id': 'popular',
        'note_count': 9999,
      };

      final tag = Tag.fromJson(json);

      expect(tag.noteCount, equals(9999));
    });

    test('handles special characters in tag id', () {
      final json = <String, dynamic>{
        'id': 'project-ideas_v2',
        'note_count': 3,
      };

      final tag = Tag.fromJson(json);

      expect(tag.id, equals('project-ideas_v2'));
    });

    test('handles empty string id', () {
      final json = <String, dynamic>{
        'id': '',
        'note_count': 0,
      };

      final tag = Tag.fromJson(json);

      expect(tag.id, equals(''));
    });
  });

  group('Tag.toJson', () {
    test('serializes all fields to JSON map', () {
      final json = sampleTag.toJson();

      expect(json['id'], equals('work'));
      expect(json['note_count'], equals(5));
    });

    test('round-trip fromJson → toJson preserves data', () {
      final tag = Tag.fromJson(sampleJson);
      final json = tag.toJson();

      expect(json['id'], equals(sampleJson['id']));
      expect(json['note_count'], equals(sampleJson['note_count']));
    });

    test('serializes tag with noteCount 0', () {
      final tag = const Tag(id: 'empty');
      final json = tag.toJson();

      expect(json['id'], equals('empty'));
      expect(json['note_count'], equals(0));
    });
  });

  group('Tag.copyWith', () {
    test('returns same tag when no fields changed', () {
      final copy = sampleTag.copyWith();

      expect(copy.id, equals(sampleTag.id));
      expect(copy.noteCount, equals(sampleTag.noteCount));
    });

    test('updates id while preserving noteCount', () {
      final copy = sampleTag.copyWith(id: 'updated-work');

      expect(copy.id, equals('updated-work'));
      expect(copy.noteCount, equals(sampleTag.noteCount));
    });

    test('updates noteCount while preserving id', () {
      final copy = sampleTag.copyWith(noteCount: 10);

      expect(copy.id, equals(sampleTag.id));
      expect(copy.noteCount, equals(10));
    });

    test('updates both fields', () {
      final copy = sampleTag.copyWith(id: 'new', noteCount: 42);

      expect(copy.id, equals('new'));
      expect(copy.noteCount, equals(42));
    });
  });

  group('Tag equality', () {
    test('tags with same id are equal', () {
      final a = const Tag(id: 'same', noteCount: 3);
      final b = const Tag(id: 'same', noteCount: 99);

      expect(a, equals(b));
    });

    test('tags with different ids are not equal', () {
      final a = const Tag(id: 'work');
      final b = const Tag(id: 'personal');

      expect(a, isNot(equals(b)));
    });

    test('hashCode matches id', () {
      expect(sampleTag.hashCode, equals('work'.hashCode));
    });

    test('hashCode is consistent for same id regardless of noteCount', () {
      final a = const Tag(id: 'tag', noteCount: 1);
      final b = const Tag(id: 'tag', noteCount: 100);

      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('Tag.toString', () {
    test('includes id and noteCount', () {
      final str = sampleTag.toString();

      expect(str, contains('work'));
      expect(str, contains('5'));
    });

    test('includes id for tag with zero count', () {
      final str = const Tag(id: 'empty').toString();

      expect(str, contains('empty'));
      expect(str, contains('0'));
    });

    test('includes class name', () {
      final str = sampleTag.toString();

      expect(str, contains('Tag'));
    });
  });

  group('Tag default constructor', () {
    test('default noteCount is 0', () {
      const tag = Tag(id: 'new-tag');

      expect(tag.id, equals('new-tag'));
      expect(tag.noteCount, equals(0));
    });
  });
}
