// lib/shared/theme/theme_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends StateNotifier<bool> {
  static const _themeKey = 'isDarkMode';
  
  ThemeNotifier() : super(false) {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_themeKey) ?? false;
  }

  void toggleTheme() async {
    final newMode = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, newMode);
    state = newMode;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});