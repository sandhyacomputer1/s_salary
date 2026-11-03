import 'package:flutter/material.dart';

/// Darker sidebar text, the same as the web.
/// Use these in the employee shell instead of the light grey colors.
class EmpSidebarStyle {
  EmpSidebarStyle._();

  static const Color primary = Color(0xFFE96832);
  static const Color primaryTint = Color(0xFFFFEEE7);

  /// menu text / icons (near black)
  static const Color itemText = Color(0xFF111827);
  static const Color itemIcon = Color(0xFF1F2937);

  /// OVERVIEW / WORK / FINANCE / ACCOUNT titles
  static const Color sectionText = Color(0xFF6B7280);

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    color: sectionText,
  );

  static TextStyle item({required bool selected}) => TextStyle(
    fontSize: 14.5,
    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    color: selected ? primary : itemText,
  );

  static Color icon({required bool selected}) => selected ? primary : itemIcon;

  static const double iconSize = 22;
  static const double itemHeight = 44;
}