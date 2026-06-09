import 'package:graphite/core/models/note.dart';
import 'package:graphite/core/repository/note_repository.dart';

/// Extracts #hashtag patterns from content.
final _tagPattern = RegExp(r'#[a-zA-Z0-9_-]+');

/// Saves a note's content, creating or updating as needed,
/// and extracts wiki-links and #tags afterward.
class SaveNoteUseCase {
  final NoteRepository _repo;

  SaveNoteUseCase(this._repo);

  /// Initialize the underlying database (idempotent).
  Future<void> initialize() async {
    await _repo.initialize();
  }

  /// Read a note by its id. Returns `null` if not found.
  Future<Note?> readNote(String id) async {
    return _repo.readNote(id);
  }

  /// Saves [content] for the note identified by [noteId].
  ///
  /// If the note already exists, it is updated in place preserving its
  /// original [Note.path], [Note.filePath], and [Note.createdAt].
  /// #tags are re-extracted from content on every save.
  ///
  /// If the note does not exist, a new one is created with [noteId] as
  /// both [Note.path] and [Note.filePath].
  ///
  /// After saving, [[wiki-links]] are extracted from the content.
  ///
  /// Returns the saved [Note].
  Future<Note> call(String noteId, String content) async {
    final tags = _extractTags(content);
    final existing = await _repo.readNote(noteId);

    if (existing != null) {
      final updated = existing.copyWith(
        content: content,
        updatedAt: DateTime.now(),
        tags: tags,
      );
      await _repo.updateNote(updated);
      await _repo.extractLinks(noteId, content);
      return updated;
    } else {
      final created = await _repo.createNote(
        Note(
          id: noteId,
          path: noteId,
          filePath: noteId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          content: content,
          tags: tags,
        ),
      );
      await _repo.extractLinks(created.id, content);
      return created;
    }
  }

  /// Extract unique #hashtags from content, preserving the # prefix.
  List<String> _extractTags(String content) {
    return _tagPattern
        .allMatches(content)
        .map((m) => m.group(0)!)
        .toSet()
        .toList();
  }
}
