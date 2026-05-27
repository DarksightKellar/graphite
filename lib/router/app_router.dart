import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import '../screens/home_screen.dart';
import '../screens/editor_screen.dart';
import '../screens/tag_browser_screen.dart';
import '../usecases/delete_note_use_case.dart';
import '../usecases/navigate_link_use_case.dart';
import '../usecases/note_list_use_case.dart';
import '../usecases/quick_note_use_case.dart';
import '../usecases/save_note_use_case.dart';

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
