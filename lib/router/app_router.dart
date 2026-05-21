import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/editor_screen.dart';
import '../screens/tag_browser_screen.dart';

/// Router configuration for Graphite app.
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (_, state) => '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),

    GoRoute(
      path: '/editor/:id',
      builder: (context, state) {
        final noteId = state.pathParameters['id']!;
        return EditorScreen(noteId: noteId);
      },
    ),

    GoRoute(path: '/tags', builder: (_, __) => const TagBrowserScreen()),
  ],
);
