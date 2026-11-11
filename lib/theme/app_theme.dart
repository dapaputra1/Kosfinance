import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF4F46E5); // Modern Indigo
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFEEF2FF);

  // Financial Accents
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeLight = Color(0xFFD1FAE5);
  static const Color expense = Color(0xFFF43F5E); // Rose Red
  static const Color expenseLight = Color(0xFFFFE4E6);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFEDE9FE);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFFCFFAFE);

  // Neutrals
  static const Color background = Color(0xFFF8FAFC); // Crisp slate canvas
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Category Icon Colors
  static Color getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('makan') || lower.contains('food')) return const Color(0xFFF97316); // Orange
    if (lower.contains('kos') || lower.contains('kamar') || lower.contains('house')) return const Color(0xFF6366F1); // Indigo
    if (lower.contains('transport') || lower.contains('bensin')) return const Color(0xFF3B82F6); // Blue
    if (lower.contains('listrik') || lower.contains('air') || lower.contains('util')) return const Color(0xFFF59E0B); // Amber
    if (lower.contains('belanja') || lower.contains('shop')) return const Color(0xFFEC4899); // Pink
    if (lower.contains('kuliah') || lower.contains('buku') || lower.contains('edu')) return const Color(0xFF14B8A6); // Teal
    if (lower.contains('hiburan') || lower.contains('game')) return const Color(0xFF8B5CF6); // Purple
    if (lower.contains('gaji') || lower.contains('salary') || lower.contains('allowance')) return const Color(0xFF10B981); // Emerald
    return const Color(0xFF64748B); // Slate
  }

  static IconData getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('makan') || lower.contains('food')) return Icons.restaurant_rounded;
    if (lower.contains('kos') || lower.contains('kamar') || lower.contains('house')) return Icons.home_rounded;
    if (lower.contains('transport') || lower.contains('bensin')) return Icons.directions_bike_rounded;
    if (lower.contains('listrik') || lower.contains('air') || lower.contains('util')) return Icons.bolt_rounded;
    if (lower.contains('belanja') || lower.contains('shop')) return Icons.shopping_bag_rounded;
    if (lower.contains('kuliah') || lower.contains('buku') || lower.contains('edu')) return Icons.school_rounded;
    if (lower.contains('hiburan') || lower.contains('game')) return Icons.sports_esports_rounded;
    if (lower.contains('kesehatan') || lower.contains('obat')) return Icons.medical_services_rounded;
    if (lower.contains('gaji') || lower.contains('salary')) return Icons.payments_rounded;
    if (lower.contains('allowance') || lower.contains('kiriman')) return Icons.card_giftcard_rounded;
    return Icons.category_rounded;
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
