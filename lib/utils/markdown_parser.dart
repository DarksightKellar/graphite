import 'package:markdown/markdown.dart' as md;

/// Parses raw markdown content and extracts:
/// - Tags from `#tag` syntax
/// - Links from `[[note title]]` syntax  
/// - Returns a parsed Note object with metadata
class MarkdownParser {
  final _linkFinder = RegExp(r'\[\[(.*?)\]\]');
  final _tagFinder = RegExp(r'#(?!#)([a-zA-Z0-9_-]+)');

  /// Converts raw markdown content to a parsed Note object.
  static Map<String, dynamic> parseMarkdown(String relativePath, String content) {
    // Extract tags first
    final tagsSet = <String>{};
    final tagMatches = _tagFinder.allMatches(content);
    for (final match in tagMatches) {
      tagsSet.add(match.group(1)!);
    }
    
    // Extract links and build a frequency map
    final linkMap = <String, int>{};
    final linkMatches = _linkFinder.allMatches(content);
    for (final match in linkMatches) {
      String title = match.group(1)!; // The note title inside [[...]]
      linkMap[title] = (linkMap[title] ?? 0) + 1;
    }

    return {
      'content': content,
      'tags': tagsSet.toList(),
      'links': linkMap.map((title, weight) => MapEntry(title, weight)),
    };
  }
}
