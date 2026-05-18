import 'package:flutter/material.dart';

/// Main app entry point for Graphite.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GraphiteApp());
}

class GraphiteApp extends StatelessWidget {
  const GraphiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Graphite — Local-First Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Calming, modern color palette inspired by Obsidian's clean aesthetic:
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFFAFAF9), // warm off-white
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2D3436),
          foregroundColor: Colors.white,
          elevation: 0, // flat design
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}

/// Router configuration — routes are ordered by specificity (most specific first)
goRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (_, state) {
    // Redirect to graph if no history, or tags if user is exploring tags
    return '/';
  },
  routes: [
    // App-level screens
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
