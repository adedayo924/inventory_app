import 'database_factory_io.dart'
    if (dart.library.html) 'database_factory_web.dart' as platform;

/// Initializes the SQLite database factory for the current platform.
/// Safe to call once on startup and idempotent.
Future<void> initializeDatabaseFactory() => platform.initializeDatabaseFactory();
