import 'dart:io';
import '../models/note.dart';
import '../data/file_repository.dart';
import '../utils/markdown_parser.dart';

/// The central business logic for note CRUD operations.
class NoteRepository {
  final FileRepository _fileSystem;

  NoteRepository(this._fileSystem);

  /// Creates a new note file and returns its absolute path.
  Future<String> createNote(String relativePath, String content) async {
    // Generate unique ID from filename hash
    final id = _hashFilename(relativePath);
    
    await _fileSystem.writeNote(
      relativePath,
      content,
    );

    return '$relativePath#$id';
  }

  /// Reads a note and returns its absolute path + parsed metadata.
  Future<({String id, String path, String filePath, DateTime createdAt, 
      DateTime updatedAt, NoteData parsed})> readNote(String relativePath) async {
    final fullpath = _fileSystem.getNotePath(relativePath);
    if (!await File(fullpath).exists()) throw FileSystemException('not found');

    final fileStat = await File(fullpath).stat();
    
    return (
      id: relativePath.hashCode.toString(),
      path: relativePath,
      filePath: fullpath,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fileStat.birthTime),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(fileStat.modified),
      parsed: MarkdownParser.parseMarkdown(relativePath, await _fileSystem.readNote(relativePath)),
    );
  }

  /// Updates an existing note's content.
  Future<void> updateNote(String relativePath, String newContent) async {
    // Write the file first
    final fullpath = _fileSystem.getNotePath(relativePath);
    final dir = File(fullpath).parent;
    if (!await dir.exists()) await dir.create(recursive: true);
    await File(fullpath).writeAsString(newContent);

    // Now parse and extract new metadata
    final parsed = MarkdownParser.parseMarkdown(
      relativePath, 
      await _fileSystem.readNote(relativePath)
    );
  }

  /// Deletes a note file from disk.
  Future<void> deleteNote(String relativePath) async {
    await File(_fileSystem.getNotePath(relativePath)).delete();
  }

  /// Lists all notes with their basic metadata.
  Future<List<Note>> listAllNotes() async {
    final paths = await _fileSystem.listAllNotes();
    return Future.wait(
      paths.map((path) => readNote(path).then((data) => Note(
        id: data.id,
        path: data.path,
        filePath: data.filePath,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
        content: '', // Content loaded lazily if needed
        tags: [], // Parse on-demand or in background
      ))
    ).then((notes) => notes);
  }

  /// Returns a note's relative path without the .md extension.
  String getRelativePath(String absolutePath) {
    return _fileSystem.getRelativePath(absolutePath);
  }
}

/// Helper: hash a filename string into a short ID (first 8 chars of SHA-256)
String _hashFilename(String path) {
  final bytes = utf8.encode(path);
  final hash = <int>{};
  for (var i = 0; i < bytes.length; i += 4) {
    final chunk = bytes.sublist(i, i + 4);
    final combined = hash.fold(0, (acc, val) => acc ^ val);
    // Simple rolling hash
    int h = 5381;
    for (final b in chunk) {
      h = ((h * 33) ^ b) & 0xFFFFFFFF;
    }
    return '${h.toRadixString(16).substring(0, 8)}';
  }
}
