import '../models/note.dart';
import '../repository/note_repository.dart';

/// Coordinates note listing, searching, and filtering for the HomeScreen.
///
/// Extracted from [HomeScreen] to keep UI and data-access concerns separate
/// and to make the listing logic independently testable.
class NoteListUseCase {
  final NoteRepository _repo;

  NoteListUseCase(this._repo);

  /// Initializes the repository (idempotent) and returns all notes.
  Future<List<Note>> loadAll() async {
    await _repo.initialize();
    return _repo.listAllNotes();
  }

  /// Search notes by [query] matching content or path (delegated to repo).
  Future<List<Note>> search(String query) async {
    return _repo.searchNotes(query);
  }

  /// Return notes that are tagged with [tag].
  Future<List<Note>> filterByTag(String tag) async {
    await _repo.initialize();
    return _repo.getNotesByTag(tag);
  }

  /// Return notes that have at least one outgoing wiki-link.
  Future<List<Note>> filterWithLinks() async {
    await _repo.initialize();
    return _repo.getNotesWithLinks();
  }

  /// Return the number of outgoing wiki-links for a note by [noteId].
  Future<int> linkCount(String noteId) async {
    return _repo.getLinkCount(noteId);
  }
}
