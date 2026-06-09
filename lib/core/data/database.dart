import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/note.dart';
import '../models/tag.dart';

/// Cross-platform SQLite database helper for Graphite.
///
/// All CRUD methods accept and return [Note] model objects.
/// The database is the primary storage; the file system is a
/// backup/export layer managed by [NoteRepository].
class GraphiteDB {
  static late Database _db;
  static String _dbDirPath = '';
  static bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _dbDirPath = await getDatabasesPath();
    final path = '$_dbDirPath/graphite.db';

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _initialized = true;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Notes table (primary storage)
    await db.execute('''
    CREATE TABLE notes (
      id TEXT PRIMARY KEY,
      path TEXT NOT NULL UNIQUE,
      file_path TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      content TEXT NOT NULL,
      tags TEXT NOT NULL DEFAULT '[]'
    )
    ''');

    // Tags table (for filtering / tag browser)
    await db.execute('''
    CREATE TABLE tags (
      id TEXT PRIMARY KEY,
      note_count INTEGER NOT NULL DEFAULT 0
    )
    ''');

    // Links table (stores [[title]] references from all notes)
    await db.execute('''
    CREATE TABLE links (
      from_note_id TEXT NOT NULL,
      to_note_title TEXT NOT NULL,
      weight INTEGER NOT NULL DEFAULT 1,
      PRIMARY KEY (from_note_id, to_note_title)
    )
    ''');

