/// Represents a connection between two notes.
/// Created when a note contains `[[note title]]` syntax.
class Link {
  /// The note containing this link.
  final String fromNoteId;

  /// The linked note's display name (not ID).
  final String toNoteTitle;

  /// Frequency of this exact link across all notes.
  final int weight;

  const Link({
    required this.fromNoteId,
    required this.toNoteTitle,
    this.weight = 1,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
    fromNoteId: json['from_note_id'] as String,
    toNoteTitle: json['to_note_title'] as String,
    weight: json['weight'] as int? ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'from_note_id': fromNoteId,
    'to_note_title': toNoteTitle,
    'weight': weight,
  };

  Link copyWith({
    String? fromNoteId,
    String? toNoteTitle,
    int? weight,
  }) {
    return Link(
      fromNoteId: fromNoteId ?? this.fromNoteId,
      toNoteTitle: toNoteTitle ?? this.toNoteTitle,
      weight: weight ?? this.weight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Link &&
          runtimeType == other.runtimeType &&
          fromNoteId == other.fromNoteId &&
          toNoteTitle == other.toNoteTitle;

  @override
  int get hashCode => Object.hash(fromNoteId, toNoteTitle);

  @override
  String toString() =>
      'Link(fromNoteId: $fromNoteId, toNoteTitle: $toNoteTitle, weight: $weight)';
}

/// A batch of links for efficient bulk operations.
class LinksBatch {
  final List<Link> links;

  const LinksBatch({required this.links});

  factory LinksBatch.fromJson(Map<String, dynamic> json) => LinksBatch(
    links: (json['links'] as List)
        .map((item) => Link.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
