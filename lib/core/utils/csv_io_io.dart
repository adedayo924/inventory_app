import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Saves a text file via the system "Save As" picker so the user always
/// chooses the destination location.
///
/// On Android/iOS the `file_picker` plugin requires the content as [bytes]
/// and writes it directly through the OS document picker (SAF on Android).
/// On desktop it returns a real filesystem path which we write ourselves.
///
/// Returns the path of the saved file, or null if the user cancelled.
/// Never falls back to a silent default location.
Future<String?> saveTextFileToDisk(String csvString, String fileName) async {
  // UTF-8 BOM prefix keeps Excel from mangling the encoded currency symbol.
  final bytes = utf8.encode('\uFEFF$csvString');

  try {
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $fileName',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: bytes,
    );

    if (outputPath == null) return null; // user cancelled

    if (!Platform.isAndroid && !Platform.isIOS) {
      final file = File(outputPath);
      await file.writeAsString(csvString, encoding: utf8);
    }
    return outputPath;
  } catch (e) {
    debugPrint('$fileName save error: $e');
    return null;
  }
}

Future<String> readTextFileFromDisk(String path) async =>
    await File(path).readAsString(encoding: utf8);