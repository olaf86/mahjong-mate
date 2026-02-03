import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F6B6B),
        brightness: Brightness.light,
      ),
    );

    final textTheme = GoogleFonts.sourceSans3TextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.merriweather(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF121417),
      ),
      headlineMedium: GoogleFonts.merriweather(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF121417),
      ),
      titleLarge: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF121417),
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF8F4EF),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F4EF),
        foregroundColor: const Color(0xFF121417),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE7DDD0)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFEDE3D6),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: const Color(0xFF3A2F25),
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7DDD0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE7DDD0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F6B6B), width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF0F6B6B),
        foregroundColor: Colors.white,
      ),
    );
  }
}
