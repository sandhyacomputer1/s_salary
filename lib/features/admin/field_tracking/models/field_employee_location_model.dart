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

String _text(dynamic v) => v?.toString().trim() ?? '';

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// One GPS fix. Only created when the coordinates are real.
class LocationPoint {
  final double lat;
  final double lng;
  final String? address;
  final int? batteryLevel;

  /// Parsed as UTC when the string ends in "Z"; use [localTime] for display.
  final DateTime? timestamp;

  const LocationPoint({
    required this.lat,
    required this.lng,
    this.address,
    this.batteryLevel,
    this.timestamp,
  });

  DateTime? get localTime => timestamp?.toLocal();

  /// False for out-of-range values and for the (0, 0) "null island" default
  /// that a failed GPS read often produces.
  static bool isValid(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  /// Returns null (never a fabricated point) when coordinates are missing
  /// or invalid.
  static LocationPoint? tryParse(
    Map<String, dynamic> json, {
    DateTime? fallbackTime,
  }) {
    final lat = _toDouble(json['lat'] ?? json['latitude']);
    final lng = _toDouble(json['lng'] ?? json['lon'] ?? json['longitude']);

    if (!isValid(lat, lng)) return null;

    final address = _text(json['address']);
    final battery = _toInt(json['batteryLevel'] ?? json['battery']);

    final stamp =
        DateTime.tryParse(
          _text(json['timestamp'] ?? json['recordedAt'] ?? json['time']),
        ) ??
        fallbackTime;

    return LocationPoint(
      lat: lat!,
      lng: lng!,
      address: address.isEmpty ? null : address,
      batteryLevel: battery,
      timestamp: stamp,
    );
  }
}

/// One field employee from GET /attendance/company/:companyId/field-locations.
///
/// !!! The response of that endpoint is NOT documented in the API reference.
/// This parser accepts the likely shapes:
///   [ { _id, name, employeeCode, ..., lastKnownLocation: {lat,lng,...} } ]
///   [ { employee: {...}, lastKnownLocation / location: {...} } ]
///   [ { _id, name, lat, lng, ... } ]
/// If your real response differs, employees will show as "No location data"
/// instead of showing wrong positions. Send me one real record and I will
/// match it exactly.
class FieldEmployeeLocation {
  final String id; // employee id, used for the location-history call
  final String name;
  final String employeeCode;
  final String designation;
  final String department;
  final String phone;

  /// null when the employee has never reported a location.
  final LocationPoint? location;

  const FieldEmployeeLocation({
    required this.id,
    required this.name,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.phone,
    this.location,
  });

  bool get hasLocation => location != null;

  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return '?';

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory FieldEmployeeLocation.fromJson(Map<String, dynamic> json) {
    final nested = _asMap(json['employee']);
    final base = nested.isEmpty ? json : nested;

    final rawLocation =
        json['lastKnownLocation'] ??
        json['location'] ??
        json['lastLocation'] ??
        base['lastKnownLocation'];

    var locationMap = _asMap(rawLocation);

    // Flat shape: lat/lng sit directly on the record.
    if (locationMap.isEmpty &&
        (json.containsKey('lat') || json.containsKey('latitude'))) {
      locationMap = json;
    }

    // Only dedicated "last location time" keys are used as a fallback.
    // updatedAt is NOT used, because it would make an old position look fresh.
    final fallbackTime = DateTime.tryParse(
      _text(
        json['lastLocationAt'] ??
            json['lastLocationTime'] ??
            json['lastPingAt'] ??
            base['lastLocationAt'],
      ),
    );

    return FieldEmployeeLocation(
      id: _text(base['_id'] ?? base['id'] ?? json['employeeId'] ?? json['_id']),
      name: _text(base['name']),
      employeeCode: _text(base['employeeCode']),
      designation: _text(base['designation']),
      department: _text(base['department']),
      phone: _text(base['phone']),
      location: locationMap.isEmpty
          ? null
          : LocationPoint.tryParse(locationMap, fallbackTime: fallbackTime),
    );
  }

  /// Accepts a bare array, or an object holding the array.
  static List<FieldEmployeeLocation> listFromResponse(dynamic body) {
    dynamic list = body;

    if (body is Map) {
      list = body['employees'] ?? body['locations'] ?? body['data'];
    }

    if (list is! List) return const [];

    return list
        .whereType<Map>()
        .map(
          (e) => FieldEmployeeLocation.fromJson(Map<String, dynamic>.from(e)),
        )
        .where((e) => e.id.isNotEmpty)
        .toList();
  }
}
