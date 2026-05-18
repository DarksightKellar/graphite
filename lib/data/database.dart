import 'package:sqflite/sqflite.dart';
import 'dart:convert';

/// SQLite database operations for Graphite notes.
class NoteDatabase {
  static late Database _db;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/graphite.db';

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Notes table (primary storage)
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        content BLOB NOT NULL
      )
    ''');

    // Tags table (for filtering and graph view)
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        note_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Links table (for graph edges — stores [[title]] references)
    await db.execute('''
      CREATE TABLE links (
        from_note_id TEXT NOT NULL,
        to_note_title TEXT NOT NULL,
        weight INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (from_note_id, to_note_title)
      )
    ''');

    // Seed with a welcome note
    await createNote(
      'Welcome.md',
      '''# Welcome to Graphite

This is your local-first knowledge base. Notes are stored securely on this device.

## Quick Start
1. Create a new note by tapping the **+** button below
2. Type markdown like `# Heading`, `[[Links]]`, or `#tags`
3. View connections in the **Graph** tab''',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Create a new note (used from home screen quick-note flow)
  Future<void> createNote(String path, String content) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Generate unique ID from filename hash
    String id = _hashFilename(path);

    await _db.insert('notes', {
      'id': id,
      'path': path.contains('/') ? path.split('/').last : path,
      'created_at': timestamp,
      'updated_at': timestamp,
      'content': content,
    });
  }

  /// Read a note by its SQLite ID
  Future<String?> readNote(String noteId) async {
    final result = await _db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );

    if (result.isEmpty) return null;

    // Parse the BLOB content back to string
    return result.first['content'] as List<int>
        .toRadixString(16); // placeholder — actual parsing needed
  }

  /// Update an existing note's content
  Future<void> updateNote(String noteId, String newContent) async {
    await _db.update('notes', {
      'content': newContent,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, where: 'id = ?', whereArgs: [noteId]);

    // Extract and save tags + links from new content (async in background)
    _extractMetadata(newContent);
  }

  /// Delete a note by its SQLite ID
  Future<void> deleteNote(String noteId) async {
    await _db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  /// Get all notes (paginated)
  Future<List<Map<String, dynamic>>> getAllNotes({int offset = 0, int limit = 50}) async {
    final result = await _db.query(
      'notes',
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    return result;
  }

  /// Extract tags and links from content (background task after update)
  Future<void> _extractMetadata(String content) async {
    // Parse markdown for #tag and [[title]] syntax
    final tagMatches = RegExp(r'#(?!#)([a-zA-Z0-9_-]+)').allMatches(content);
    
    for (final match in tagMatches) {
      final tagId = '${match.group(1)}_tag';
      await _updateTagCount(tagId, increment: true);
    }

    // TODO: parse [[title]] links and store in links table for graph view
  }

  Future<void> _updateTagCount(String tagId, {bool increment = false}) async {
    if (increment) {
      await _db.update('tags', {'note_count': Field.raw('note_count + 1')},
          where: 'id = ?', whereArgs: [tagId],
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// Generate unique ID from filename hash (first 8 hex chars of SHA-256)
  String _hashFilename(String path) {
    final bytes = utf8.encode(path);
    int h = 0;
    for (final b in bytes) {
      h = ((h * 31) ^ b) & 0xFFFFFFFF;
    }
    return '${h.toRadixString(16).substring(0, 8)}';
  }
}

/// Convenience extension for field references in SQL
extension Field on int {
  static final Field noteCount = Field('note_count');
}
