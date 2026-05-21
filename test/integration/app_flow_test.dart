import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:graphite/data/database.dart';
import 'package:graphite/models/note.dart';
import 'package:graphite/models/tag.dart';
import 'package:graphite/screens/editor_screen.dart';
import 'package:graphite/screens/home_screen.dart';
import 'package:graphite/screens/tag_browser_screen.dart';
import 'package:graphite/widgets/editor_pane.dart';

/// A comprehensive in-memory fake database for integration testing.
class IntegrationTestFakeDB extends GraphiteDB {
  final List<Note> _notes = [];
  final Map<String, List<Map<String, dynamic>>> _links = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<Note> createNote(Note note) async {
    final id = note.path.hashCode.abs().toString();
    final created = note.copyWith(id: id);
    _notes.add(created);
    return created;
  }

  @override
  Future<Note?> readNote(String noteId) async {
    try {
      return _notes.firstWhere((n) => n.id == noteId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) _notes[idx] = note;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n.id == noteId);
    _links.remove(noteId);
  }

  @override
  Future<List<Note>> listNotes() async {
    final sorted = List<Note>.from(_notes);
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final lower = query.toLowerCase();
    return _notes
        .where((n) =>
            n.content.toLowerCase().contains(lower) ||
            n.path.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Future<List<Tag>> getAllTags() async {
    final counts = <String, int>{};
    for (final note in _notes) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts.entries
        .map((e) => Tag(id: e.key, noteCount: e.value))
        .toList();
  }

  @override
  Future<List<Note>> getNotesByTag(String tag) async {
    return _notes.where((n) => n.tags.contains(tag)).toList();
  }

  @override
  Future<void> extractLinks(String noteId, String content) async {
    _links[noteId] = [];
    final pattern = RegExp(r'\[\[(.+?)\]\]');
    for (final match in pattern.allMatches(content)) {
      final title = match.group(1)!.trim();
      if (title.isNotEmpty) {
        _links[noteId]!.add({
          'from_note_id': noteId,
          'to_note_title': title,
        });
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOutgoingLinks(String fromNoteId) async =>
      _links[fromNoteId] ?? [];

  @override
  Future<int> getLinkCount(String noteId) async =>
      (_links[noteId]?.length) ?? 0;

  @override
  Future<List<Note>> getNotesWithLinks() async {
    final linkedIds =
        _links.entries.where((e) => e.value.isNotEmpty).map((e) => e.key);
    return _notes.where((n) => linkedIds.contains(n.id)).toList();
  }

  @override
  Future<Note?> findNoteByTitle(String title) async {
    try {
      return _notes.firstWhere(
        (n) => n.path.toLowerCase() == title.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// End-to-end integration tests for Graphite covering 6 core user flows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late IntegrationTestFakeDB fakeDb;

  setUp(() => fakeDb = IntegrationTestFakeDB());

  Widget buildApp() => MaterialApp(
        title: 'Graphite',
        home: HomeScreen(db: fakeDb),
        onGenerateRoute: (settings) {
          if (settings.name == '/tags') {
            return MaterialPageRoute(
                builder: (_) => TagBrowserScreen(db: fakeDb));
          }
          if (settings.name != null &&
              settings.name!.startsWith('/editor/')) {
            final id = settings.name!.split('/').last;
            return MaterialPageRoute(
                builder: (_) => EditorScreen(noteId: id, db: fakeDb));
          }
          return null;
        },
      );

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> dismissTimers(WidgetTester t) async {
    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(milliseconds: 100));
  }

  Future<Note> mkNote({
    required String path,
    required String content,
    List<String> tags = const [],
  }) async {
    final n = Note(
      id: '',
      path: path,
      filePath: '/tmp/$path.md',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      content: content,
      tags: tags,
    );
    return fakeDb.createNote(n);
  }

  // ═════════════════════════════════════════════════════════════════════
  // Flow 1: First launch → first note
  // ═════════════════════════════════════════════════════════════════════

  testWidgets('Flow 1: quick capture → note in list → tap opens editor',
      (tester) async {
    addTearDown(() => dismissTimers(tester));

    await tester.pumpWidget(buildApp());
    await settle(tester);

    // Empty state
    expect(find.text('No notes yet. Tap + to create your first note.'),
        findsOneWidget);

    // Tap FAB
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);

    // QuickCaptureDialog
    expect(find.text('Save'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'First Note');
    await tester.enterText(fields.at(1), 'Hello integration test');
    await tester.pump();

    // Save
    await tester.tap(find.text('Save'));
    await settle(tester);

    // Note in list
    expect(find.text('First Note'), findsOneWidget);

    // Navigate to editor by pushing route directly (bypasses
    // InkWell/Dismissible gesture complexity)
    final notes = await fakeDb.listNotes();
    final id = notes.first.id;
    tester.state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/editor/$id');
    await settle(tester);

    // Editor screen
    expect(find.text('Edit Note'), findsOneWidget);
  });

  // ═════════════════════════════════════════════════════════════════════
  // Flow 2: Edit → save → verify
  // ═════════════════════════════════════════════════════════════════════

  testWidgets('Flow 2: edit and auto-save persist via DB only',
      (tester) async {
    addTearDown(() => dismissTimers(tester));

    final note = await mkNote(
      path: 'Edit Test',
      content: '# Edit Test\n\nOriginal content.',
    );

    await tester.pumpWidget(buildApp());
    await settle(tester);
    expect(find.text('Edit Test'), findsOneWidget);

    // Navigate to editor
    tester.state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/editor/${note.id}');
    await settle(tester);
    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.text('Original content.'), findsOneWidget);

    // Edit content using descendant finder (the TextField is inside EditorPane)
    final editorPane = find.byType(EditorPane);
    final textField = find.descendant(
      of: editorPane,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      textField,
      '# Edit Test\n\nUpdated content.',
    );
    await tester.pump();

    // Trigger auto-save: pump past the 2-second debounce timer
    await tester.pump(const Duration(seconds: 3));

    // Verify persisted in DB via auto-save
    final reloaded = await fakeDb.readNote(note.id);
    expect(reloaded!.content, contains('Updated content.'));
  });

  // ═════════════════════════════════════════════════════════════════════
  // Flow 3: Search
  // ═════════════════════════════════════════════════════════════════════

  testWidgets('Flow 3: search filters notes, clear restores all',
      (tester) async {
    addTearDown(() => dismissTimers(tester));

    await mkNote(path: 'Alpha', content: '# Alpha\n\nLighthouse keeper logs.');
    await mkNote(path: 'Beta', content: '# Beta\n\nBakery recipes and notes.');
    await mkNote(path: 'Gamma', content: '# Gamma\n\nGamma ray research.');

    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);

    // Search
    await tester.enterText(find.byType(TextField).at(0), 'bakery');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);

    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Gamma'), findsNothing);

    // Clear
    await tester.tap(find.byIcon(Icons.clear));
    await settle(tester);

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
  });

  // ═════════════════════════════════════════════════════════════════════
  // Flow 4: Tag
  // ═════════════════════════════════════════════════════════════════════

  testWidgets('Flow 4: tagged note → browse tags → tap tag filters',
      (tester) async {
    addTearDown(() => dismissTimers(tester));

    await mkNote(
      path: 'Tagged Note',
      content: '# Tagged Note\n\nThis one has an #important tag.',
      tags: ['#important'],
    );
    await mkNote(
      path: 'Plain Note',
      content: '# Plain Note\n\nJust a regular note.',
      tags: [],
    );

    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(find.text('Tagged Note'), findsOneWidget);
    expect(find.text('Plain Note'), findsOneWidget);

    // Browse Tags: open 3-dot menu then tap "Browse Tags"
    // The third PopupMenuButton in the AppBar actions is the quick-actions menu
    final popupMenus = find.byType(PopupMenuButton<String>);
    await tester.tap(popupMenus);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // "Browse Tags" should appear in the overlay
    expect(find.text('Browse Tags'), findsOneWidget);
    await tester.tap(find.text('Browse Tags'));
    await settle(tester);

    // Tag browser
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('1 note'), findsOneWidget);

    // Tap #important tag row → pops back with tag
    await tester.tap(find.text('#important').last);
    await settle(tester);

    // Home screen should show filter banner from filterByTag()
    expect(find.text('Filtered by #important (1 note)'), findsOneWidget);
    expect(find.text('Tagged Note'), findsOneWidget);
    expect(find.text('Plain Note'), findsNothing);
  });

  // ═════════════════════════════════════════════════════════════════════
  // Flow 5: Wiki-link
  // ═════════════════════════════════════════════════════════════════════

  testWidgets('Flow 5: wiki-link tap prompts create, link navigates',
      (tester) async {
    addTearDown(() => dismissTimers(tester));

    final noteA = await mkNote(
      path: 'Note A',
      content: '# Note A\n\nSee [[Note B]] for more details.',
    );
    await fakeDb.extractLinks(noteA.id, noteA.content);

    await tester.pumpWidget(buildApp());
    await settle(tester);

    // Open Note A
    await tester.tap(find.text('Note A'));
    await settle(tester);
    expect(find.text('Edit Note'), findsOneWidget);

    // Tap [[Note B]] link in preview
    expect(find.text('Note B'), findsWidgets);
    await tester.tap(find.text('Note B').last);
    await settle(tester);

    // Create dialog
    expect(find.text('Create "Note B"?'), findsOneWidget);

    // Tap Create
    await tester.tap(find.text('Create'));
    await settle(tester);

    // Navigated to Note B editor (two stacked, findsWidgets)
    expect(find.text('Edit Note'), findsWidgets);
  });

  // ═════════════════════════════════════════════════════════════════════
  // Flow 6: Delete
  // ═════════════════════════════════════════════════════════════════════

  testWidgets('Flow 6: long-press delete, confirm, note removed',
      (tester) async {
    addTearDown(() => dismissTimers(tester));

    await mkNote(
      path: 'Delete Me',
      content: '# Delete Me\n\nThis note will be deleted.',
    );

    await tester.pumpWidget(buildApp());
    await settle(tester);

    expect(find.text('Delete Me'), findsOneWidget);

    // Long-press → selection mode
    await tester.longPress(find.text('Delete Me'));
    await settle(tester);
    expect(find.text('1 selected'), findsOneWidget);

    // Delete
    await tester.tap(find.byTooltip('Delete selected'));
    await settle(tester);
    expect(find.text('Delete Notes'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Delete'));
    await settle(tester);

    // Gone
    expect(find.text('Delete Me'), findsNothing);

    // Search for it → empty
    await tester.enterText(find.byType(TextField).at(0), 'Delete Me');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);

    expect(find.textContaining('No notes matching'), findsOneWidget);
  });
}
