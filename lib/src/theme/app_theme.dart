import 'package:flutter/material.dart';

class AppTheme {
  static Color seed = const Color(0xFF2364D2);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      fontFamily: 'Roboto',
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}