import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFF22C55E);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
      scaffoldBackgroundColor: const Color(0xFFF5F7FC),
      useMaterial3: true,
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0B1020),
      useMaterial3: true,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF111827),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
