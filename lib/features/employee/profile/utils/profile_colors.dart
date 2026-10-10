// lib/features/employee/profile/utils/profile_colors.dart

import 'package:flutter/material.dart';

class ProfileColors {
  ProfileColors._();

  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFEEE7);   // tonal button bg
  static const Color primaryTint = Color(0xFFFBE3D8);    // chip bg (ID pill)

  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color fieldLabel = Color(0xFF6B7280);     // "FULL NAME" label gray

  static const Color border = Color(0xFFE1E5EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF9FAFB);     // info strip bg
  static const Color background = Color(0xFFF7F8FA);

  static const Color success = Color(0xFF16803B);
  static const Color successBg = Color(0xFFE7F6EC);
  static const Color warning = Color(0xFF9A6A00);
  static const Color warningBg = Color(0xFFFFF6E0);
  static const Color danger = Color(0xFFD64545);         // REJECTED pill fg
  static const Color dangerBg = Color(0xFFFDECEA);
  static const Color dangerText = Color(0xFFE96832);     // emergency phone shown orange-red

  // Grid label styling
  static const TextStyle labelStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: fieldLabel,
  );

  static const TextStyle valueStyle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
    color: primary,
  );
}