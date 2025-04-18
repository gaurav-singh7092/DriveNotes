import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'app_theme_mode';
  final FlutterSecureStorage _storage;

  ThemeModeNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await _storage.read(key: _themeKey);

    if (savedTheme != null) {
      state = _getThemeModeFromString(savedTheme);
    }
  }

  ThemeMode _getThemeModeFromString(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    String themeSaveValue;
    switch (mode) {
      case ThemeMode.light:
        themeSaveValue = 'light';
        break;
      case ThemeMode.dark:
        themeSaveValue = 'dark';
        break;
      case ThemeMode.system:
        themeSaveValue = 'system';
        break;
    }

    await _storage.write(key: _themeKey, value: themeSaveValue);
  }

  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        await setThemeMode(
            brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
        break;
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

final lightThemeData = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 4,
  ),
);

final darkThemeData = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 4,
  ),
);
