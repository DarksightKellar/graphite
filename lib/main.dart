import 'package:flutter/material.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

/// Main entry point for Graphite app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF546E7A),
          brightness: Brightness.light,
        ).copyWith(
          secondary: const Color(0xFF1976D2),
          tertiary: const Color(0xFF00E676),
          surface: const Color(0xFFFAFAF9),
          surfaceContainerHighest: const Color(0xFFD6DBDF),
          error: Colors.red,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAF9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D3436),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF90A4AE),
          brightness: Brightness.dark,
        ).copyWith(
          secondary: const Color(0xFF64B5F6),
          tertiary: const Color(0xFF69F0AE),
          surface: const Color(0xFF1A1D23),
          error: const Color(0xFFEF5350),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1D23),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D3436),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
