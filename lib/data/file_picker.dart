import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart';

/// Cross-platform file picker that wraps package:file_picker.
class GraphiteFilePicker {
  /// Pick a single markdown file from device storage
  Future<File?> pickMarkdownFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['md'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;

        if (filePath != null && filePath.endsWith('.md')) {
          return File(filePath);
        }
      }
    } catch (e) {
      debugPrint('FilePicker error: $e');
    }

    return null;
  }

  /// Pick multiple markdown files at once
  Future<List<File>> pickMultipleMarkdownFiles() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['md'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      }
    } catch (e) {
      debugPrint('Multi-file picker error: $e');
    }

    return [];
  }

  /// Pick any file type (for future extensions)
  Future<File?> pickAnyFile() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path!);
      }
    } catch (e) {
      debugPrint('Any file picker error: $e');
    }

    return null;
  }
}
