import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Abstracts file system operations across all platforms.
/// This is the "filesystem router" pattern for local-first apps.
class FileRepository {
  Directory? _vaultRoot;

  /// The root directory where user notes are stored (the "vault").
  /// Must call [init] before accessing.
  Directory get vaultRoot {
    final root = _vaultRoot;
    if (root == null) {
      throw StateError('FileRepository not initialized. Call init() first.');
    }
    return root;
  }

  /// Initializes the vault directory.
  ///
  /// If [vaultDir] is provided (e.g., in tests), uses that directory.
  /// Otherwise, resolves the platform-appropriate application documents
  /// directory and creates a 'graphite_vault' subdirectory within it.
  Future<void> init({Directory? vaultDir}) async {
    if (vaultDir != null) {
      _vaultRoot = vaultDir;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _vaultRoot = Directory('${dir.path}/graphite_vault');
    }

    if (!await _vaultRoot!.exists()) {
      await _vaultRoot!.create(recursive: true);
    }
  }

  /// Returns the absolute path to a note's markdown file.
  String getNotePath(String relativePath) {
    return '${vaultRoot.path}/$relativePath.md';
  }

  /// Checks if a note file exists at the given path.
  Future<bool> noteExists(String relativePath) async {
    final fullpath = getNotePath(relativePath);
    return File(fullpath).existsSync();
  }

  /// Reads the entire content of a markdown file.
  Future<String> readNote(String relativePath) async {
    final fullpath = getNotePath(relativePath);
    return await File(fullpath).readAsString();
  }

  /// Writes new content to a note, creating or overwriting the file.
  Future<void> writeNote(String relativePath, String content) async {
    final fullpath = getNotePath(relativePath);
    // Create parent directories if they don't exist
    final dir = File(fullpath).parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    await File(fullpath).writeAsString(content);
  }

  /// Lists all .md files recursively from the vault root.
  Future<List<String>> listAllNotes() async {
    final noteFiles = <String>[];
    _traverse(vaultRoot, (Directory dir) {
      for (final child in dir.listSync()) {
        if (child is File && child.path.endsWith('.md')) {
          noteFiles.add(child.path.substring(vaultRoot.path.length + 1));
        }
      }
    });
    return noteFiles;
  }

  /// Recursively traverses directories, calling [action] on each
  /// directory encountered (including [dir] itself on the first call
  /// if callers pass a root).
  void _traverse(Directory dir, void Function(Directory) action) {
    action(dir);
    for (final child in dir.listSync()) {
      if (child is Directory) {
        _traverse(child, action);
      }
    }
  }

  /// Gets the relative path from vault root to a given absolute path.
  String getRelativePath(String absolutePath) {
    return absolutePath.substring(vaultRoot.path.length + 1);
  }
}
