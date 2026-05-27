import 'package:graphite/data/database.dart';
import 'package:graphite/models/note.dart';
import 'package:graphite/models/tag.dart';

/// A fake database that stores notes and tags in memory for widget testing.
/// Avoids sqflite_common_ffi native library issues on WSL.
class FakeGraphiteDB extends GraphiteDB {
  final List<Note> notes = [];
  final Map<String, Set<String>> _links = {}; // noteId -> set of link targets
  bool _initialized = false;

  /// Whether [initialize] has been called.
  bool get initialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<List<Note>> listNotes() async => List.unmodifiable(notes);

  @override
  Future<Note?> readNote(String noteId) async {
    try {
      return notes.firstWhere((n) => n.id == noteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final lower = query.toLowerCase();
    return notes.where((n) => n.content.toLowerCase().contains(lower)).toList();
  }

  @override
  Future<Note> createNote(Note note) async {
    final id = note.path.hashCode.toString();
    final created = note.copyWith(id: id);
    notes.add(created);
    return created;
  }

  @override
  Future<void> updateNote(Note note) async {
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      notes[index] = note;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    notes.removeWhere((n) => n.id == noteId);
    _links.remove(noteId);
  }

  @override
  Future<int> getLinkCount(String noteId) async =>
      (_links[noteId]?.length) ?? 0;

  @override
  Future<List<Note>> getNotesByTag(String tag) async =>
      notes.where((n) => n.tags.contains(tag)).toList();

  @override
  Future<List<Note>> getNotesWithLinks() async =>
      notes.where((n) => (_links[n.id]?.isNotEmpty ?? false)).toList();

  @override
  Future<List<Tag>> getAllTags() async {
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

  @override
  Future<Note?> findNoteByTitle(String title) async {
    try {
      return notes.firstWhere(
          (n) => n.path.toLowerCase() == title.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> extractLinks(String noteId, String content) async {
    final linkPattern = RegExp(r'\[\[(.+?)\]\]');
    final targets = linkPattern
        .allMatches(content)
        .map((m) => m.group(1)!.trim())
        .where((t) => t.isNotEmpty)
        .toSet();
    _links[noteId] = targets;
  }

  /// Inject links for testing.
  void addLinks(String noteId, Set<String> targets) {
    _links[noteId] = targets;
  }
}
