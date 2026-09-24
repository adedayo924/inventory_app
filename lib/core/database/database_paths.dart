import 'database_paths_io.dart'
    if (dart.library.html) 'database_paths_web.dart' as platform;

/// Resolves the database file location for the current platform.
Future<String> resolveDatabasePath(String fileName) =>
    platform.resolveDatabasePath(fileName);
