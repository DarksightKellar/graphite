import 'package:graphite/core/models/note.dart';
import 'package:graphite/core/repository/note_repository.dart';

/// Finds an existing note by title or creates a new one.
///
/// Extracted from [EditorScreen._onLinkTap] to separate the "find or create"
/// logic from navigation/UI concerns. The screen handles navigation and the
/// confirmation dialog; this use case only returns the [Note].
class NavigateLinkUseCase {
  final NoteRepository _repo;

  NavigateLinkUseCase(this._repo);

  /// Finds a note by [title] (case-insensitive).
  ///
  /// Returns the existing [Note] or `null` if none was found.
  Future<Note?> find(String title) async {
    return _repo.findNoteByTitle(title);
  }

  /// Creates a new note with [title] as the path and
  /// `# $title\n\n` as the content.
  ///
  /// Returns the newly-created [Note].
  Future<Note> create(String title) async {
    return _repo.createNote(
      Note(
        id: '',
        path: title,
        filePath: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: '# $title\n\n',
        tags: const [],
      ),
    );
  }

  /// Convenience: finds a note by [title] (case-insensitive), or creates
  /// a new one with `# $title\n\n` content if none exists.
  ///
  /// Returns the existing or newly-created [Note].
  Future<Note> findOrCreate(String title) async {
    final note = await _repo.findNoteByTitle(title);

    if (note != null) {
      return note;
    }

    return _repo.createNote(
      Note(
        id: '',
        path: title,
        filePath: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        content: '# $title\n\n',
        tags: const [],
      ),
    );
  }
}
