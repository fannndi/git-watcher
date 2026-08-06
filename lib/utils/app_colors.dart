import 'package:flutter/material.dart';

/// App color constants for consistent theming
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Colors.blue;
  static const Color primaryLight = Color(0xFFBBDEFB);
  static const Color primaryDark = Color(0xFF1565C0);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Commit status colors
  static const Color added = Color(0xFF4CAF50);
  static const Color removed = Color(0xFFF44336);
  static const Color modified = Color(0xFF2196F3);
  static const Color renamed = Color(0xFFFF9800);

  // Background colors
  static const Color scaffoldLight = Color(0xFFF8FAFF);
  static const Color scaffoldDark = Color(0xFF121212);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Chip colors
  static const Color chipPublic = Color(0xFFE8F5E9);
  static const Color chipPrivate = Color(0xFFFFEBEE);
}

/// Extension for color opacity helpers
extension ColorExtension on Color {
  Color withValues({double? alpha}) {
    return withAlpha(((alpha ?? 1.0) * 255).round());
  }
}
