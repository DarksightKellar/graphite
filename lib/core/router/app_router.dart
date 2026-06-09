import 'package:go_router/go_router.dart';
import 'package:graphite/core/di/injection.dart';
import 'package:graphite/features/editor/editor_screen.dart';
import 'package:graphite/features/editor/usecases/navigate_link_use_case.dart';
import 'package:graphite/features/editor/usecases/save_note_use_case.dart';
import 'package:graphite/features/home/home_screen.dart';
import 'package:graphite/features/home/usecases/delete_note_use_case.dart';
import 'package:graphite/features/home/usecases/note_list_use_case.dart';
import 'package:graphite/features/home/usecases/quick_note_use_case.dart';
import 'package:graphite/features/tags/tag_browser_screen.dart';

/// Router configuration for Graphite app.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => HomeScreen(
        noteListUseCase: getIt<NoteListUseCase>(),
        quickNoteUseCase: getIt<QuickNoteUseCase>(),
        deleteNoteUseCase: getIt<DeleteNoteUseCase>(),
      ),
    ),

    GoRoute(
      path: '/editor/:id',
      builder: (context, state) {
        final noteId = state.pathParameters['id']!;
        return EditorScreen(
          noteId: noteId,
          saveNoteUseCase: getIt<SaveNoteUseCase>(),
          navigateLinkUseCase: getIt<NavigateLinkUseCase>(),
        );
      },
    ),

    GoRoute(
      path: '/tags',
      builder: (_, __) => TagBrowserScreen(
        noteListUseCase: getIt<NoteListUseCase>(),
      ),
    ),
  ],
);
