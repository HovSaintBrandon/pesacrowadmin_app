import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardColor: const Color(0xFF141E33),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF10B981),
      secondary: Color(0xFF1E293B),
      surface: Color(0xFF141E33),
      background: Color(0xFF0F172A),
      onPrimary: Color(0xFF0F172A),
      onSurface: Color(0xFFE2E8F0),
      onBackground: Color(0xFFE2E8F0),
      outline: Color(0xFF1E3A5F),
    ),
    dividerColor: const Color(0xFF1E3A5F),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF10B981)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      hintStyle: const TextStyle(color: Color(0xFF475569)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
    ),
  );

  // Colors
  static const Color primary = Color(0xFF10B981);
  static const Color background = Color(0xFF0F172A);
  static const Color card = Color(0xFF141E33);
  static const Color border = Color(0xFF1E3A5F);
  static const Color sidebar = Color(0xFF0B1120);
  static const Color textMain = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
