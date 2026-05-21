import 'dart:io';

import '../data/database.dart';
import '../data/file_repository.dart';
import '../models/note.dart';

/// Coordinates between SQLite persistence (primary) and file system
/// (backup/export).
///
/// All reads go through the database. Writes go to the database first,
/// then to the file system for backup/export.
class NoteRepository {
  final GraphiteDB _db;
  final FileRepository _fileSystem;

  NoteRepository(this._db, this._fileSystem);

  // ── CRUD ────────────────────────────────────────────────────────────

  /// Insert a new note. Persists to DB, then writes the markdown file.
  Future<Note> createNote(Note note) async {
    final saved = await _db.createNote(note);

    try {
      await _fileSystem.writeNote(saved.path, saved.content);
    } catch (e) {
      // File write is best-effort backup; don't fail the operation.
    }

    return saved;
  }

  /// Read a note by its id. Returns `null` if not found.
  Future<Note?> readNote(String id) async {
    return _db.readNote(id);
  }

  /// Update an existing note's content and metadata.
  Future<void> updateNote(Note note) async {
    await _db.updateNote(note);

    try {
      await _fileSystem.writeNote(note.path, note.content);
    } catch (e) {
      // File write is best-effort.
    }
  }

  /// Delete a note by id. Removes from DB and file system.
  Future<void> deleteNote(String id) async {
    final note = await _db.readNote(id);
    await _db.deleteNote(id);

    if (note != null) {
      try {
        final filePath = _fileSystem.getNotePath(note.path);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // File deletion is best-effort.
      }
    }
  }

  /// List all notes, newest first.
  Future<List<Note>> listAllNotes() async {
    return _db.listNotes();
  }

  /// Search notes by content or path using LIKE pattern matching.
  Future<List<Note>> searchNotes(String query) async {
    return _db.searchNotes(query);
  }

  /// Returns a note's relative path without the .md extension.
  String getRelativePath(String absolutePath) {
    return _fileSystem.getRelativePath(absolutePath);
  }
}
