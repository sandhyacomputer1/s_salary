import 'field_employee_location_model.dart';

String _text(dynamic v) => v?.toString().trim() ?? '';

/// Response of GET /attendance/employee/:employeeId/location-history?date=
///
/// Logs with missing or invalid coordinates are dropped (never replaced with
/// made-up points) and counted in [skippedCount] so the UI can say so.
class LocationHistory {
  final String employeeName;
  final String employeeCode;
  final String date; // YYYY-MM-DD

  /// Valid points in chronological order.
  final List<LocationPoint> points;

  /// Number of log entries the API returned.
  final int totalRecords;

  /// Log entries ignored because their coordinates were missing or invalid.
  final int skippedCount;

  const LocationHistory({
    required this.employeeName,
    required this.employeeCode,
    required this.date,
    required this.points,
    required this.totalRecords,
    required this.skippedCount,
  });

  bool get isEmpty => points.isEmpty;

  /// A route line needs at least two points.
  bool get hasRoute => points.length >= 2;

  LocationPoint? get first => points.isEmpty ? null : points.first;

  LocationPoint? get latest => points.isEmpty ? null : points.last;

  factory LocationHistory.empty(String date) => LocationHistory(
    employeeName: '',
    employeeCode: '',
    date: date,
    points: const [],
    totalRecords: 0,
    skippedCount: 0,
  );

  factory LocationHistory.fromResponse(
    dynamic body, {
    required String requestedDate,
  }) {
    if (body is! Map) return LocationHistory.empty(requestedDate);

    final json = Map<String, dynamic>.from(body);

    final employee = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'] as Map)
        : <String, dynamic>{};

    final rawLogs = json['logs'] is List ? json['logs'] as List : const [];

    final points = <LocationPoint>[];
    var skipped = 0;

    for (final item in rawLogs) {
      if (item is! Map) {
        skipped++;
        continue;
      }

      final point = LocationPoint.tryParse(Map<String, dynamic>.from(item));

      if (point == null) {
        skipped++;
      } else {
        points.add(point);
      }
    }

    // Sort by time only when every point has a timestamp; otherwise keep the
    // order the API returned rather than guess.
    if (points.length > 1 && points.every((p) => p.timestamp != null)) {
      points.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
    }

    final date = _text(json['date']);

    return LocationHistory(
      employeeName: _text(employee['name']),
      employeeCode: _text(employee['employeeCode']),
      date: date.isEmpty ? requestedDate : date,
      points: points,
      totalRecords: rawLogs.length,
      skippedCount: skipped,
    );
  }
}
