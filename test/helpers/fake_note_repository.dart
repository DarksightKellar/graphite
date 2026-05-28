import 'package:graphite/models/note.dart';
import 'package:graphite/repository/note_repository.dart';
import 'fake_graphite_db.dart';

/// A fake repository that wraps a [FakeGraphiteDB] for widget testing.
/// File-system writes are no-ops — all reads/writes go through the
/// in-memory fake database.
class FakeNoteRepository extends NoteRepository {
  final FakeGraphiteDB fakeDb;

  FakeNoteRepository._(FakeGraphiteDB super.db) : fakeDb = db;

  /// Create a fake repository backed by a [FakeGraphiteDB].
  /// If no [db] is provided, creates a new empty [FakeGraphiteDB].
  factory FakeNoteRepository([FakeGraphiteDB? db]) {
    final resolved = db ?? FakeGraphiteDB();
    return FakeNoteRepository._(resolved);
  }

  /// Direct access to the underlying notes list for test setup/assertion.
  List<Note> get notes => fakeDb.notes;

  /// Whether [initialize] has been called on the underlying database.
  bool get initialized => fakeDb.initialized;

  /// Inject links for testing.
  void addLinks(String noteId, Set<String> targets) {
    fakeDb.addLinks(noteId, targets);
  }
}
