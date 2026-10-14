import 'package:flutter/material.dart';

/// Display helpers for the Audit Trail screen.
class AuditFormat {
  AuditFormat._();

  /// Shown whenever a value is missing. Never replaced with made-up data.
  static const String empty = '—';

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// "13 Oct 2026 03:45:26 pm" in the device's local time zone.
  /// The API sends UTC; a missing or malformed value shows [empty].
  static String timestamp(DateTime? value) {
    if (value == null) return empty;

    final d = value.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'pm' : 'am';

    return '${_two(d.day)} ${_months[d.month - 1]} ${d.year} '
        '${_two(hour)}:${_two(d.minute)}:${_two(d.second)} $period';
  }

  /// Returns [empty] for null or blank text.
  static String text(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? empty : trimmed;
  }

  // ==========================================================
  // STATUS COLOURS (case-insensitive; unknown values stay neutral)
  // ==========================================================

  static Color statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFF18864B);
      case 'FAILED':
        return const Color(0xFFC62828);
      case 'WARNING':
        return const Color(0xFFB45309);
      default:
        return const Color(0xFF4B5563);
    }
  }

  static Color statusBackground(String status) {
    switch (status.trim().toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFFE9F8EF);
      case 'FAILED':
        return const Color(0xFFFDECEC);
      case 'WARNING':
        return const Color(0xFFFFF4DB);
      default:
        return const Color(0xFFF1F3F6);
    }
  }
}