    // Seed with a welcome note
    final welcome = Note(
      id: _hashFilename('Welcome'),
      path: 'Welcome',
      filePath: 'Welcome.md',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: '# Welcome to Graphite #welcome\n\n'
          'Your personal, local-first notes app. '
          'Everything stays on this device — no accounts, no cloud, no setup.\n\n'
          '## Getting Started\n'
          '• Create a new note by tapping the **+** button below\n'
          '• Write in markdown: use `# Headings`, **bold**, *italic*, and more\n'
          '• Link ideas with `[[double brackets]]` — connect notes like wiki pages\n'
          '• Tag notes with `#hashtags` to organize and filter your thoughts\n\n'
          'Happy note-taking!',
      tags: const ['welcome'],
    );
    await _insertNoteRow(db, welcome);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: rebuild tables (content was BLOB, now TEXT)
      await db.execute('DROP TABLE IF EXISTS notes');
      await db.execute('DROP TABLE IF EXISTS tags');
      await db.execute('DROP TABLE IF EXISTS links');
      await _onCreate(db, 2);
    }
    if (oldVersion < 3) {
      // v2 → v3: add file_path and tags columns
      await db.execute('ALTER TABLE notes ADD COLUMN file_path TEXT NOT NULL DEFAULT ""');
      await db.execute('ALTER TABLE notes ADD COLUMN tags TEXT NOT NULL DEFAULT "[]"');
    }
  }

  // ── CRUD (returning Note objects) ────────────────────────────────────

  /// Insert a note. Returns the same [Note] with the assigned id.
  Future<Note> createNote(Note note) async {
    final id = _hashFilename(note.path);
    final row = _noteToRow(note, id: id);
    await _db.insert('notes', row);
    return note.copyWith(id: id);
  }

  /// Read a note by its id. Returns `null` if not found.
  Future<Note?> readNote(String noteId) async {
    final result = await _db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );

    if (result.isEmpty) return null;
    return _rowToNote(result.first);
  }

  /// Update a note's content and metadata.
  Future<void> updateNote(Note note) async {
    await _db.update(
      'notes',
      _noteToRow(note, id: note.id),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Delete a note by id.
  Future<void> deleteNote(String noteId) async {
    await _db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  /// List all notes ordered by last update time (most recent first).
  Future<List<Note>> listNotes() async {
    final rows = await _db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(_rowToNote).toList();
  }

  /// Search notes by content and path with case-insensitive LIKE matching.
  /// Ordered by updated_at DESC, limited to 50 results for performance.
  Future<List<Note>> searchNotes(String query) async {
    final pattern = '%${query.toLowerCase()}%';
    final rows = await _db.query(
      'notes',
      where: 'LOWER(content) LIKE ? OR LOWER(path) LIKE ?',
      whereArgs: [pattern, pattern],
      orderBy: 'updated_at DESC',
      limit: 50,
    );
    return rows.map(_rowToNote).toList();
  }

  // ── Row ↔ Note conversion ───────────────────────────────────────────

  Note _rowToNote(Map<String, dynamic> row) {
    return Note(
      id: row['id'] as String,
      path: row['path'] as String,
      filePath: row['file_path'] as String,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      content: row['content'] as String,
      tags: List<String>.from(
          (jsonDecode(row['tags'] as String) as List<dynamic>).cast()),
    );
  }

  Map<String, dynamic> _noteToRow(Note note, {String? id}) {
    return {
      'id': id ?? note.id,
      'path': note.path,
      'file_path': note.filePath,
      'created_at': note.createdAt.millisecondsSinceEpoch,
      'updated_at': note.updatedAt.millisecondsSinceEpoch,
      'content': note.content,
      'tags': jsonEncode(note.tags),
    };
  }

  /// Convenience: insert a note row directly (used during seeding).
  Future<void> _insertNoteRow(Database db, Note note) async {
    await db.insert('notes', _noteToRow(note));
  }

  // ── Graph helpers ────────────────────────────────────────────────────

  /// Extract [[title]] links from markdown content and store in graph.
  /// Deletes old links for this note before inserting new ones to keep
  /// the link set in sync with the note's current content.
  Future<void> extractLinks(String noteId, String content) async {
    // Delete old links first so re-saves don't accumulate stale links
    await _db.delete(
      'links',
      where: 'from_note_id = ?',
      whereArgs: [noteId],
    );

    final linkPattern = RegExp(r'\[\[(.+?)\]\]');
    final matches = linkPattern.allMatches(content);

    for (final match in matches) {
      final title = match.group(1)!.trim();
      if (title.isEmpty) continue;
      await _db.insert('links', {
        'from_note_id': noteId,
        'to_note_title': title,
        'weight': 1,
      });
    }
  }

  /// Find notes whose title is referenced by links (incoming backlinks).
  Future<List<Map<String, dynamic>>> getIncomingLinks(String title) async {
    return await _db.query(
      'links',
      where: 'to_note_title = ?',
      whereArgs: [title],
    );
  }

  /// Get all links for a specific note (graph traversal / outgoing links).
  Future<List<Map<String, dynamic>>> getOutgoingLinks(
      String fromNoteId) async {
    return await _db.query(
      'links',
      where: 'from_note_id = ?',
      whereArgs: [fromNoteId],
    );
  }

  /// Count outgoing links for a note (for badge display).
  Future<int> getLinkCount(String noteId) async {
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as cnt FROM links WHERE from_note_id = ?',
      [noteId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete all links from and to a note (use when deleting a note).
  Future<void> deleteLinksForNote(String noteId) async {
    await _db.delete(
      'links',
      where: 'from_note_id = ?',
      whereArgs: [noteId],
    );
  }

  /// Find a note by its title/path, case-insensitive.
  /// Returns null if no note matches.
  Future<Note?> findNoteByTitle(String title) async {
    final results = await _db.query(
      'notes',
      where: 'LOWER(path) = ?',
      whereArgs: [title.toLowerCase()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _rowToNote(results.first);
  }

  // ── Tag helpers ──────────────────────────────────────────────────────

  /// Get all unique tags across all notes with their note counts.
  Future<List<Tag>> getAllTags() async {
    final notes = await listNotes();
    final counts = <String, int>{};
    for (final note in notes) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts.entries
        .map((e) => Tag(id: e.key, noteCount: e.value))
        .toList();
  }

  /// Get all notes that have the given tag.
  /// Uses SQL LIKE on the JSON tags column for server-side filtering.
  Future<List<Note>> getNotesByTag(String tag) async {
    final pattern = '%"$tag"%';
    final rows = await _db.query(
      'notes',
      where: 'tags LIKE ?',
      whereArgs: [pattern],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_rowToNote).toList();
  }

  /// Get all notes that have outgoing wiki-links.
  Future<List<Note>> getNotesWithLinks() async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT n.* FROM notes n
      INNER JOIN links l ON l.from_note_id = n.id
      ORDER BY n.updated_at DESC
    ''');
    return rows.map(_rowToNote).toList();
  }

  /// Hash function for generating unique IDs from filenames.
  String _hashFilename(String filename) {
    final codeUnits = filename.codeUnits;
    var hash = 0;
    for (var i = 0; i < codeUnits.length; i++) {
      final character = codeUnits[i];
      hash = ((hash << 5) - hash) + character;
      hash &= hash;
    }
    return hash.toString();
  }

  /// Reset static state for testing. Call between independent test runs.
  static void resetForTesting() {
    _initialized = false;
  }
}
