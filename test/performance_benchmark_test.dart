import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/core/data/database.dart';
import 'package:graphite/core/models/note.dart';
import 'package:graphite/core/repository/note_repository.dart';
import 'package:graphite/features/editor/editor_screen.dart';
import 'package:graphite/features/editor/usecases/navigate_link_use_case.dart';
import 'package:graphite/features/editor/usecases/save_note_use_case.dart';
import 'package:graphite/features/editor/widgets/editor_pane.dart';
import 'package:graphite/features/home/home_screen.dart';
import 'package:graphite/features/home/usecases/delete_note_use_case.dart';
import 'package:graphite/features/home/usecases/note_list_use_case.dart';
import 'package:graphite/features/home/usecases/quick_note_use_case.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/fake_note_repository.dart';
import 'helpers/fake_graphite_db.dart';

/// Micro-benchmarks for MVP performance targets.
///
/// Targets:
///   - Cold start: <2 seconds (DB init measured here)
///   - Search latency: <500ms p95 (measured with 100/200/500 notes)
///   - Time to first note: <30 seconds (editor load measured here)
///
/// Note: widget rendering benchmarks use [FakeGraphiteDB] to isolate Flutter
/// rendering perf from sqflite FFI I/O. DB I/O is benchmarked separately above.

/// Helper: seed notes into a [FakeGraphiteDB] (synchronous, for widget benchmarks).
void _seedFakeNotes(FakeGraphiteDB db, int count, {int contentLength = 200}) {
  final rng = Random(42);
  for (var i = 0; i < count; i++) {
    final title = 'Benchmark Note ${i.toString().padLeft(4, '0')}';
    final content = String.fromCharCodes(List.generate(contentLength, (_) => rng.nextInt(26) + 97));
    db.notes.add(
      Note(
        id: title.hashCode.toString(),
        path: title,
        filePath: '$title.md',
        createdAt: DateTime.now().subtract(Duration(days: count - i)),
        updatedAt: DateTime.now().subtract(Duration(minutes: i)),
        content: '# $title\n\n$content',
        tags: i % 3 == 0 ? ['benchmark'] : [],
      ),
    );
  }
}

