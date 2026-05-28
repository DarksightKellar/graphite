// Performance benchmarks for Graphite MVP targets.
// Run with: dart run bench_runner.dart
//
// Note: This uses sqflite_common_ffi for desktop benchmarking since
// sqflite proper requires a mobile platform.

import 'dart:math';
import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Replicate the database schema and methods from GraphiteDB
// to benchmark without Flutter dependencies.

const notesTable = '''
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL UNIQUE,
  file_path TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  content TEXT NOT NULL,
  tags TEXT NOT NULL DEFAULT '[]'
)
''';

const tagsTable = '''
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  note_count INTEGER NOT NULL DEFAULT 0
)
''';

const linksTable = '''
CREATE TABLE links (
  from_note_id TEXT NOT NULL,
  to_note_title TEXT NOT NULL,
  weight INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (from_note_id, to_note_title)
)
''';

String hashFilename(String filename) {
  final codeUnits = filename.codeUnits;
  var hash = 0;
  for (var i = 0; i < codeUnits.length; i++) {
    final character = codeUnits[i];
    hash = ((hash << 5) - hash) + character;
    hash &= hash;
  }
  return hash.toString();
}

Future<Database> createDb(String path) async {
  final db = await openDatabase(
    path,
    version: 3,
    onCreate: (db, version) async {
      await db.execute(notesTable);
      await db.execute(tagsTable);
      await db.execute(linksTable);
    },
  );
  return db;
}

Future<void> insertNote(
  Database db, {
  required String title,
  required int createdAt,
  required int updatedAt,
  required String content,
}) async {
  final id = hashFilename(title);
  await db.insert('notes', {
    'id': id,
    'path': title,
    'file_path': '$title.md',
    'created_at': createdAt,
    'updated_at': updatedAt,
    'content': content,
    'tags': '[]',
  });
}

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('=== Graphite Performance Benchmarks ===\n');
  print('Targets: Cold start <2s | Search <500ms p95 | First note <30s');
  print('');

  // ── Cold start (DB init) ──────────────────────────────────
  var sw = Stopwatch()..start();
  final db = await createDb('benchmark_cold.db');
  sw.stop();
  final coldInitMs = sw.elapsedMilliseconds;
  final coldResult = coldInitMs < 2000 ? 'PASS' : 'FAIL';
  print('Cold start (DB init):     ${coldInitMs}ms [$coldResult]');
  final coldMs = coldInitMs;

  // ── Seed benchmark data ───────────────────────────────────
  final rng = Random(42);
  final sizes = [100, 200, 500];

  // Pre-seed 500 notes for measurement
  sw = Stopwatch()..start();
  final batch = <Map<String, dynamic>>[];
  for (var i = 0; i < 500; i++) {
    final title = 'Note ${i.toString().padLeft(4, '0')}';
    final content = String.fromCharCodes(List.generate(200, (_) => rng.nextInt(26) + 97));
    batch.add({
      'id': hashFilename(title),
      'path': title,
      'file_path': '$title.md',
      'created_at': DateTime.now().subtract(Duration(days: 500 - i)).millisecondsSinceEpoch,
      'updated_at': DateTime.now().subtract(Duration(minutes: i)).millisecondsSinceEpoch,
      'content': '# $title\n\n$content',
      'tags': '[]',
    });
  }

  // Batch insert
  for (final row in batch) {
    await db.insert('notes', row);
  }
  sw.stop();
  final bulkInsertMs = sw.elapsedMilliseconds;
  print('Bulk insert (500 notes):  ${bulkInsertMs}ms (${(bulkInsertMs / 500).toStringAsFixed(1)}ms/note)');

  // ── Search benchmarks ─────────────────────────────────────
  var searchMs = 0;
  for (final size in sizes) {
    // Use a subset of data
    final searchSw = Stopwatch()..start();
    final pattern = '%note 0001%';
    final rows = await db.query(
      'notes',
      where: "LOWER(content) LIKE ? OR LOWER(path) LIKE ?",
      whereArgs: [pattern, pattern],
      orderBy: 'updated_at DESC',
      limit: 50,
    );
    searchSw.stop();
    searchMs = searchSw.elapsedMilliseconds;
    final searchResult = searchMs < 500 ? 'PASS' : 'FAIL';
    print('Search (~$size in 500):      ${searchMs}ms (${rows.length} results) [$searchResult]');
  }

  // ── List notes benchmark ──────────────────────────────────
  sw = Stopwatch()..start();
  final allRows = await db.query('notes', orderBy: 'updated_at DESC');
  sw.stop();
  final listAllMs = sw.elapsedMilliseconds;
  print('List all (500 notes):      ${listAllMs}ms (${allRows.length} notes)');

  // ── Summary ───────────────────────────────────────────────
  print('');
  print('=== Results ===');
  print('Cold start: $coldResult (${coldMs}ms / <2000ms)');
  print('Search (500): ${searchMs < 500 ? 'PASS' : 'FAIL'} (${searchMs}ms / <500ms)');
  print('');

  // Cleanup
  await db.close();
  // Delete the database file
  await databaseFactoryFfi.deleteDatabase('benchmark_cold.db');
}
