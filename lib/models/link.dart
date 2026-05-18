import 'package:freezed_annotation/freezed_annotation.dart';

part 'link.freezed.dart';

/// Represents a connection between two notes.
/// Created when a note contains `[[note title]]` syntax.
class Link {
  final String fromNoteId; // the note containing this link
  
  final String toNoteTitle; // the linked note's display name (not ID)
  
  final int weight; // frequency of this exact link across all notes
  
  factory Link.fromJson(Map<String, dynamic> json) => Link(
        fromNoteId: json['from_note_id'] as String,
        toNoteTitle: json['to_note_title'] as String,
        weight: json['weight'] as int,
      );
}

/// A batch of links for efficient bulk operations.
class LinksBatch {
  final List<Link> links;
  
  factory LinksBatch.fromJson(Map<String, dynamic> json) => LinksBatch(
        links: (json['links'] as List)
            .map((item) => Link.fromJson(item))
            .toList(),
      );
}
