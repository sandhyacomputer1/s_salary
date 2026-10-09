import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../endpoints/emp_daily_report_endpoints.dart';
import '../models/emp_daily_report_model.dart';

/// Every error leaving this service is already a user-friendly message.
class EmpDailyReportException implements Exception {
  final String message;

  const EmpDailyReportException(this.message);

  @override
  String toString() => message;
}

class EmpDailyReportService {
  final ApiClient _apiClient = ApiClient();

  static const Duration _timeout = Duration(seconds: 20);

  String? _employeeId;

  // ============================================================
  // HISTORY — GET /reports/employee/:employeeId (newest first)
  // ============================================================

  Future<List<EmpDailyReportModel>> getReportHistory() {
    return _guard(() async {
      final employeeId = await _resolveEmployeeId();

      final response = await _apiClient
          .get(EmpDailyReportEndpoints.history(employeeId))
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('EMP DAILY REPORT HISTORY RAW: $response');
      }

      if (response == null) return <EmpDailyReportModel>[];

      if (response is! List) {
        throw const EmpDailyReportException(
          'The server sent an unexpected response. Please try again.',
        );
      }

      final reports = response
          .whereType<Map>()
          .map((j) => EmpDailyReportModel.fromJson(
        Map<String, dynamic>.from(j),
      ))
          .toList();

      // Documented newest-first; sort by report date to be safe.
      reports.sort((a, b) {
        if (a.dateKey.isEmpty && b.dateKey.isEmpty) return 0;
        if (a.dateKey.isEmpty) return 1;
        if (b.dateKey.isEmpty) return -1;
        return b.dateKey.compareTo(a.dateKey);
      });

      return reports;
    });
  }

  // ============================================================
  // TODAY — GET /reports/employee/:employeeId?date=YYYY-MM-DD
  // Returns a single object, or null when no report exists.
  // ============================================================

  Future<EmpDailyReportModel?> getTodayReport(DateTime day) {
    return _guard(() async {
      final employeeId = await _resolveEmployeeId();

      final response = await _apiClient
          .get(
        EmpDailyReportEndpoints.byDate(
          employeeId,
          EmpDailyReportFormat.api(day),
        ),
      )
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('EMP DAILY REPORT TODAY RAW: $response');
      }

      if (response is Map) {
        return EmpDailyReportModel.fromJson(
          Map<String, dynamic>.from(response),
        );
      }

      return null;
    });
  }

  // ============================================================
  // SUBMIT — POST /reports (upsert: one report per employee per date)
  // ============================================================

  Future<void> submitDailyReport(EmpDailyReportInput input) {
    return _guard(() async {
      if (kDebugMode) {
        debugPrint('EMP DAILY REPORT BODY: ${input.toJson()}');
      }

      final response = await _apiClient
          .post(EmpDailyReportEndpoints.create, body: input.toJson())
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('EMP DAILY REPORT RESPONSE: $response');
      }
    });
  }

  // ============================================================
  // EMPLOYEE ID
  // ============================================================

  Future<String> _resolveEmployeeId() async {
    final cached = _employeeId;
    if (cached != null && cached.isNotEmpty) return cached;

    final stored = await SecureStorage.getEmployeeId();
    if (stored != null && stored.isNotEmpty) {
      _employeeId = stored;
      return stored;
    }

    // Fallback: GET /employees/me → { employee: { _id, ... }, ... }
    final response = await _apiClient
        .get(EmpDailyReportEndpoints.profile)
        .timeout(_timeout);

    if (response is Map) {
      final employee = response['employee'];
      if (employee is Map) {
        final id = employee['_id']?.toString();
        if (id != null && id.isNotEmpty) {
          _employeeId = id;
          return id;
        }
      }
    }

    throw const EmpDailyReportException(
      'Unable to identify your employee profile. Please log in again.',
    );
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on EmpDailyReportException {
      rethrow;
    } catch (e) {
      throw EmpDailyReportException(_friendlyMessage(e));
    }
  }

  static String _friendlyMessage(Object error) {
    const generic = 'Something went wrong. Please try again.';

    if (error is TimeoutException) {
      return 'The request timed out. Please check your connection and try again.';
    }

    if (error is! Exception) return generic;

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = message.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('failed to fetch')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (lower.contains('formatexception') ||
        lower.contains('invalid response')) {
      return 'The server sent an unexpected response. Please try again.';
    }

    // ApiClient uses this text when the backend sent no "message".
    final status = RegExp(r'status code: (\d{3})').firstMatch(lower)?.group(1);

    if (status != null) {
      switch (status) {
        case '400':
          return 'The request was invalid. Please review your report and try again.';
        case '401':
          return 'Your session has expired. Please log in again.';
        case '403':
          return 'You do not have permission to do this.';
        case '404':
          return 'The requested information was not found.';
        default:
          return status.startsWith('5')
              ? 'The server ran into a problem. Please try again later.'
              : generic;
      }
    }

    // Backend "message" text passes through.
    return message.isEmpty ? generic : message;
  }
}