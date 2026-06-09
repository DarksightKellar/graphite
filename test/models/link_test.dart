import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/core/models/link.dart';

void main() {
  final sampleJson = <String, dynamic>{'from_note_id': 'note-123', 'to_note_title': 'Project Alpha', 'weight': 3};

  final sampleLink = const Link(fromNoteId: 'note-123', toNoteTitle: 'Project Alpha', weight: 3);

  group('Link.fromJson', () {
    test('parses all fields from JSON map', () {
      final link = Link.fromJson(sampleJson);

      expect(link.fromNoteId, equals('note-123'));
      expect(link.toNoteTitle, equals('Project Alpha'));
      expect(link.weight, equals(3));
    });

    test('defaults weight to 1 when missing from JSON', () {
      final json = <String, dynamic>{'from_note_id': 'note-1', 'to_note_title': 'Other Note'};

      final link = Link.fromJson(json);

      expect(link.fromNoteId, equals('note-1'));
      expect(link.toNoteTitle, equals('Other Note'));
      expect(link.weight, equals(1));
    });

    test('defaults weight to 1 when null in JSON', () {
      final json = <String, dynamic>{'from_note_id': 'note-1', 'to_note_title': 'Other Note', 'weight': null};

      final link = Link.fromJson(json);

      expect(link.weight, equals(1));
    });

    test('handles zero weight', () {
      final json = <String, dynamic>{'from_note_id': 'a', 'to_note_title': 'b', 'weight': 0};

      final link = Link.fromJson(json);

      expect(link.weight, equals(0));
    });

    test('handles special characters in title', () {
      final json = <String, dynamic>{
        'from_note_id': 'note-1',
        'to_note_title': 'Project: 2024-Q1 Report!',
        'weight': 2,
      };

      final link = Link.fromJson(json);

      expect(link.toNoteTitle, equals('Project: 2024-Q1 Report!'));
    });

    test('handles empty string fields', () {
      final json = <String, dynamic>{'from_note_id': '', 'to_note_title': '', 'weight': 1};

      final link = Link.fromJson(json);

      expect(link.fromNoteId, equals(''));
      expect(link.toNoteTitle, equals(''));
    });
  });

  group('Link.toJson', () {
    test('serializes all fields to JSON map', () {
      final json = sampleLink.toJson();

      expect(json['from_note_id'], equals('note-123'));
      expect(json['to_note_title'], equals('Project Alpha'));
      expect(json['weight'], equals(3));
    });

    test('round-trip fromJson → toJson preserves data', () {
      final link = Link.fromJson(sampleJson);
      final json = link.toJson();

      expect(json['from_note_id'], equals(sampleJson['from_note_id']));
      expect(json['to_note_title'], equals(sampleJson['to_note_title']));
      expect(json['weight'], equals(sampleJson['weight']));
    });

    test('serializes link with default weight', () {
      final link = const Link(fromNoteId: 'a', toNoteTitle: 'b');
      final json = link.toJson();

      expect(json['from_note_id'], equals('a'));
      expect(json['to_note_title'], equals('b'));
      expect(json['weight'], equals(1));
    });
  });

  group('Link.copyWith', () {
    test('returns same link when no fields changed', () {
      final copy = sampleLink.copyWith();

      expect(copy.fromNoteId, equals(sampleLink.fromNoteId));
      expect(copy.toNoteTitle, equals(sampleLink.toNoteTitle));
      expect(copy.weight, equals(sampleLink.weight));
    });

    test('updates fromNoteId while preserving others', () {
      final copy = sampleLink.copyWith(fromNoteId: 'note-999');

      expect(copy.fromNoteId, equals('note-999'));
      expect(copy.toNoteTitle, equals(sampleLink.toNoteTitle));
      expect(copy.weight, equals(sampleLink.weight));
    });

    test('updates toNoteTitle while preserving others', () {
      final copy = sampleLink.copyWith(toNoteTitle: 'New Project');

      expect(copy.fromNoteId, equals(sampleLink.fromNoteId));
      expect(copy.toNoteTitle, equals('New Project'));
      expect(copy.weight, equals(sampleLink.weight));
    });

    test('updates weight while preserving others', () {
      final copy = sampleLink.copyWith(weight: 10);

      expect(copy.fromNoteId, equals(sampleLink.fromNoteId));
      expect(copy.toNoteTitle, equals(sampleLink.toNoteTitle));
      expect(copy.weight, equals(10));
    });

    test('updates all fields', () {
      final copy = sampleLink.copyWith(fromNoteId: 'new-from', toNoteTitle: 'New Title', weight: 99);

      expect(copy.fromNoteId, equals('new-from'));
      expect(copy.toNoteTitle, equals('New Title'));
      expect(copy.weight, equals(99));
    });
  });

  group('Link equality', () {
    test('links with same fromNoteId and toNoteTitle are equal', () {
      final a = const Link(fromNoteId: 'n1', toNoteTitle: 'T', weight: 1);
      final b = const Link(fromNoteId: 'n1', toNoteTitle: 'T', weight: 99);

      expect(a, equals(b));
    });

    test('links with different fromNoteId are not equal', () {
      final a = const Link(fromNoteId: 'n1', toNoteTitle: 'T');
      final b = const Link(fromNoteId: 'n2', toNoteTitle: 'T');

      expect(a, isNot(equals(b)));
    });

    test('links with different toNoteTitle are not equal', () {
      final a = const Link(fromNoteId: 'n1', toNoteTitle: 'T1');
      final b = const Link(fromNoteId: 'n1', toNoteTitle: 'T2');

      expect(a, isNot(equals(b)));
    });

    test('hashCode combines fromNoteId and toNoteTitle', () {
      final a = const Link(fromNoteId: 'n1', toNoteTitle: 'T1');
      final b = const Link(fromNoteId: 'n1', toNoteTitle: 'T1');

      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs when fromNoteId differs', () {
      final a = const Link(fromNoteId: 'n1', toNoteTitle: 'T');
      final b = const Link(fromNoteId: 'n2', toNoteTitle: 'T');

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('hashCode differs when toNoteTitle differs', () {
      final a = const Link(fromNoteId: 'n1', toNoteTitle: 'T1');
      final b = const Link(fromNoteId: 'n1', toNoteTitle: 'T2');

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('Link.toString', () {
    test('includes fromNoteId, toNoteTitle, and weight', () {
      final str = sampleLink.toString();

      expect(str, contains('note-123'));
      expect(str, contains('Project Alpha'));
      expect(str, contains('3'));
    });

    test('includes class name', () {
      final str = sampleLink.toString();

      expect(str, contains('Link'));
    });

    test('shows weight of 1 for default link', () {
      final str = const Link(fromNoteId: 'a', toNoteTitle: 'b').toString();

      expect(str, contains('weight: 1'));
    });
  });

  group('Link default constructor', () {
    test('default weight is 1', () {
      final link = const Link(fromNoteId: 'a', toNoteTitle: 'b');

      expect(link.fromNoteId, equals('a'));
      expect(link.toNoteTitle, equals('b'));
      expect(link.weight, equals(1));
    });
  });

  // ── LinksBatch tests ──────────────────────────────────────────

  group('LinksBatch', () {
    final batchJson = <String, dynamic>{
      'links': [
        {'from_note_id': 'n1', 'to_note_title': 'Note A', 'weight': 1},
        {'from_note_id': 'n2', 'to_note_title': 'Note B', 'weight': 2},
      ],
    };

    test('fromJson parses list of links', () {
      final batch = LinksBatch.fromJson(batchJson);

      expect(batch.links.length, equals(2));
      expect(batch.links[0].fromNoteId, equals('n1'));
      expect(batch.links[0].toNoteTitle, equals('Note A'));
      expect(batch.links[1].fromNoteId, equals('n2'));
      expect(batch.links[1].toNoteTitle, equals('Note B'));
    });

    test('fromJson handles empty links list', () {
      final json = <String, dynamic>{'links': []};

      final batch = LinksBatch.fromJson(json);

      expect(batch.links, isEmpty);
    });

    test('constructor creates batch with provided links', () {
      final links = [const Link(fromNoteId: 'a', toNoteTitle: 'X'), const Link(fromNoteId: 'b', toNoteTitle: 'Y')];
      final batch = LinksBatch(links: links);

      expect(batch.links, equals(links));
    });

    test('constructor handles empty link list', () {
      const batch = LinksBatch(links: []);

      expect(batch.links, isEmpty);
    });

    test('fromJson handles single link', () {
      final json = <String, dynamic>{
        'links': [
          {'from_note_id': 'only', 'to_note_title': 'Only Note', 'weight': 1},
        ],
      };

      final batch = LinksBatch.fromJson(json);

      expect(batch.links.length, equals(1));
      expect(batch.links.first.fromNoteId, equals('only'));
    });
  });
}
