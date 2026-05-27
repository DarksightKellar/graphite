import 'dart:io';

/// Cross-platform file system abstraction layer.
class FileSystem {
  /// List files and directories in a path (recursive)
  Future<List<FileSystemEntity>> listDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) return [];

    final entities = <FileSystemEntity>[];
    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      entities.add(entity);
    }
    return entities.whereType<File>().toList();
  }

  /// Read file as string
  Future<String> readFileAsString(String path) async {
    final file = File(path);
    if (!await file.exists()) throw FileSystemException('File not found', path);
    return await file.readAsString();
  }

  /// Write content to file
  Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  /// Check if a path exists
  static Future<bool> exists(String path) async {
    return (await Directory(path).exists()) ||
        (await File(path).exists());
  }
}
