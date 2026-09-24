import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;

/// Resolves the absolute filesystem path for the SQLite database file on non-web platforms.
Future<String> resolveDatabasePath(String fileName) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getDatabasesPath();
    return p.join(dir, fileName);
  }
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, fileName);
}
