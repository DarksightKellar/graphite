import 'package:graphite/core/models/note.dart';
import 'package:graphite/core/repository/note_repository.dart';

/// Creates notes from quick-capture text input or imported files.
///
/// Extracted from [HomeScreen] to encapsulate the note-building logic
/// for both the quick capture dialog and file import flow.
class QuickNoteUseCase {
  final NoteRepository _repo;

  QuickNoteUseCase(this._repo);

  /// Creates a note from text input (quick capture).
  ///
  /// If [title] is empty or whitespace-only, falls back to
  /// "Untitled {timestamp_ms}".
  ///
  /// Content is formatted as:
  /// ```markdown
  /// # {effectiveTitle}
  ///
  /// {content}
  /// ```
  /// If [content] is empty, only the heading is included.
  ///
  /// [tags] are passed through directly.
  Future<Note> fromText(
    String title,
    String content, {
    List<String> tags = const [],
  }) async {
    final effectiveTitle = title.trim().isEmpty
        ? 'Untitled ${DateTime.now().millisecondsSinceEpoch}'
        : title.trim();

    final noteContent = content.trim().isEmpty
        ? '# $effectiveTitle'
        : '# $effectiveTitle\n\n$content';

    final now = DateTime.now();
    final note = Note(
      id: '', // assigned by database
      path: effectiveTitle,
      filePath: '', // no file backing for quick capture
      createdAt: now,
      updatedAt: now,
      content: noteContent,
      tags: tags,
    );

    return _repo.createNote(note);
  }

  /// Creates a note from an imported markdown file.
  ///
  /// The display name is derived from the last segment of [filePath]
  /// with the `.md` extension stripped. The note's path is set to
  /// "Imported {displayName}".
  ///
  /// Content includes an import metadata header:
  /// ```markdown
  /// # {displayName}
  ///
  /// > Imported from: {filePath}
  /// > Imported at: {now}
  ///
  /// {fileContent}
  /// ```
  Future<Note> importFile(String filePath, String fileContent) async {
    String displayName = filePath.split('/').last;
    if (displayName.endsWith('.md')) {
      displayName = displayName.substring(0, displayName.length - 3);
    }

    final now = DateTime.now();
    final note = Note(
      id: '', // assigned by database
      path: 'Imported $displayName',
      filePath: filePath,
      createdAt: now,
      updatedAt: now,
      content:
          '# $displayName\n\n> Imported from: $filePath\n> Imported at: $now\n\n$fileContent',
      tags: const [],
    );

    return _repo.createNote(note);
  }
}
