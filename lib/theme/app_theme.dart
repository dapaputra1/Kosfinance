import 'package:flutter/material.dart';

class AppColors {
  // --- The Primary Forest Olive Anchor (#5C7057) ---
  static const Color primary = Color(0xFF5C7057);
  static const Color primaryDark = Color(0xFF3B4A37);
  static const Color primaryLight = Color(0xFFEBF1EA);
  static const Color primaryAccent = Color(0xFF86A380);

  // Financial Semantics:
  // Income: Botanical Sage Green
  static const Color income = Color(0xFF4E8752);
  static const Color incomeLight = Color(0xFFE8F3E8);
  static const Color incomeDark = Color(0xFF2C562F);

  // Expense: Warm Terracotta Earth
  static const Color expense = Color(0xFFC75846);
  static const Color expenseLight = Color(0xFFFBECE9);
  static const Color expenseDark = Color(0xFF852D20);

  // Warning & Gold Highlights
  static const Color warning = Color(0xFFD69F34);
  static const Color warningLight = Color(0xFFFBF4E4);

  // Warm Cream & Sage Accents
  static const Color cream = Color(0xFFFBF4E4);
  static const Color creamLight = Color(0xFFFFFDF7);
  static const Color creamDark = Color(0xFF9E741E);

  static const Color sage = Color(0xFF5C7057);
  static const Color sageLight = Color(0xFFEDF2EC);
  static const Color sageDark = Color(0xFF384735);

  // Secondary Accents
  static const Color purple = Color(0xFF76778D);
  static const Color purpleLight = Color(0xFFF0F1F6);
  static const Color cyan = Color(0xFF5C8A82);
  static const Color cyanLight = Color(0xFFEBF3F2);

  // Canvas & Neutrals
  static const Color background = Color(0xFFF6F8F5);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFEEF3EC);
  static const Color border = Color(0xFFDBE3DA);
  static const Color textPrimary = Color(0xFF1B261A);
  static const Color textSecondary = Color(0xFF4F604E);
  static const Color textMuted = Color(0xFF869785);

  // Category Icon Colors (Botanical Earthy Palette)
  static Color getCategoryColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('makan') || lower.contains('food')) return const Color(0xFFD77C49); // Warm Sand Ochre
    if (lower.contains('kos') || lower.contains('kamar') || lower.contains('house')) return const Color(0xFF5C7057); // Forest Olive
    if (lower.contains('transport') || lower.contains('bensin')) return const Color(0xFF6B8770); // Sage Slate
    if (lower.contains('listrik') || lower.contains('air') || lower.contains('util')) return const Color(0xFFD69F34); // Warm Gold
    if (lower.contains('belanja') || lower.contains('shop')) return const Color(0xFFC76258); // Terracotta Coral
    if (lower.contains('kuliah') || lower.contains('buku') || lower.contains('edu')) return const Color(0xFF3E604F); // Deep Spruce
    if (lower.contains('hiburan') || lower.contains('game')) return const Color(0xFF76778D); // Muted Heather
    if (lower.contains('kesehatan') || lower.contains('obat')) return const Color(0xFF548B80); // Mineral Sage
    if (lower.contains('gaji') || lower.contains('salary') || lower.contains('allowance')) return const Color(0xFF4E8752); // Botanical Green
    return const Color(0xFF6A7B69);
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
        secondary: AppColors.primaryAccent,
        tertiary: AppColors.warning,
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
