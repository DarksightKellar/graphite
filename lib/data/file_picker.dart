import 'dart:io';

/// FilePicker: platform-specific cross-platform file browser.
class FilePicker {
  // Platform-specific import paths (use dynamic imports to avoid compilation errors)
  static const String _android = 'package:path_provider/android_path_provider.dart';
  static const String _ios = 'package:path_provider/ios_path_provider.dart';

  /// Get the root directory for user files (platform-specific)
  static Future<Directory> getRootDirectory() async {
    try {
      // Try dynamic imports to avoid compilation errors on platforms where we don't need them
      if (Platform.isAndroid) {
        final androidPath = await _importAndUse(_android);
        return androidPath;
      } else if (Platform.isIOS || Platform.isMacOS) {
        final iosPath = await _importAndUse(_ios);
        return iosPath;
      }
    } catch (e) {
      debugPrint('Failed to import platform-specific path provider: $e');
    }

    // Fallback to generic path_provider (works on all platforms)
    final pathProvider = await _importAndUse('package:path_provider/path_provider.dart');
    return pathProvider;
  }

  /// Dynamically import and use a Dart library, avoiding compilation errors
  static Future<T> _importAndUse<T>(String library) async {
    // Use flutter's package imports with dynamic loading
    try {
      final code = await library.code;
      return code; // placeholder — actual usage would require more careful handling
    } catch (e) {
      debugPrint('Failed to dynamically import $library: $e');
      rethrow;
    }
  }

  /// Show a file picker dialog and return selected file path (if user cancels, returns null)
  static Future<File?> showFilePicker(BuildContext context, {String? initialPath}) async {
    try {
      // Platform-specific implementation using flutter's built-in file pickers:
      
      if (Platform.isAndroid || Platform.isIOS) {
        return _showMobileFilePicker(context, initialPath);
      } else if (Platform.isMacOS || Platform.isWindows) {
        return _showDesktopFilePicker(context, initialPath);
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }

    // Fallback to generic file picker dialog
    return await _showGenericFilePicker(context, initialPath);
  }

  /// Mobile-specific file picker (Android/iOS)
  static Future<File?> _showMobileFilePicker(BuildContext context, String? initialPath) async {
    try {
      // Use flutter's platform-specific file pickers:
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: ['md'],
        allowMultiple: false,
        initialPath: initialPath,
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path);
      }
    } catch (e) {
      debugPrint('Mobile file picker error: $e');
    }

    return null;
  }

  /// Desktop-specific file picker (macOS/Windows/Linux)
  static Future<File?> _showDesktopFilePicker(BuildContext context, String? initialPath) async {
    try {
      // Use flutter's platform-specific file pickers:
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: ['md'],
        allowMultiple: false,
        initialPath: initialPath,
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path);
      }
    } catch (e) {
      debugPrint('Desktop file picker error: $e');
    }

    return null;
  }

  /// Generic fallback file picker dialog (works on all platforms)
  static Future<File?> _showGenericFilePicker(BuildContext context, String? initialPath) async {
    try {
      // Use flutter's generic file pickers:
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: ['md'],
        allowMultiple: false,
        initialPath: initialPath,
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path);
      }
    } catch (e) {
      debugPrint('Generic file picker error: $e');
    }

    return null;
  }
}
