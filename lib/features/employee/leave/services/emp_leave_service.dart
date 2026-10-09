import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../endpoints/emp_leave_endpoints.dart';
import '../models/emp_leave_balance_model.dart';
import '../models/emp_leave_model.dart';

/// Every error leaving this service is already a user-friendly message.
class EmpLeaveException implements Exception {
  final String message;

  const EmpLeaveException(this.message);

  @override
  String toString() => message;
}

class EmpLeaveService {
  final ApiClient _apiClient = ApiClient();

  static const Duration _timeout = Duration(seconds: 20);

  String? _employeeId;

  // ============================================================
  // BALANCES — GET /leaves/balances/:employeeId
  // ============================================================

  Future<List<EmpLeaveBalanceModel>> getLeaveBalances() {
    return _guard(() async {
      final employeeId = await _resolveEmployeeId();

      final response = await _apiClient
          .get(EmpLeaveEndpoints.balances(employeeId))
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('EMP LEAVE BALANCES RAW: $response');
      }

      // Only a list of per-type balance documents can feed the cards.
      if (response is! List) return <EmpLeaveBalanceModel>[];

      final all = response
          .whereType<Map>()
          .map((j) => EmpLeaveBalanceModel.fromJson(
        Map<String, dynamic>.from(j),
      ))
          .where((b) => b.leaveType.isNotEmpty)
          .toList();

      final year = DateTime.now().year;
      final current = all.where((b) => b.year == year).toList();

      return current.isNotEmpty ? current : all;
    });
  }

  // ============================================================
  // HISTORY — GET /leaves/employee/:employeeId
  // ============================================================

  Future<List<EmpLeaveModel>> getLeaveHistory() {
    return _guard(() async {
      final employeeId = await _resolveEmployeeId();

      final response = await _apiClient
          .get(EmpLeaveEndpoints.history(employeeId))
          .timeout(_timeout);

      if (response is! List) {
        throw const EmpLeaveException(
          'The server sent an unexpected response. Please try again.',
        );
      }

      final leaves = response
          .whereType<Map>()
          .map((j) => EmpLeaveModel.fromJson(Map<String, dynamic>.from(j)))
          .toList();

      // Newest first, so a just-submitted request appears at the top.
      leaves.sort((a, b) {
        final aDate = a.appliedOn;
        final bDate = b.appliedOn;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return leaves;
    });
  }

  // ============================================================
  // APPLY — POST /leaves/apply
  // ============================================================

  Future<void> submitLeaveRequest(EmpLeaveRequest request) {
    return _guard(() async {
      if (kDebugMode) {
        debugPrint('EMP LEAVE APPLY BODY: ${request.toJson()}');
      }

      final response = await _apiClient
          .post(EmpLeaveEndpoints.apply, body: request.toJson())
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('EMP LEAVE APPLY RESPONSE: $response');
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
    final response =
    await _apiClient.get(EmpLeaveEndpoints.profile).timeout(_timeout);

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

    throw const EmpLeaveException(
      'Unable to identify your employee profile. Please log in again.',
    );
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on EmpLeaveException {
      rethrow;
    } catch (e) {
      throw EmpLeaveException(_friendlyMessage(e));
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
          return 'The request was invalid. Please review your details and try again.';
        case '401':
          return 'Your session has expired. Please log in again.';
        case '403':
          return 'You do not have permission to do this.';
        case '404':
          return 'The requested information was not found.';
        case '409':
          return 'This request conflicts with an existing leave application.';
        default:
          return status.startsWith('5')
              ? 'The server ran into a problem. Please try again later.'
              : generic;
      }
    }

    // Backend "message" text (e.g. "Insufficient leave balance") passes through.
    return message.isEmpty ? generic : message;
  }
}