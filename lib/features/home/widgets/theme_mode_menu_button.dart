import 'package:flutter/material.dart';
import 'package:graphite/core/theme/app_theme_service.dart';

class ThemeModeMenuButton extends StatelessWidget {
  final AppThemeService themeService;

  const ThemeModeMenuButton({
    super.key,
    required this.themeService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService.themeModeListenable,
      builder: (context, themeMode, child) {
        return PopupMenuButton<ThemeMode>(
          tooltip: 'Theme mode',
          icon: Icon(_iconForMode(themeMode)),
          onSelected: themeService.setThemeMode,
          itemBuilder: (_) => [
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.system,
              child: Row(
                children: [
                  if (themeMode == ThemeMode.system) ...[
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                  ],
                  const Text('System'),
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.light,
              child: Row(
                children: [
                  if (themeMode == ThemeMode.light) ...[
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                  ],
                  const Text('Light'),
                ],
              ),
            ),
            PopupMenuItem<ThemeMode>(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  if (themeMode == ThemeMode.dark) ...[
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                  ],
                  const Text('Dark'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconForMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
  }
}
