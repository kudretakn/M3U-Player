import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepository {
  static const String key = 'selected_theme';

  Future<void> saveTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, index);
  }

  Future<int> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0; // 0 = default (blue)
  }
}

class AppThemes {
  static final List<MaterialColor> colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
  ];

  static final List<String> names = [
    'Mavi (Varsayılan)',
    'Kırmızı',
    'Yeşil',
    'Mor',
    'Turuncu',
    'Turkuaz',
  ];

  static ThemeData getTheme(int index) {
    if (index < 0 || index >= colors.length) index = 0;
    final color = colors[index];

    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: color,
      primaryColor: color,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: color),
        titleTextStyle:
            TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
