/// Stub used on web where direct filesystem access is unavailable. The web
/// build reads file bytes via `file_picker`'s `withData` flag instead.
Future<String?> saveTextFileToDisk(String csvString, String fileName) async =>
    throw UnsupportedError('File system access is not available on this platform.');

Future<String> readTextFileFromDisk(String path) async =>
    throw UnsupportedError('File system access is not available on this platform.');