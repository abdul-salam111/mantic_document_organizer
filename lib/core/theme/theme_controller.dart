import 'package:flutter/material.dart';

import '../local_storage/local_storage_exports.dart';

/// Controls and persists the app's light/dark theme preference.
///
/// This is a `ChangeNotifier` (not GetX) to stay consistent with the rest
/// of the app's state management. Register it once as a DI singleton
/// (see core/di/injection_container.dart) and provide that same instance
/// at the root of the widget tree via `ChangeNotifierProvider.value` — see
/// main.dart — so every screen shares one source of truth for theme.
class ThemeController extends ChangeNotifier {
  static const String _storageKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Loads the persisted theme preference, if any. Call this once before
  /// the app's first frame (e.g. in `main()` before `runApp`) so there's
  /// no flash of the wrong theme.
  Future<void> loadTheme() async {
    final value = await storage.readValues(_storageKey);
    switch (value) {
      case 'dark':
        _themeMode = ThemeMode.dark;
      case 'light':
        _themeMode = ThemeMode.light;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Flips between light and dark. If the current mode is `system`,
  /// switches to the opposite of whatever the OS is currently reporting.
  Future<void> toggleTheme(BuildContext context) async {
    final isCurrentlyDark = _themeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context) == Brightness.dark
        : isDarkMode;
    await setTheme(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setTheme(ThemeMode mode) async {
    // Update in-memory state and notify immediately so the UI reacts
    // without waiting on disk I/O. Persistence is best-effort: if it
    // fails, the chosen theme still applies for the rest of this session.
    _themeMode = mode;
    notifyListeners();
    try {
      await storage.setValues(_storageKey, mode.name);
    } catch (_) {
      // Ignore — see comment above.
    }
  }

  /// Resets to following the OS-level light/dark setting.
  Future<void> useSystemTheme() => setTheme(ThemeMode.system);
}
