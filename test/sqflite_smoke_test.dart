import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test('sqflite_common_ffi works in test environment', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    print('getDatabasesPath: $dbPath');

    final db = await openDatabase(
      '$dbPath/smoke_test.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)',
        );
        await db.insert('test', {'value': 'hello from smoke'});
      },
    );

    final rows = await db.query('test');
    expect(rows, hasLength(1));
    expect(rows.first['value'], 'hello from smoke');

    await db.close();
  });
}
