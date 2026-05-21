import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  final dbPath = await getDatabasesPath();
  print('DB path: $dbPath');
  
  final db = await openDatabase('$dbPath/test.db', version: 1,
    onCreate: (db, version) async {
      await db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)');
      await db.insert('test', {'value': 'hello'});
    },
  );
  
  final rows = await db.query('test');
  print('Rows: $rows');
  await db.close();
  print('OK');
}
