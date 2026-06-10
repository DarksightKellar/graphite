import 'package:flutter/material.dart';

import 'package:graphite/core/design/theme.dart';
import 'package:graphite/core/di/injection.dart';
import 'package:graphite/core/router/app_router.dart';
import 'package:graphite/core/theme/app_theme_service.dart';

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
    final appTheme = getIt<AppThemeService>();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appTheme.themeModeListenable,
      builder: (context, themeMode, child) {
        return MaterialApp.router(
          title: 'Graphite — Local-First Notes',
          debugShowCheckedModeBanner: false,
          theme: GraphiteTheme.light(),
          darkTheme: GraphiteTheme.dark(),
          themeMode: themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
