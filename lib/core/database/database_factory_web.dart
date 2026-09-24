import 'package:sqflite_common/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Sets up the global [databaseFactory] for web using a persistent SQLite
/// worker backed by IndexedDB. Requires `web/sqlite3.wasm` and `web/sqflite_sw.js`.
Future<void> initializeDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWeb;
}
