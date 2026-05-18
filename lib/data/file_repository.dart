import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Abstracts file system operations across all platforms.
/// This is the "filesystem router" pattern for local-first apps.
class FileRepository {
  /// The root directory where user notes are stored (the "vault")
  late Directory vaultRoot;

  FileRepository() {
    _initVault();
  }

  Future<void> _initVault() async {
    // Choose the appropriate data directory based on platform
    final dir = await getApplicationDocumentsDirectory(); // Android, iOS, Windows
    
    vaultRoot = Directory(dir.path + '/graphite_vault');
    
    if (!await vaultRoot.exists()) {
      await vaultRoot.create(recursive: true);
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
    _traverse(vaultRoot, (dir) {
      for (final child in dir.childrenSync()) {
        if (child is Directory) {
          _traverse(child, noteFiles.add);
        } else if (child.path.endsWith('.md')) {
          noteFiles.add(child.path.substring(vaultRoot.path.length + 1));
        }
      }
    });
    return noteFiles;
  }

  void _traverse(Directory dir, dynamic action) {
    for (final child in dir.childrenSync()) {
      if (child is Directory) {
        action(child);
      }
    }
  }

  /// Gets the relative path from vault root to a given absolute path.
  String getRelativePath(String absolutePath) {
    return absolutePath.substring(vaultRoot.path.length + 1);
  }
}