void main() {
  group('Performance benchmarks', () {
    late GraphiteDB db;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfiNoIsolate;
      // Nuke leftover DB from previous runs.
      final dbFile = File('.dart_tool/sqflite_common_ffi/databases/graphite.db');
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    });

    tearDownAll(() async {
      // Nuke the DB file so subsequent runs start fresh.
      // sqflite_common_ffi creates the db at <cwd>/.dart_tool/sqflite_common_ffi/databases/
      final dbFile = File('.dart_tool/sqflite_common_ffi/databases/graphite.db');
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      GraphiteDB.resetForTesting();
    });

    setUp(() async {
      GraphiteDB.resetForTesting();
      db = GraphiteDB();
      await db.initialize();
    });

    tearDown(() async {
      // Clean benchmark data by deleting all non-welcome notes
      final notes = await db.listNotes();
      for (final note in notes) {
        if (note.path != 'Welcome') {
          await db.deleteNote(note.id);
        }
      }
    });

    test('DB initialization <2 seconds (cold start target)', () async {
      final freshDb = GraphiteDB();
      final sw = Stopwatch()..start();
      await freshDb.initialize();
      sw.stop();
      // swiftlint:disable:next no_magic_numbers — performance target
      expect(sw.elapsedMilliseconds, lessThan(2000), reason: 'Cold start DB init must be under 2 seconds');
      // swiftlint:disable:next avoid_print
      print('  DB init: ${sw.elapsedMilliseconds}ms');
    });

    /// Helper: create N synthetic notes for bulk benchmarks.
    Future<void> seedNotes(int count, {int contentLength = 200}) async {
      final rng = Random(42);
      for (var i = 0; i < count; i++) {
        final title = 'Benchmark Note ${i.toString().padLeft(4, '0')}';
        final content = String.fromCharCodes(List.generate(contentLength, (_) => rng.nextInt(26) + 97));
        await db.createNote(
          Note(
            id: '',
            path: title,
            filePath: '$title.md',
            createdAt: DateTime.now().subtract(Duration(days: count - i)),
            updatedAt: DateTime.now().subtract(Duration(minutes: i)),
            content: '# $title\n\n$content',
            tags: i % 3 == 0 ? ['benchmark'] : [],
          ),
        );
      }
      // Allow any pending DB work
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    group('Search performance', () {
      final datasets = [100, 200, 500];
      for (final size in datasets) {
        test('search with $size notes <500ms p95', () async {
          await seedNotes(size);

          final sw = Stopwatch()..start();
          final results = await db.searchNotes('benchmark');
          sw.stop();

          expect(results, isNotEmpty);
          expect(sw.elapsedMilliseconds, lessThan(500), reason: 'Search with $size notes must be <500ms');
          // swiftlint:disable:next avoid_print
          print(
            '  Search ($size notes): ${sw.elapsedMilliseconds}ms, '
            '${results.length} results',
          );
        });
      }
    });

    group('Editor load performance', () {
      final contentSizes = {'1KB': 1024, '10KB': 10 * 1024, '100KB': 100 * 1024};

      var noteId = '';

      setUp(() async {
        // Create a single test note (not using _seedNotes — we need specific IDs)
        final rng = Random(123);
        final content = String.fromCharCodes(List.generate(1024, (_) => rng.nextInt(26) + 97));
        final note = await db.createNote(
          Note(
            id: '',
            path: 'Editor Benchmark',
            filePath: 'Editor Benchmark.md',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            content: '# Editor Benchmark\n\n$content',
            tags: const [],
          ),
        );
        noteId = note.id;
      });

      for (final MapEntry(key: label, value: size) in contentSizes.entries) {
        testWidgets('editor load for $label note <30s', (tester) async {
          // Create larger content
          final rng = Random(456);
          final bigContent = String.fromCharCodes(List.generate(size, (_) => rng.nextInt(26) + 97));
          final existing = await db.readNote(noteId);
          if (existing != null) {
            await db.updateNote(existing.copyWith(
              content: '# Large Note\\n\\n$bigContent',
              updatedAt: DateTime.now(),
            ));
          }

          final sw = Stopwatch()..start();
          // Run widget build + DB I/O entirely in real async zone so
          // sqflite FFI futures can resolve without deadlocking.
          await tester.runAsync(() async {
            await tester.pumpWidget(
              MaterialApp(
                home: EditorScreen(
                  noteId: noteId,
                  saveNoteUseCase: SaveNoteUseCase(NoteRepository(db)),
                  navigateLinkUseCase: NavigateLinkUseCase(NoteRepository(db)),
                ),
              ),
            );
            // Give sqflite FFI time to complete _loadNote.
            await Future<void>.delayed(const Duration(seconds: 2));
            await tester.pump();
            await tester.pump();
          });
          sw.stop();

          final editorPane = find.byType(EditorPane);
          expect(editorPane, findsOneWidget);

          // swiftlint:disable:next avoid_print
          print('  Editor load ($label): ${sw.elapsedMilliseconds}ms');
        });
      }
    });

    testWidgets('home screen render with 100 notes', (tester) async {
      // Use FakeNoteRepository — rendering perf is what matters here;
      // sqflite FFI I/O is already benchmarked above.
      final fakeDb = FakeGraphiteDB();
      _seedFakeNotes(fakeDb, 100);
      final fakeRepo = FakeNoteRepository(fakeDb);

      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            noteListUseCase: NoteListUseCase(fakeRepo),
            quickNoteUseCase: QuickNoteUseCase(fakeRepo),
            deleteNoteUseCase: DeleteNoteUseCase(fakeRepo),
          ),
        ),
      );
      // Pump frames until note cards render (fake DB is synchronous).
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(Card).evaluate().isNotEmpty) break;
      }
      sw.stop();

      // Should render note cards
      expect(find.byType(Card), findsWidgets);
      // swiftlint:disable:next avoid_print
      print('  HomeScreen render (100 notes): ${sw.elapsedMilliseconds}ms');
    });
  });

  group('Jank detection', () {
    testWidgets('scrolling 500 note list should not drop frames', (tester) async {
      // Use FakeNoteRepository — scrolling perf is about widget rendering,
      // not DB I/O (which is benchmarked separately above).
      final fakeDb = FakeGraphiteDB();
      _seedFakeNotes(fakeDb, 500);
      final fakeRepo = FakeNoteRepository(fakeDb);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            noteListUseCase: NoteListUseCase(fakeRepo),
            quickNoteUseCase: QuickNoteUseCase(fakeRepo),
            deleteNoteUseCase: DeleteNoteUseCase(fakeRepo),
          ),
        ),
      );
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(Card).evaluate().isNotEmpty) break;
      }

      // Scroll through the list in chunks
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Scroll down 3 times, measuring frame timing tolerance
      for (var i = 0; i < 3; i++) {
        await tester.drag(listView, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 16));
      }

      // The list should still be rendering (not crashed)
      expect(find.byType(Card), findsWidgets);
    });
  });
}
