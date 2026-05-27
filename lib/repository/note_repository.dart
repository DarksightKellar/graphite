import 'dart:io';

import '../data/database.dart';
import '../data/file_repository.dart';
import '../models/note.dart';
import '../models/tag.dart';

/// Coordinates between SQLite persistence (primary) and file system
/// (backup/export).
///
/// All reads go through the database. Writes go to the database first,
/// then to the file system for backup/export.
class NoteRepository {
  final GraphiteDB _db;
  final FileRepository? _fileSystem;

  NoteRepository(this._db, [this._fileSystem]);

  // ── CRUD ────────────────────────────────────────────────────────────

  /// Insert a new note. Persists to DB, then writes the markdown file.
  Future<Note> createNote(Note note) async {
    final saved = await _db.createNote(note);

    try {
      await _fileSystem?.writeNote(saved.path, saved.content);
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
      await _fileSystem?.writeNote(note.path, note.content);
    } catch (e) {
      // File write is best-effort.
    }
  }

  /// Delete a note by id. Removes from DB and file system.
  Future<void> deleteNote(String id) async {
    final note = await _db.readNote(id);
    await _db.deleteNote(id);

    if (note != null && _fileSystem != null) {
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
    return _fileSystem?.getRelativePath(absolutePath) ?? absolutePath;
  }

  // ── Delegated DB operations ─────────────────────────────────────────

  /// Initialize the underlying database (idempotent).
  Future<void> initialize() async {
    await _db.initialize();
  }

  /// Extract [[wiki-links]] from markdown content and store in graph.
  Future<void> extractLinks(String noteId, String content) async {
    await _db.extractLinks(noteId, content);
  }

  /// Find a note by its title/path, case-insensitive.
  Future<Note?> findNoteByTitle(String title) async {
    return _db.findNoteByTitle(title);
  }

  /// Count outgoing links for a note.
  Future<int> getLinkCount(String noteId) async {
    return _db.getLinkCount(noteId);
  }

  /// Get all notes that have outgoing wiki-links.
  Future<List<Note>> getNotesWithLinks() async {
    return _db.getNotesWithLinks();
  }

  /// Get all notes tagged with [tag].
  Future<List<Note>> getNotesByTag(String tag) async {
    return _db.getNotesByTag(tag);
  }

  /// Get all unique tags across all notes with their note counts.
  Future<List<Tag>> getAllTags() async {
    return _db.getAllTags();
  }
}
