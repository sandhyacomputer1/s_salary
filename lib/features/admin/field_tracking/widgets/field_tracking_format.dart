import 'package:flutter/material.dart';

import '../models/field_employee_location_model.dart';

/// How trustworthy a "current location" is, based on its age.
enum LocationFreshness { live, recent, stale, unknownTime, noLocation }

/// Display helpers shared by the Field Tracking widgets.
/// Timestamps from the API are UTC; every display method converts to the
/// device's local time zone.
class FieldTrackingFormat {
  FieldTrackingFormat._();

  /// Employees ping about every 10 minutes (API reference), so a position up
  /// to 15 minutes old still counts as live.
  static const Duration liveWindow = Duration(minutes: 15);

  /// Older than [liveWindow] but within an hour: probably just a missed ping.
  static const Duration recentWindow = Duration(hours: 1);

  static const String unavailable = 'Not available';

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

  // ==========================================================
  // FRESHNESS
  // ==========================================================

  static LocationFreshness freshness(LocationPoint? point, {DateTime? now}) {
    if (point == null) return LocationFreshness.noLocation;

    final stamp = point.timestamp;
    if (stamp == null) return LocationFreshness.unknownTime;

    final age = (now ?? DateTime.now()).toUtc().difference(stamp.toUtc());

    // A small negative age is just clock skew between phone and server.
    if (age <= liveWindow) return LocationFreshness.live;
    if (age <= recentWindow) return LocationFreshness.recent;
    return LocationFreshness.stale;
  }

  static String freshnessLabel(LocationFreshness f) {
    switch (f) {
      case LocationFreshness.live:
        return 'Live';
      case LocationFreshness.recent:
        return 'Recent';
      case LocationFreshness.stale:
        return 'Stale';
      case LocationFreshness.unknownTime:
        return 'Time unknown';
      case LocationFreshness.noLocation:
        return 'No location';
    }
  }

  static Color freshnessColor(LocationFreshness f) {
    switch (f) {
      case LocationFreshness.live:
        return const Color(0xFF18864B);
      case LocationFreshness.recent:
        return const Color(0xFFE8A317);
      case LocationFreshness.stale:
        return const Color(0xFFC62828);
      case LocationFreshness.unknownTime:
        return const Color(0xFF64748B);
      case LocationFreshness.noLocation:
        return const Color(0xFF94A3B8);
    }
  }

  // ==========================================================
  // TIME
  // ==========================================================

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// "13 Oct 2026"
  static String date(DateTime value) {
    final d = value.toLocal();
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  /// "9:49 AM"
  static String time(DateTime value) {
    final d = value.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$hour:${_two(d.minute)} ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  /// "13 Oct 2026, 9:49 AM", or [unavailable].
  static String dateTime(DateTime? value) {
    if (value == null) return unavailable;
    return '${date(value)}, ${time(value)}';
  }

  /// "9:49 AM", or [unavailable].
  static String timeOnly(DateTime? value) {
    if (value == null) return unavailable;
    return time(value);
  }

  /// "Just now", "12 min ago", "3 h ago", "2 d ago", or [unavailable].
  static String relative(DateTime? value, {DateTime? now}) {
    if (value == null) return unavailable;

    final age = (now ?? DateTime.now()).toUtc().difference(value.toUtc());

    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes} min ago';
    if (age.inHours < 24) return '${age.inHours} h ago';
    return '${age.inDays} d ago';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  // ==========================================================
  // OTHER FIELDS
  // ==========================================================

  /// "63%", or [unavailable] when missing or outside 0-100.
  static String battery(int? level) {
    if (level == null || level < 0 || level > 100) return unavailable;
    return '$level%';
  }

  static bool hasBattery(int? level) =>
      level != null && level >= 0 && level <= 100;

  /// "19.076000, 72.877700"
  static String coordinates(double lat, double lng) =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

  static String address(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? unavailable : text;
  }
}
