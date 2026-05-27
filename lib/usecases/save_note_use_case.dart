import '../models/note.dart';
import '../repository/note_repository.dart';

/// Saves a note's content, creating or updating as needed,
/// and extracts wiki-links afterward.
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
  /// original [Note.path], [Note.filePath], [Note.createdAt], and [Note.tags].
  /// If the note does not exist, a new one is created with [noteId] as
  /// both [Note.path] and [Note.filePath].
  ///
  /// After saving, [[wiki-links]] are extracted from the content.
  ///
  /// Returns the saved [Note].
  Future<Note> call(String noteId, String content) async {
    final existing = await _repo.readNote(noteId);

    if (existing != null) {
      final updated = existing.copyWith(
        content: content,
        updatedAt: DateTime.now(),
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
          tags: const [],
        ),
      );
      await _repo.extractLinks(created.id, content);
      return created;
    }
  }
}
