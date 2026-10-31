import '../../../../core/network/api_client.dart'; // TODO: fix path if different
import '../endpoints/admin_employee_profile_endpoints.dart';
import '../models/admin_employee_profile_models.dart';
import '../models/admin_salary_structure_model.dart';

class AdminEmployeeProfileService {
  final ApiClient _api = ApiClient();

  // ------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------

  List<Map<String, dynamic>> _list(dynamic res, [List<String> keys = const []]) {
    List<dynamic> raw = const [];
    if (res is List) {
      raw = res;
    } else if (res is Map) {
      for (final k in [...keys, 'data', 'items']) {
        if (res[k] is List) {
          raw = res[k] as List;
          break;
        }
      }
    }
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  // ------------------------------------------------------------
  // account & company info
  // ------------------------------------------------------------

  Future<AdminProfileExtra> getExtra(String employeeId) async {
    var extra = const AdminProfileExtra();

    // 1) employee detail  -> company / user.lastLogin (if the API sends them)
    try {
      final res = _map(await _api.get(AdminEmployeeProfileEndpoints.detail(employeeId)));
      final company = _map(res['company']);
      final user = _map(res['user']);
      final empUser = _map(_map(res['employee'])['userId']);

      final last = user['lastLogin'] ?? user['lastLoginAt'] ??
          empUser['lastLogin'] ?? empUser['lastLoginAt'] ??
          res['lastLogin'] ?? res['lastLoginAt'];

      extra = extra.copyWith(
        companyName: company['name']?.toString(),
        timezone: company['timezone']?.toString(),
        lastLogin: last == null ? null : DateTime.tryParse(last.toString()),
      );
    } catch (_) {}

    // 2) fall back to /companies/me for name + timezone
    if (extra.companyName.isEmpty || extra.timezone.isEmpty) {
      try {
        final res = _map(await _api.get(AdminEmployeeProfileEndpoints.companyMe));
        final c = res['company'] is Map ? _map(res['company']) : res;
        extra = extra.copyWith(
          companyName: extra.companyName.isEmpty ? c['name']?.toString() : null,
          timezone: extra.timezone.isEmpty ? c['timezone']?.toString() : null,
        );
      } catch (_) {}
    }

    return extra;
  }

  // ------------------------------------------------------------
  // attendance
  // ------------------------------------------------------------

  Future<AdminAttendanceSummary> getAttendanceSummary(String id, int month, int year) async {
    final res = await _api.get(AdminEmployeeProfileEndpoints.attendanceSummary(id, month, year));
    return AdminAttendanceSummary.fromJson(res);
  }

  Future<List<AdminAttendanceLog>> getAttendanceLogs(String id, int month, int year) async {
    final res = await _api.get(AdminEmployeeProfileEndpoints.attendanceLogs(id, month, year));
    final logs = _list(res, ['attendance', 'records']).map(AdminAttendanceLog.fromJson).toList();
    logs.sort((a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)));
    return logs; // newest first
  }

  // ------------------------------------------------------------
  // leave
  // ------------------------------------------------------------

  Future<List<AdminLeaveBalance>> getLeaveBalances(String id, int year) async {
    final res = await _api.get(AdminEmployeeProfileEndpoints.leaveBalances(id, year));
    return _list(res, ['balances']).map(AdminLeaveBalance.fromJson).toList();
  }

  Future<List<AdminLeaveRequest>> getLeaveHistory(String id) async {
    final res = await _api.get(AdminEmployeeProfileEndpoints.leaveHistory(id));
    final list = _list(res, ['leaves']).map(AdminLeaveRequest.fromJson).toList();
    list.sort((a, b) => (b.startDate ?? DateTime(1970)).compareTo(a.startDate ?? DateTime(1970)));
    return list;
  }

  // ------------------------------------------------------------
  // salary
  // ------------------------------------------------------------

  Future<AdminSalaryStructure?> getSalaryStructure(String id) async {
    try {
      final res = await _api.get(AdminEmployeeProfileEndpoints.salaryStructure(id));
      return AdminSalaryStructure.fromResponse(res);
    } catch (_) {
      return null; // no structure yet
    }
  }

  Future<List<AdminSalarySlip>> getSalarySlips(String id) async {
    try {
      final res = await _api.get(AdminEmployeeProfileEndpoints.salarySlips(id));
      final list = _list(res, ['slips']).map(AdminSalarySlip.fromJson).toList();
      list.sort((a, b) => (b.year * 100 + b.month).compareTo(a.year * 100 + a.month));
      return list;
    } catch (_) {
      return [];
    }
  }

  // ------------------------------------------------------------
  // expenses
  // ------------------------------------------------------------

  Future<List<AdminExpenseItem>> getExpenses(String id) async {
    final res = await _api.get(AdminEmployeeProfileEndpoints.expenses(id));
    final list = _list(res, ['expenses']).map(AdminExpenseItem.fromJson).toList();
    list.sort((a, b) => (b.expenseDate ?? DateTime(1970)).compareTo(a.expenseDate ?? DateTime(1970)));
    return list;
  }

  // ------------------------------------------------------------
  // approve / reject (admin)
  // ------------------------------------------------------------

  Future<void> approveLeave(String leaveId) async =>
      _api.put(AdminEmployeeProfileEndpoints.leaveApprove(leaveId));

  Future<void> rejectLeave(String leaveId) async =>
      _api.put(AdminEmployeeProfileEndpoints.leaveReject(leaveId));

  Future<void> approveExpense(String expenseId) async =>
      _api.put(AdminEmployeeProfileEndpoints.expenseApprove(expenseId));

  Future<void> rejectExpense(String expenseId) async =>
      _api.put(AdminEmployeeProfileEndpoints.expenseReject(expenseId));

  // ------------------------------------------------------------
  // company calendar + manual attendance
  // ------------------------------------------------------------

  /// Holidays and week-offs. Empty when the API has nothing / fails.
  Future<List<AdminCalendarDay>> getCalendarDays(String companyId, int year) async {
    final paths = [
      AdminEmployeeProfileEndpoints.calendar(companyId, year),
      AdminEmployeeProfileEndpoints.holidays(companyId),
    ];

    for (final path in paths) {
      try {
        final res = await _api.get(path);
        final list = _list(res, ['calendar', 'days', 'holidays', 'entries'])
            .map(AdminCalendarDay.fromJson)
            .where((d) => d.dateKey.length == 10)
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return [];
  }

  /// POST /attendance/manual-mark  (status: present | late | half_day | absent | on_leave)
  Future<void> markAttendance({
    required String employeeId,
    required List<String> dates,
    required String status,
    String? notes,
  }) async {
    await _api.post(
      AdminEmployeeProfileEndpoints.manualMark,
      body: {
        'employeeId': employeeId,
        'dates': dates,
        'status': status,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
  }
}