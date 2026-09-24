// =================================================================
// SHIFT MODEL
//
// Represents one configured shift (General, Night, Morning, etc).
//
// FIELD NAMING NOTE:
// Your API docs (sdocs.html) do not document a response shape for
// GET /shifts (the admin list) — only for GET /shifts/my-shift
// (the employee view), which uses "shiftName" and
// "gracePeriodMinutes" rather than "name" / "graceMinutes".
//
// Since the admin shape is unconfirmed, fromJson() below accepts
// EITHER naming so it parses whichever your backend actually sends,
// and toJson() sends both keys with the same value so a create/
// update request works whichever key your Express route reads.
// Once you confirm the real admin shape, this can be simplified to
// just the one true key.
// =================================================================

class ShiftModel {
  final String id;
  final String name;
  final String code;

  /// 24h "HH:mm" strings, e.g. "09:00".
  final String startTime;
  final String endTime;

  final int graceMinutes;
  final double requiredHours;
  final bool isOvernight;
  final bool isFlexiHours;
  final String? status;
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
    this.isFlexiHours = false,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? json['shiftName'] ?? '').toString(),
      code: (json['code'] ?? json['shiftCode'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      graceMinutes: _toInt(
        json['graceMinutes'] ?? json['gracePeriodMinutes'],
      ),
      requiredHours: _toDouble(
        json['requiredHours'] ?? json['requiredShiftHours'],
      ),
      isOvernight: json['isOvernight'] == true,
      isFlexiHours: json['isFlexiHours'] == true,
      status: json['status']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'shiftName': name,
      'code': code,
      'startTime': startTime,
      'endTime': endTime,
      'graceMinutes': graceMinutes,
      'gracePeriodMinutes': graceMinutes,
      'requiredHours': requiredHours,
      'isOvernight': isOvernight,
      'isFlexiHours': isFlexiHours,
      if (status != null) 'status': status,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}