import 'package:flutter/material.dart';

/// Theme helper for consistent styling
class ThemeHelper {
  ThemeHelper._();

  /// Get card decoration
  static BoxDecoration cardDecoration(BuildContext context,
      {bool elevated = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: elevated
          ? null
          : Border.all(
              color: colorScheme.outlineVariant.withAlpha(128),
            ),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  /// Get section header style
  static TextStyle sectionHeader(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ) ??
        const TextStyle(fontWeight: FontWeight.w800);
  }

  /// Get body style
  static TextStyle body(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  }

  /// Get caption style
  static TextStyle caption(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ) ??
        const TextStyle();
  }

  /// Get chip decoration
  static BoxDecoration chipDecoration(BuildContext context,
      {bool isAccent = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: isAccent
          ? colorScheme.secondaryContainer.withAlpha(128)
          : colorScheme.surfaceContainerHighest.withAlpha(153),
      borderRadius: BorderRadius.circular(8),
    );
  }

  /// Get status color
  static Color statusColor(String status, ColorScheme colorScheme) {
    return switch (status) {
      'added' => Colors.green,
      'removed' => colorScheme.error,
      'renamed' => colorScheme.tertiary,
      _ => colorScheme.primary,
    };
  }

  /// Get status icon
  static IconData statusIcon(String status) {
    return switch (status) {
      'added' => Icons.add_circle_outline,
      'removed' => Icons.remove_circle_outline,
      'renamed' => Icons.drive_file_rename_outline,
      _ => Icons.edit_outlined,
    };
  }
}
