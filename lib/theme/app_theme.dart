import 'package:flutter/material.dart';

class AppColors {
  // --- The 3 Core Requested Palette Tones ---
  // 1. Aqua Mint (#8AD6D1)
  static const Color aqua = Color(0xFF8AD6D1);
  static const Color aquaLight = Color(0xFFE5F7F6);
  static const Color aquaDark = Color(0xFF1F524E);

  // 2. Butter Cream (#FFF0C5)
  static const Color cream = Color(0xFFFFF0C5);
  static const Color creamLight = Color(0xFFFFFDF5);
  static const Color creamDark = Color(0xFF8A6D1D);

  // 3. Sage Green (#89A482)
  static const Color sage = Color(0xFF89A482);
  static const Color sageLight = Color(0xFFEDF4EC);
  static const Color sageDark = Color(0xFF355231);

  // --- Brand Semantic Roles ---
  // Primary: Rich Pine Teal (anchored to 8AD6D1)
  static const Color primary = Color(0xFF24524E);
  static const Color primaryDark = Color(0xFF163734);
  static const Color primaryLight = Color(0xFFE5F7F6);
  static const Color primaryAccent = Color(0xFF8AD6D1);

  // Financial Semantics:
  // Income: Sage Green (89A482)
  static const Color income = Color(0xFF89A482);
  static const Color incomeLight = Color(0xFFEDF4EC);
  static const Color incomeDark = Color(0xFF355231);

  // Expense: Warm Terracotta Clay (harmonizes with Sage, Mint, and Cream)
  static const Color expense = Color(0xFFD65C47);
  static const Color expenseLight = Color(0xFFFDEEEC);
  static const Color expenseDark = Color(0xFF8C3122);

  // Warning & Budget: Butter Cream (FFF0C5) & Amber Gold
  static const Color warning = Color(0xFFC48E1D);
  static const Color warningLight = Color(0xFFFFF0C5); // Exact requested cream

  // Secondary Accents
  static const Color purple = Color(0xFF7A7996);
  static const Color purpleLight = Color(0xFFF1F0F7);
  static const Color cyan = Color(0xFF8AD6D1); // Exact requested aqua
  static const Color cyanLight = Color(0xFFE5F7F6);

  // --- Canvas & Neutrals ---
  static const Color background = Color(0xFFF7FAF8); // Clean, warm mineral canvas
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFEFF4F1);
  static const Color border = Color(0xFFDCE6DF);
  static const Color textPrimary = Color(0xFF13251E);
  static const Color textSecondary = Color(0xFF4C6358);
  static const Color textMuted = Color(0xFF82988C);

  // Category Icon Colors (Harmonized Nordic Palette)
  static Color getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('makan') || lower.contains('food')) return const Color(0xFFD97746); // Warm Sand
    if (lower.contains('kos') || lower.contains('kamar') || lower.contains('house')) return const Color(0xFF3C8A84); // Teal Aqua
    if (lower.contains('transport') || lower.contains('bensin')) return const Color(0xFF6E8E67); // Forest Sage
    if (lower.contains('listrik') || lower.contains('air') || lower.contains('util')) return const Color(0xFFC48E1D); // Warm Gold
    if (lower.contains('belanja') || lower.contains('shop')) return const Color(0xFFCE6373); // Terracotta Pink
    if (lower.contains('kuliah') || lower.contains('buku') || lower.contains('edu')) return const Color(0xFF2B716A); // Deep Pine
    if (lower.contains('hiburan') || lower.contains('game')) return const Color(0xFF7A7996); // Slate Lavender
    if (lower.contains('kesehatan') || lower.contains('obat')) return const Color(0xFF5A8E89); // Mineral Teal
    if (lower.contains('gaji') || lower.contains('salary') || lower.contains('allowance')) return const Color(0xFF89A482); // Sage
    return const Color(0xFF647B70);
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
        seedColor: AppColors.aqua,
        primary: AppColors.primary,
        secondary: AppColors.sage,
        tertiary: AppColors.cream,
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
