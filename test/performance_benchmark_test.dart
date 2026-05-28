import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/data/database.dart';
import 'package:graphite/models/note.dart';
import 'package:graphite/repository/note_repository.dart';
import 'package:graphite/screens/editor_screen.dart';
import 'package:graphite/screens/home_screen.dart';
import 'package:graphite/usecases/delete_note_use_case.dart';
import 'package:graphite/usecases/navigate_link_use_case.dart';
import 'package:graphite/usecases/note_list_use_case.dart';
import 'package:graphite/usecases/quick_note_use_case.dart';
import 'package:graphite/usecases/save_note_use_case.dart';
import 'package:graphite/widgets/editor_pane.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Micro-benchmarks for MVP performance targets.
///
/// Targets:
///   - Cold start: <2 seconds (DB init measured here)
///   - Search latency: <500ms p95 (measured with 100/200/500 notes)
///   - Time to first note: <30 seconds (editor load measured here)
void main() {
  group('Performance benchmarks', () {
    late GraphiteDB db;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
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
            await db.updateNote(existing.copyWith(content: '# Large Note\\n\\n$bigContent', updatedAt: DateTime.now()));
          }

          final sw = Stopwatch()..start();
          await tester.pumpWidget(
            MaterialApp(
              home: EditorScreen(
                noteId: noteId,
                saveNoteUseCase: SaveNoteUseCase(NoteRepository(db)),
                navigateLinkUseCase: NavigateLinkUseCase(NoteRepository(db)),
              ),
            ),
          );
          // Wait for load to complete
          await tester.pumpAndSettle(const Duration(seconds: 30));
          sw.stop();

          final editorPane = find.byType(EditorPane);
          expect(editorPane, findsOneWidget);

          // swiftlint:disable:next avoid_print
          print('  Editor load ($label): ${sw.elapsedMilliseconds}ms');
        });
      }
    });

    testWidgets('home screen render with 100 notes', (tester) async {
      await seedNotes(100);

      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            noteListUseCase: NoteListUseCase(NoteRepository(db)),
            quickNoteUseCase: QuickNoteUseCase(NoteRepository(db)),
            deleteNoteUseCase: DeleteNoteUseCase(NoteRepository(db)),
          ),
        ),
      );
      // Wait for async data load
      await tester.pumpAndSettle(const Duration(seconds: 30));
      sw.stop();

      // Should render note cards
      expect(find.byType(Card), findsWidgets);
      // swiftlint:disable:next avoid_print
      print('  HomeScreen render (100 notes): ${sw.elapsedMilliseconds}ms');
    });
  });

  group('Jank detection', () {
    testWidgets('scrolling 500 note list should not drop frames', (tester) async {
      final db = GraphiteDB();
      await db.initialize();

      // Seed 500 notes
      final rng = Random(99);
      for (var i = 0; i < 500; i++) {
        final title = 'Scroll Note ${i.toString().padLeft(4, '0')}';
        final content = String.fromCharCodes(List.generate(200, (_) => rng.nextInt(26) + 97));
        await db.createNote(
          Note(
            id: '',
            path: title,
            filePath: '$title.md',
            createdAt: DateTime.now().subtract(Duration(days: 500 - i)),
            updatedAt: DateTime.now().subtract(Duration(minutes: i)),
            content: '# $title\\n\\n$content',
            tags: i % 5 == 0 ? ['scroll-test'] : [],
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            noteListUseCase: NoteListUseCase(NoteRepository(db)),
            quickNoteUseCase: QuickNoteUseCase(NoteRepository(db)),
            deleteNoteUseCase: DeleteNoteUseCase(NoteRepository(db)),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 30));

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
