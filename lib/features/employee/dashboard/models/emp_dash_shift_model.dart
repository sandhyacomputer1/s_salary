class EmpDashShiftModel {
  final String shiftName;
  final String startTime;
  final String endTime;
  final int gracePeriodMinutes;
  final List<String> weeklyOffs;

  const EmpDashShiftModel({
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodMinutes,
    required this.weeklyOffs,
  });

  factory EmpDashShiftModel.fromJson(Map<String, dynamic> json) {
    final offsJson = json['weeklyOffs'];

    return EmpDashShiftModel(
      shiftName: json['shiftName']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      gracePeriodMinutes: _toInt(json['gracePeriodMinutes']),
      weeklyOffs: offsJson is List
          ? offsJson.map((e) => e.toString()).toList()
          : <String>[],
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  bool isWeeklyOffToday(DateTime date) {
    const weekdayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final todayName = weekdayNames[date.weekday - 1];
    return weeklyOffs.any(
          (off) => off.toLowerCase() == todayName.toLowerCase(),
    );
  }
}