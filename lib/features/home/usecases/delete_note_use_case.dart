import 'package:flutter/foundation.dart';

import 'package:graphite/core/repository/note_repository.dart';

/// Coordinates note deletion for the HomeScreen.
///
/// Extracted from [HomeScreen] to keep UI and data-access concerns separate
/// and to make the delete logic independently testable.
class DeleteNoteUseCase {
  final NoteRepository _repo;

  DeleteNoteUseCase(this._repo);

  /// Delete a single note by [id]. No-op if the note does not exist.
  Future<void> single(String id) async {
    await _repo.deleteNote(id);
  }

  /// Delete all notes identified by [ids], returning the number of notes
  /// that were successfully deleted.
  ///
  /// Each deletion is best-effort: failures for individual ids are caught
  /// and logged, and the remaining ids in the batch are still processed.
  /// Returns the count of notes that were actually removed (nonexistent ids
  /// are silently skipped and do not increment the count).
  Future<int> bulk(Iterable<String> ids) async {
    var deleted = 0;
    for (final id in ids) {
      try {
        final existed = await _repo.readNote(id) != null;
        await _repo.deleteNote(id);
        if (existed) deleted++;
      } catch (e) {
        debugPrint('Failed to delete note $id: $e');
      }
    }
    return deleted;
  }
}
