/// On web the database is persisted by the sqlite web worker (IndexedDB),
/// so the "path" is just the logical database file name.
Future<String> resolveDatabasePath(String fileName) async => fileName;
