import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardWhite  = Color(0xFFFFFFFF);

  // Brand / Role
  static const Color primary   = Color(0xFF4CAF50); // green
  static const Color student   = Color(0xFF2196F3); // blue
  static const Color committee = Color(0xFF9C27B0); // purple
  static const Color president = Color(0xFFFF9800); // orange
  static const Color admin     = Color(0xFFF44336); // red

  // Neutral
  static const Color textDark    = Color(0xFF1A1A2E);
  static const Color textMedium  = Color(0xFF6B7280);
  static const Color textLight   = Color(0xFF9CA3AF);
  static const Color divider     = Color(0xFFE5E7EB);
  static const Color inputBg     = Color(0xFFF3F4F6);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    fontFamily: 'Roboto',
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'president':  return AppColors.president;
      case 'committee':  return AppColors.committee;
      case 'treasurer':  return AppColors.primary;
      default:           return AppColors.student; // student
    }
  }

  static String roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'president':  return 'President Portal';
      case 'committee':  return 'Committee Portal';
      case 'treasurer':  return 'Treasurer Portal';
      default:           return 'Student Portal';
    }
  }
}
