import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphite/data/database.dart';
import 'package:graphite/models/note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late String testDbDir;

  setUpAll(() async {
    sqfliteFfiInit();
    testDbDir =
        '${Directory.systemTemp.path}/graphite_dbonly_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(testDbDir).create(recursive: true);
    databaseFactory = databaseFactoryFfi;
    databaseFactoryFfi.setDatabasesPath(testDbDir);
  });

  tearDownAll(() async {
    if (await Directory(testDbDir).exists()) {
      await Directory(testDbDir).delete(recursive: true);
    }
  });

  test('DB create and read from different GraphiteDB instances', () async {
    // Instance 1: create
    final db1 = GraphiteDB();
    await db1.initialize();
    final note = await db1.createNote(Note(
      id: '',
      path: 'Hello',
      filePath: 'hello.md',
      createdAt: DateTime(2025, 6, 1),
      updatedAt: DateTime(2025, 6, 1),
      content: '# Hi',
      tags: const [],
    ));

    // Instance 2: read (same static DB)
    final db2 = GraphiteDB();
    final read = await db2.readNote(note.id);
    expect(read, isNotNull);
    expect(read!.content, '# Hi');
  });
}
