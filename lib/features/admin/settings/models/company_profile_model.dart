import 'dart:convert';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

String _text(dynamic v, [String fallback = '']) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? fallback : s;
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// Company details edited on the "Profile & Location" tab.
///
/// Parsed from the `company` object of GET /companies/me:
///   { _id, name, address, timezone, location: {lat, lng},
///     checkInRadiusMeters, isActive, ... }
/// This is a mutable working copy: the screen edits it and compares
/// [fingerprint] with the loaded copy to know whether anything changed.
class CompanyProfile {
  CompanyProfile({
    required this.id,
    required this.name,
    required this.address,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
  });

  final String id;
  String name;
  String address;
  String timezone;
  double? latitude;
  double? longitude;
  int radiusMeters;
  bool isActive;

  bool get hasPin => latitude != null && longitude != null;

  /// Same rule as the field-tracking module: in range and not (0, 0).
  static bool isValidPoint(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  factory CompanyProfile.fromResponse(dynamic body) {
    final root = _asMap(body);
    final company = root['company'] is Map ? _asMap(root['company']) : root;
    final location = _asMap(company['location']);

    final lat = _toDouble(location['lat']);
    final lng = _toDouble(location['lng']);
    final valid = isValidPoint(lat, lng);

    return CompanyProfile(
      id: _text(company['_id'] ?? company['id']),
      name: _text(company['name']),
      address: _text(company['address']),
      timezone: _text(company['timezone'], 'UTC'),
      latitude: valid ? lat : null,
      longitude: valid ? lng : null,
      radiusMeters: _toInt(company['checkInRadiusMeters']) ?? 100,
      isActive: company['isActive'] != false,
    );
  }

  CompanyProfile copy() => CompanyProfile(
    id: id,
    name: name,
    address: address,
    timezone: timezone,
    latitude: latitude,
    longitude: longitude,
    radiusMeters: radiusMeters,
    isActive: isActive,
  );

  String get fingerprint => jsonEncode({
    'name': name.trim(),
    'address': address.trim(),
    'timezone': timezone.trim(),
    'lat': latitude,
    'lng': longitude,
    'radius': radiusMeters,
    'active': isActive,
  });
}
