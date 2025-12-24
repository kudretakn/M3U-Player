import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'utils/http_overrides.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const M3uPlayerApp());
}

class M3uPlayerApp extends StatelessWidget {
  const M3uPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      },
      child: MaterialApp(
        title: 'M3U Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF121212),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
