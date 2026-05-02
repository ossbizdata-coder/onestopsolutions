import 'package:flutter/material.dart';

class AppTheme {
  // OSD Brand Colors (green / white / black)
  static const Color primaryColor = Color(0xFF02C27D);
  static const Color secondaryColor = Color(0xFF049552);
  static const Color accentColor = Color(0xFF4CF3B4);

  // Shop/Module Colors
  static const Color cafeColor     = Color(0xFF068A4B);
  static const Color bookshopColor = Color(0xFF1565C0);
  static const Color foodhutColor  = Color(0xFFB65505);
  static const Color creditsColor  = Color(0xFFE60B31);
  static const Color staffColor    = Color(0xFF6A1B9A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F9FB),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 48,          // ← was default 56
        titleTextStyle: TextStyle(
          fontSize: 16,             // ← was 18
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),  // ← was 14
          ),
          minimumSize: const Size(double.infinity, 42), // ← was 52
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,             // ← was 16
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(double.infinity, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(
            fontSize: 13,             // ← was 15
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,               // ← compact inputs
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),   // ← was 14
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ← was 16/16
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),   // ← was 16
        ),
        color: Colors.white,
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,                 // ← compact list tiles
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),  // ← was 16/4
        minLeadingWidth: 0,
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
