import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAppTheme {
  // Colors provided by the user
  static const Color accentDark = Color(0xFF047857);
  static const Color accentLight = Color(0xFF059669);

  static const Color bgDark = Color(0xFF111827);
  static const Color bgLight = Color(0xFFF9FAFB);

  static const Color cardDark = Color(0xFF374151);
  static const Color cardLight = Color(0xFFFFFFFF);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
    primaryColor: accentLight,
    scaffoldBackgroundColor: bgLight,
    cardColor: cardLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentLight,
      brightness: Brightness.light,
      primary: accentLight,
      secondary: accentDark,
      background: bgLight,
      surface: cardLight,
      outline: bgDark,
      onPrimary: Color(0xff000000),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: accentLight,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardLight,
      selectedItemColor: accentLight,
      unselectedItemColor: Colors.grey,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
    primaryColor: accentDark,
    scaffoldBackgroundColor: bgDark,
    cardColor: cardDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentDark,
      brightness: Brightness.dark,
      primary: accentDark,
      secondary: accentLight,
      background: bgDark,
      surface: cardDark,
      outline: bgLight,
      onPrimary: bgLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: accentDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardDark,
      selectedItemColor: accentDark,
      unselectedItemColor: Colors.grey,
    ),
  );
}

class ThemeNotifier extends ChangeNotifier {
  static const _prefKey = 'isDarkMode';

  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeNotifier();

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _isDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isDark);
    notifyListeners();
  }

  Future<void> toggle() async => setDark(!_isDark);
}
