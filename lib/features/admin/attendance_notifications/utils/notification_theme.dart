// lib/features/admin/attendance_notifications/utils/notification_theme.dart

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colors
// ─────────────────────────────────────────────────────────────────────────────
class NotificationColors {
  NotificationColors._();

  // Brand / surfaces
  static const Color primary      = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFEEE7);

  static const Color textDark     = Color(0xFF18212F);
  static const Color textMedium   = Color(0xFF4B5563);
  static const Color textLight    = Color(0xFF8A93A1);

  static const Color border       = Color(0xFFE1E5EA);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color background   = Color(0xFFF7F8FA);

  // Semantic
  static const Color success      = Color(0xFF16803B);
  static const Color successBg    = Color(0xFFE7F6EC);

  static const Color danger       = Color(0xFFD64545);
  static const Color dangerBg     = Color(0xFFFDECEA);

  static const Color warning      = Color(0xFFD97706);
  static const Color warningBg    = Color(0xFFFFF6E0);

  // Table-specific
  static const Color headerBg     = Color(0xFFF8F9FA);
  static const Color rowAlt       = Color(0xFFFBFBFB);
  static const Color checkIn      = Color(0xFF10B981);
  static const Color checkInBg    = Color(0xFFE7F8F1);
  static const Color checkOut     = Color(0xFFE96832); // matches primary
  static const Color checkOutBg   = Color(0xFFFDEEE5);
  static const Color late         = Color(0xFFD97706);
  static const Color lateBg       = Color(0xFFFFF6E0);
  static const Color dash         = Color(0xFF9CA3AF);
}

// ─────────────────────────────────────────────────────────────────────────────
// Backwards-compatible alias so table widgets can keep using
// NotificationTableColors.xxx without changing every reference.
// ─────────────────────────────────────────────────────────────────────────────
class NotificationTableColors {
  NotificationTableColors._();

  static const Color headerBg   = NotificationColors.headerBg;
  static const Color rowAlt     = NotificationColors.rowAlt;
  static const Color checkIn    = NotificationColors.checkIn;
  static const Color checkInBg  = NotificationColors.checkInBg;
  static const Color checkOut   = NotificationColors.checkOut;
  static const Color checkOutBg = NotificationColors.checkOutBg;
  static const Color late       = NotificationColors.late;
  static const Color lateBg     = NotificationColors.lateBg;
  static const Color dash       = NotificationColors.dash;
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography
// ─────────────────────────────────────────────────────────────────────────────
class NotificationText {
  NotificationText._();

  static const TextStyle empName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: NotificationColors.textDark,
  );

  static const TextStyle summaryLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: NotificationColors.textMedium,
  );

  static const TextStyle summaryValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: NotificationColors.textDark,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: NotificationColors.textDark,
  );

  static const TextStyle tabActive = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: NotificationColors.primary,
  );

  static const TextStyle tabInactive = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: NotificationColors.textMedium,
  );

  static const TextStyle emptyTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: NotificationColors.textDark,
  );

  static const TextStyle emptySubtitle = TextStyle(
    fontSize: 13,
    color: NotificationColors.textLight,
  );
}