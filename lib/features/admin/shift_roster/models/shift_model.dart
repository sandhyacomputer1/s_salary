// =================================================================
// SHIFT MODEL
//
// Represents one configured company shift.
//
// Example API response:
//
// {
//   "_id": "...",
//   "companyId": "...",
//   "name": "General Shift",
//   "code": "GS",
//   "startTime": "09:00",
//   "endTime": "18:00",
//   "isOvernight": false,
//   "graceMinutes": 15,
//   "flexiHoursEnabled": false,
//   "requiredHours": 8,
//   "color": "#2563eb",
//   "isActive": true,
//   "createdAt": "...",
//   "updatedAt": "..."
// }
// =================================================================

class ShiftModel {
  final String id;
  final String name;
  final String code;
  bool get isFlexiHours => flexiHoursEnabled;
  /// 24-hour HH:mm format.
  final String startTime;
  final String endTime;

  final int graceMinutes;
  final double requiredHours;

  final bool isOvernight;

  /// Backend field:
  /// flexiHoursEnabled
  final bool flexiHoursEnabled;

  final String? color;

  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShiftModel({
    required this.id,
    required this.name,
    required this.code,
    required this.startTime,
    required this.endTime,
    required this.graceMinutes,
    required this.requiredHours,
    this.isOvernight = false,
    this.flexiHoursEnabled = false,
    this.color,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory ShiftModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ShiftModel(
      id: (
          json['id'] ??
              json['_id'] ??
              ''
      ).toString(),

      name: (
          json['name'] ??
              json['shiftName'] ??
              ''
      ).toString(),

      code: (
          json['code'] ??
              json['shiftCode'] ??
              ''
      ).toString(),

      startTime: (
          json['startTime'] ??
              ''
      ).toString(),

      endTime: (
          json['endTime'] ??
              ''
      ).toString(),

      graceMinutes: _toInt(
        json['graceMinutes'] ??
            json['gracePeriodMinutes'],
      ),

      requiredHours: _toDouble(
        json['requiredHours'] ??
            json['requiredShiftHours'],
      ),

      isOvernight:
      json['isOvernight'] == true,

      flexiHoursEnabled:
      json['flexiHoursEnabled'] == true ||
          json['isFlexiHours'] == true,

      color: json['color']?.toString(),

      isActive:
      json['isActive'] == null
          ? true
          : json['isActive'] == true,

      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ),

      updatedAt: DateTime.tryParse(
        json['updatedAt']?.toString() ?? '',
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'startTime': startTime,
      'endTime': endTime,
      'graceMinutes': graceMinutes,
      'requiredHours': requiredHours,
      'isOvernight': isOvernight,
      'flexiHoursEnabled': flexiHoursEnabled,
      'color': color,
      'isActive': isActive,
    };
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0.0;
  }

  // ============================================================
  // DISPLAY HELPERS
  // ============================================================

  String get displayName {
    if (code.trim().isEmpty) {
      return name;
    }

    return '$name ($code)';
  }

  String get timingDisplay {
    return '$startTime – $endTime';
  }

  String get graceDisplay {
    return '${graceMinutes}m';
  }

  String get requiredHoursDisplay {
    return '${requiredHours.toStringAsFixed(0)}h';
  }
}