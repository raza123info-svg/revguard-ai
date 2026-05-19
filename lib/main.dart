// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const RevGuardApp());
}

class RevGuardApp extends StatelessWidget {
  const RevGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RevGuard AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF06B6D4), // Cyan
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate-900
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF06B6D4),
          secondary: Color(0xFF3B82F6),
          background: Color(0xFF0F172A),
          surface: Color(0xFF1E293B),
          error: Colors.redAccent,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Roboto',
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF1E293B),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
