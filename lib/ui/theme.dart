/// Цвета и тема приложения (светлая и тёмная).
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const accent = Color(0xFF4F46E5);
  static const accentDark = Color(0xFF6366F1);
  static const up = Color(0xFF16A34A);
  static const down = Color(0xFFDC2626);
  static const flat = Color(0xFF64748B);
  static const warning = Color(0xFFD97706);
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: brightness,
    primary: dark ? AppColors.accentDark : AppColors.accent,
    surface: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
    surfaceContainerLow: dark ? const Color(0xFF1E293B) : Colors.white,
    surfaceContainerHigh: dark ? const Color(0xFF273449) : const Color(0xFFF1F5F9),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface)),
    ),
  );
}
