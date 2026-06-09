/// A tag extracted from note content via #tag syntax.
class Tag {
  /// The tag text, e.g. "personal" or "journaling".
  final String id;

  /// How many notes reference this tag.
  final int noteCount;

  const Tag({
    required this.id,
    this.noteCount = 0,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
    id: json['id'] as String,
    noteCount: json['note_count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'note_count': noteCount,
  };

  Tag copyWith({
    String? id,
    int? noteCount,
  }) {
    return Tag(
      id: id ?? this.id,
      noteCount: noteCount ?? this.noteCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tag(id: $id, noteCount: $noteCount)';
}
