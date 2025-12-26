import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/playlist_screen.dart';
import 'utils/http_overrides.dart';
import 'repositories/theme_repository.dart';

import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  final initialThemeIndex = await ThemeRepository().getTheme();
  runApp(M3uPlayerApp(initialThemeIndex: initialThemeIndex));
}

// Simple state management for theme
class ThemeManager extends ValueNotifier<int> {
  ThemeManager(super.value);

  static final ThemeManager _instance = ThemeManager(0);
  static ThemeManager get instance => _instance;

  void changeTheme(int index) {
    value = index;
    ThemeRepository().saveTheme(index);
  }
}

class M3uPlayerApp extends StatefulWidget {
  final int initialThemeIndex;
  const M3uPlayerApp({super.key, required this.initialThemeIndex});

  @override
  State<M3uPlayerApp> createState() => _M3uPlayerAppState();
}

class _M3uPlayerAppState extends State<M3uPlayerApp> {
  @override
  void initState() {
    super.initState();
    ThemeManager.instance.value = widget.initialThemeIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: ValueListenableBuilder<int>(
        valueListenable: ThemeManager.instance,
        builder: (context, themeIndex, child) {
          return MaterialApp(
            title: 'Simple M3U IPTV',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.getTheme(themeIndex),
            home: const PlaylistScreen(),
          );
        },
      ),
    );
  }
}
