// Pure Dart, no dependencies. Each validator returns an error message
// or null, so they plug straight into TextFormField.validator.

class BranchValidators {
  BranchValidators._();

  static const weekDays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String? required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? email(String? v, {bool isRequired = true}) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return isRequired ? 'Login email is required' : null;
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s);
    return ok ? null : 'Enter a valid email address';
  }

  /// Optional. Accepts 7-15 digits, ignoring spaces, dashes and a leading '+'.
  static String? phone(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    final digits = s.replaceAll(RegExp(r'[\s\-+]'), '');
    return RegExp(r'^\d{7,15}$').hasMatch(digits)
        ? null
        : 'Enter a valid phone number';
  }

  /// The web form says "Min 6 characters".
  static String? password(String? v, {bool isRequired = true}) {
    final s = v ?? '';
    if (s.isEmpty) return isRequired ? 'Password is required' : null;
    return s.length < 6 ? 'Minimum 6 characters' : null;
  }

  static String? latitude(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    final n = double.tryParse(s);
    if (n == null) return 'Enter a valid number';
    if (n < -90 || n > 90) return 'Latitude must be between -90 and 90';
    return null;
  }

  static String? longitude(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    final n = double.tryParse(s);
    if (n == null) return 'Enter a valid number';
    if (n < -180 || n > 180) return 'Longitude must be between -180 and 180';
    return null;
  }

  /// Cross-field check: latitude and longitude must be given together.
  static String? latLngPair(String? lat, String? lng) {
    final hasLat = (lat ?? '').trim().isNotEmpty;
    final hasLng = (lng ?? '').trim().isNotEmpty;
    if (hasLat != hasLng) return 'Provide both latitude and longitude';
    return null;
  }

  static String? radius(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    final n = int.tryParse(s);
    if (n == null) return 'Enter a whole number';
    if (n < 10 || n > 5000) return 'Radius must be 10-5000 meters';
    return null;
  }

  static String? time(String? v, String label) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    final ok = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s);
    return ok ? null : '$label must be HH:mm (e.g. 09:00)';
  }

  static String? grace(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null; // optional
    final n = int.tryParse(s);
    if (n == null) return 'Enter a whole number';
    if (n < 0 || n > 240) return 'Grace period must be 0-240 minutes';
    return null;
  }

  /// Shift end must be after shift start (same-day shifts only).
  static String? shiftOrder(String? start, String? end) {
    if (time(start, 'Start') != null || time(end, 'End') != null) return null;
    if ((start ?? '').isEmpty || (end ?? '').isEmpty) return null;

    int mins(String t) {
      final p = t.split(':');
      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    return mins(end!) > mins(start!)
        ? null
        : 'Shift end must be after shift start';
  }
}