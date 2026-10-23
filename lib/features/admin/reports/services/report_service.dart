// lib/features/admin/reports/services/report_service.dart

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/report_models.dart';

class ReportService {
  final ApiClient _api;
  ReportService(this._api);

  /// API §4.2: GET /attendance/company/:companyId/matrix?month=&year=
  Future<List<MonthlyMatrixRow>> fetchMonthlyMatrix({
    required int month,
    required int year,
  }) async {
    final companyId = await SecureStorage.getCompanyId();
    if (companyId == null || companyId.isEmpty) {
      throw Exception('Company ID missing');
    }

    final endpoint =
        '/attendance/company/$companyId/matrix?month=$month&year=$year';
    final res = await _api.get(endpoint);

    // Backend returns { month, year, daysInMonth, matrix: [...] }
    final List list = (res is Map && res['matrix'] is List)
        ? res['matrix'] as List
        : const [];

    return list
        .whereType<Map>()
        .map((e) => MonthlyMatrixRow.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// API §4.2: POST /attendance/manual-mark
  Future<void> markManualAttendance({
    required String employeeId,
    required String dateIso,
    required String status,
    String? note,
  }) async {
    // Backend expects status values like: present|absent|half_day|leave|
    // on_leave|holiday|week_off. Our UI uses P/L/A/LV; map here.
    final payloadStatus = _mapUiStatusToApi(status);

    await _api.post(
      '/attendance/manual-mark',
      body: {
        'employeeId': employeeId,
        'dates': [dateIso], // backend accepts array; 'date' single string also works
        'status': payloadStatus,
        if (note != null && note.isNotEmpty) 'notes': note,
      },
    );
  }

  /// API §4.2: GET /reports/company/:companyId?date=
  Future<List<DailyWorkReport>> fetchDailyReports({
    DateTime? date,
    String? search,
  }) async {
    final companyId = await SecureStorage.getCompanyId();
    if (companyId == null || companyId.isEmpty) {
      throw Exception('Company ID missing');
    }

    final buf = StringBuffer('/reports/company/$companyId');
    if (date != null) {
      final d = '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      buf.write('?date=$d');
    }

    final res = await _api.get(buf.toString());

    // Backend returns bare array (or possibly {data:[]} envelope in some builds)
    final List list = res is List
        ? res
        : (res is Map && res['data'] is List)
        ? res['data'] as List
        : const [];

    var reports = list
        .whereType<Map>()
        .map((e) => DailyWorkReport.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Client-side search (backend has no search endpoint per docs)
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      reports = reports.where((r) {
        return r.employeeName.toLowerCase().contains(q) ||
            r.employeeCode.toLowerCase().contains(q) ||
            r.department.toLowerCase().contains(q);
      }).toList();
    }

    return reports;
  }

  String _mapUiStatusToApi(String ui) {
    switch (ui.toUpperCase()) {
      case 'P':
        return 'present';
      case 'L':
        return 'late';
      case 'A':
        return 'absent';
      case 'HD':
        return 'half_day';
      case 'LV':
      case 'H':
        return 'on_leave';
      case 'WO':
        return 'week_off';
      default:
        return 'present';
    }
  }
}