/// A note is a markdown file stored locally on the device.
/// This is the core data model for Graphite.
class Note {
  /// The unique identifier of this note, used as the filename hash.
  final String id;

  /// The relative path from the vault root to this note's markdown file.
  /// e.g., "Home/My First Note.md"
  final String path;

  /// The absolute filesystem path where the markdown file is stored.
  final String filePath;

  /// The timestamp when this note was created.
  final DateTime createdAt;

  /// The last time the note was modified.
  final DateTime updatedAt;

  /// The full markdown content of the note (read-only in most views).
  final String content;

  /// All tags associated with this note, derived from #tag syntax.
  /// e.g., ["personal", "journaling", "ideas"]
  final List<String> tags;

  const Note({
    required this.id,
    required this.path,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    required this.content,
    required this.tags,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    path: json['path'] as String,
    filePath: json['file_path'] as String,
    createdAt: _iso8601DateTimeFromJson(json['created_at'])!,
    updatedAt: _iso8601DateTimeFromJson(json['updated_at'])!,
    content: json['content'] as String,
    tags: _stringListFromJson(json['tags']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'file_path': filePath,
    'created_at': _iso8601DateTimeToJson(createdAt),
    'updated_at': _iso8601DateTimeToJson(updatedAt),
    'content': content,
    'tags': _stringListToJson(tags),
  };

  Note copyWith({
    String? id,
    String? path,
    String? filePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? content,
    List<String>? tags,
  }) {
    return Note(
      id: id ?? this.id,
      path: path ?? this.path,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      content: content ?? this.content,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Note(id: $id, path: $path, filePath: $filePath, '
      'createdAt: $createdAt, updatedAt: $updatedAt, '
      'content: ${content.length} chars, tags: ${tags.length})';
}

// ISO8601 DateTime serialization helpers
DateTime? _iso8601DateTimeFromJson(dynamic json) =>
    json == null ? null : DateTime.tryParse(json as String);

String _iso8601DateTimeToJson(DateTime dateTime) =>
    dateTime.toIso8601String();

List<String> _stringListFromJson(dynamic json) =>
    json == null ? [] : List<String>.from(json as Iterable);

List<dynamic> _stringListToJson(List<String> list) => list;
