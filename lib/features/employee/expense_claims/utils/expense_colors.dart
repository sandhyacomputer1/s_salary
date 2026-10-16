import 'package:flutter/material.dart';

/// Expense module colors, matched to the S Salary admin palette
/// (same values used in AdminDashboardScreen / Leave / Expense admin).
class ExpenseColors {
  ExpenseColors._();

  // Brand
  static const Color primary = Color(0xFFE96832); // S Salary orange
  static const Color primaryTint = Color(0xFFFFEEE7);

  // Surfaces
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB);

  // Text
  static const Color textPrimary = Color(0xFF18212F);
  static const Color textSecondary = Color(0xFF6B7280);

  // Status
  static const Color success = Color(0xFF18864B);
  static const Color warning = Color(0xFFE8A317);
  static const Color danger = Color(0xFFC62828);

  /// Soft card shadow used across the app.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];
}