import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: AppColors.surface,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(
                color: AppColors.primaryAccent, size: 24);
          }
          return const IconThemeData(color: AppColors.iconSecondary, size: 24);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
              color: AppColors.primaryAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }
          return const TextStyle(
            color: AppColors.iconSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        height: 56,
        elevation: 0,
        surfaceTintColor: AppColors.surface,
      ),
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
          textStyle: AppTypography.titleMedium.copyWith(color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          textStyle: AppTypography.titleMedium,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
        labelStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      // Text Themes
      textTheme: TextTheme(
        displayLarge:
            AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
        displayMedium:
            AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
        displaySmall:
            AppTypography.displaySmall.copyWith(color: AppColors.textPrimary),
        headlineLarge:
            AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary),
        headlineMedium:
            AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
        headlineSmall:
            AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        titleLarge:
            AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        titleMedium:
            AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        titleSmall:
            AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        bodyMedium:
            AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        bodySmall:
            AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        labelLarge:
            AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
        labelMedium:
            AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
        labelSmall:
            AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
      ),
      // Icon Themes
      iconTheme: const IconThemeData(
        color: AppColors.icon,
        size: 24,
      ),
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
