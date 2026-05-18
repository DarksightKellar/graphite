import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';
part 'note.g.dart';

/// A note is a markdown file stored locally on the device.
/// This is the core data model for Graphite.
@freezed
class Note with _$Note {
  /// The unique identifier of this note, used as the filename hash.
  @JsonKey(name: 'id')
  final String id;

  /// The relative path from the vault root to this note's markdown file.
  // e.g., "Home/My First Note.md"
  @JsonKey(name: 'path')
  final String path;

  /// The absolute filesystem path where the markdown file is stored.
  final String filePath;

  /// The timestamp when this note was created (in ISO8601 format).
  @JsonKey(fromJson: _iso8601DateTimeFromJson,
       toJson: _iso8601DateTimeToJson)
  final DateTime createdAt;

  /// The last time the note was modified.
  @JsonKey(name: 'updated_at', fromJson: _iso8601DateTimeFromJson,
       toJson: _iso8601DateTimeToJson)
  final DateTime updatedAt;

  /// The full markdown content of the note (read-only in most views).
  final String content;

  /// All tags associated with this note, derived from `#tag` syntax.
  // e.g., ["personal", "journaling", "ideas"]
  @JsonKey(name: 'tags', fromJson: _stringListFromJson,
       toJson: _stringListToJson)
  final List<String> tags;

  /// Internal counter for version control and conflict resolution.
  int _version = 0;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'file_path': filePath,
        'created_at': _iso8601DateTimeToJson(createdAt),
        'updated_at': _iso8601DateTimeToJson(updatedAt),
        'content': content,
        'tags': _stringListToJson(tags),
      };

  Note copyWith({String? id, String? path, String? filePath,
       DateTime? createdAt, DateTime? updatedAt,
       String? content, List<String>? tags}) {
    return Note(
      id: id ?? this.id,
      path: path ?? this.path,
      filePath: filePath ?? this.filePath,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      content: content ?? this.content,
      tags: tags ?? this.tags,
    );
  }

  /// Increment the version counter for conflict resolution.
  void incrementVersion() {
    _version++;
  }
}

// ISO8601 DateTime serialization helpers
DateTime? _iso8601DateTimeFromJson(dynamic json) => json == null ? null :
    DateTime.tryParse(json as String);

String _iso8601DateTimeToJson(DateTime dateTime) =>
    dateTime.toIso8601String();

List<dynamic> _stringListFromJson(dynamic json) => json == null ? [] :
    List<String>.from(json as Iterable); 

List<dynamic> _stringListToJson(List<String> list) => list;
