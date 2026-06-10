import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application-wide theme mode controller.
///
/// Keeps the current user-selected theme mode and exposes a
/// [ValueListenable] for widgets that need to rebuild when it changes.
class AppThemeService {
  AppThemeService() : _themeModeNotifier = ValueNotifier(ThemeMode.system);

  final ValueNotifier<ThemeMode> _themeModeNotifier;

  ThemeMode get themeMode => _themeModeNotifier.value;

  ValueListenable<ThemeMode> get themeModeListenable => _themeModeNotifier;

  void setThemeMode(ThemeMode themeMode) {
    if (_themeModeNotifier.value == themeMode) return;
    _themeModeNotifier.value = themeMode;
  }

  void toggleThemeMode() {
    final next = switch (_themeModeNotifier.value) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
    _themeModeNotifier.value = next;
  }
}
