import 'package:flutter/material.dart';

ThemeData buildAllonbizTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final seed = isDark ? const Color(0xFF2CC8A1) : const Color(0xFF0F7B6C);
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
    primary: isDark ? const Color(0xFF84F0D5) : const Color(0xFF0F7B6C),
    secondary: isDark ? const Color(0xFFF5B544) : const Color(0xFFA65A00),
    surface: isDark ? const Color(0xFF081917) : const Color(0xFFF8FBFA),
  );

  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: scheme.surface,
    useMaterial3: true,
    textTheme: Typography.material2021().black.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF0F2421) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF112C28) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
