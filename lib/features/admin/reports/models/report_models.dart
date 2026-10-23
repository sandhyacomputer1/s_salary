// lib/features/admin/reports/models/report_models.dart

class MonthlyMatrixRow {
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final Map<int, String> dailyStatus;
  final int present;
  final int late;
  final int halfDay;
  final int leave;
  final int holiday;
  final int weekOff;
  final int absent;
  final double hours;

  const MonthlyMatrixRow({
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.dailyStatus,
    required this.present,
    required this.late,
    required this.halfDay,
    required this.leave,
    required this.holiday,
    required this.weekOff,
    required this.absent,
    required this.hours,
  });

  factory MonthlyMatrixRow.fromJson(Map<String, dynamic> j) {
    final daysRaw = (j['days'] ?? {}) as Map;
    final summary = (j['summary'] ?? {}) as Map;

    final Map<int, String> daily = {};
    daysRaw.forEach((k, v) {
      final day = int.tryParse(k.toString());
      if (day != null) {
        final code = v.toString().toUpperCase();
        // Backend may send "-" for future days; keep it so the grid shows a dash
        daily[day] = code.isEmpty ? '-' : code;
      }
    });

    int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

    return MonthlyMatrixRow(
      employeeId: (j['employeeId'] ?? '').toString(),
      employeeName: (j['name'] ?? 'Unknown').toString(),
      employeeCode: (j['employeeCode'] ?? '').toString(),
      department: (j['department'] ?? '').toString(),
      dailyStatus: daily,
      present: asInt(summary['presentCount']),
      late: asInt(summary['lateCount']),
      halfDay: asInt(summary['halfDayCount']),
      leave: asInt(summary['leaveCount']),
      holiday: asInt(summary['holidayCount']),
      weekOff: asInt(summary['weekOffCount']),
      absent: asInt(summary['absentCount']),
      hours: asDouble(summary['totalHours']),
    );
  }
}

class DailyWorkReport {
  final String id;
  final DateTime date;
  final String employeeName;
  final String employeeCode;
  final String designation;
  final String department;
  final String completedWork;
  final String ongoingTasks;
  final String planForTomorrow;

  const DailyWorkReport({
    required this.id,
    required this.date,
    required this.employeeName,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.completedWork,
    required this.ongoingTasks,
    required this.planForTomorrow,
  });

  factory DailyWorkReport.fromJson(Map<String, dynamic> j) {
    final emp = (j['employeeId'] ?? j['employee'] ?? {}) as Map? ?? {};

    // Check for 'user', 'userId', or 'userID'
    final user = (emp['userID'] ?? emp['user'] ?? emp['userId'] ?? emp) as Map? ?? {};

    return DailyWorkReport(
      id: (j['_id'] ?? '').toString(),
      date: DateTime.tryParse(
        (j['date'] ?? j['reportDate'] ?? '').toString(),
      ) ??
          DateTime.now(),
      // Look for 'name' in the user object, or fallback to emp, or root
      employeeName: (user['name'] ?? emp['name'] ?? j['name'] ?? 'Unknown').toString(),
      employeeCode: (emp['employeeCode'] ?? j['employeeCode'] ?? '').toString(),
      designation: (emp['designation'] ?? user['designation'] ?? '').toString(),
      department: (emp['department'] ?? '').toString(),
      completedWork: (j['completedWork'] ?? j['workDoneToday'] ?? '').toString(),
      ongoingTasks: (j['ongoingWork'] ?? j['ongoingTasks'] ?? '').toString(),
      planForTomorrow: (j['planForTomorrow'] ?? '').toString(),
    );
  }
}