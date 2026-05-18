import 'package:flutter/material.dart';

/// Router configuration for Graphite app.
goRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (_, state) => '/',
  routes: [
    // App-level screens (ordered by specificity)
    GoRoute(path: '/', builder: (_) => const HomeScreen()),

    GoRoute(
      path: '/editor/:id',
      builder: (context, state) {
        final noteId = state.pathParameters['id']!;
        return EditorScreen(noteId: noteId);
      },
    ),

    GoRoute(path: '/graph', builder: (_) => const GraphScreen()),

    GoRoute(path: '/tags', builder: (_) => const TagBrowserScreen()),
  ],
);
