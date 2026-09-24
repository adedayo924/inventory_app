import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Sets up the global [databaseFactory] for desktop platforms (Windows/Linux/macOS).
/// On Android/iOS the sqflite plugin provides its own default factory, so this
/// is intentionally a no-op there.
Future<void> initializeDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
