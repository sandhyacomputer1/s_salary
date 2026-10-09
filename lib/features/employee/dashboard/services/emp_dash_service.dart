import '../../../../core/network/api_client.dart';

import '../endpoints/emp_dash_endpoints.dart';
import '../models/emp_dash_attendance_model.dart';
import '../models/emp_dash_checkin_result_model.dart';
import '../models/emp_dash_profile_model.dart';
import '../models/emp_dash_shift_model.dart';

class EmpDashService {
  final ApiClient _apiClient = ApiClient();

  Future<EmpDashProfileModel> getProfile() async {
    final response = await _apiClient.get(EmpDashEndpoints.profile);

    if (response is! Map) {
      throw Exception('Invalid profile response.');
    }

    return EmpDashProfileModel.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // GET ATTENDANCE HISTORY
  // GET /attendance/employee/:employeeId?month=M&year=Y
  // ============================================================

  Future<List<EmpDashAttendanceRecord>> getAttendanceHistory({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    final response = await _apiClient.get(
      EmpDashEndpoints.attendanceHistory(
        employeeId: employeeId,
        month: month,
        year: year,
      ),
    );

    if (response is! List) {
      throw Exception('Invalid attendance history response.');
    }

    return response
        .map(
          (json) => EmpDashAttendanceRecord.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  Future<EmpDashShiftModel> getMyShift() async {
    final response = await _apiClient.get(EmpDashEndpoints.myShift);

    if (response is! Map) {
      throw Exception('Invalid shift response.');
    }

    return EmpDashShiftModel.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<EmpDashCheckInResult> checkIn({
    required double lat,
    required double lng,
    String? photoUrl,
    String? deviceInfo,
    String? workMode,
  }) async {
    final response = await _apiClient.post(
      EmpDashEndpoints.checkIn,
      body: {
        'lat': lat,
        'lng': lng,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
        if (workMode != null) 'workMode': workMode,
      },
    );

    if (response is! Map) {
      throw Exception('Invalid check-in response.');
    }

    return EmpDashCheckInResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  Future<EmpDashCheckOutResult> checkOut({
    required double lat,
    required double lng,
    String? photoUrl,
  }) async {
    final response = await _apiClient.post(
      EmpDashEndpoints.checkOut,
      body: {
        'lat': lat,
        'lng': lng,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    );

    if (response is! Map) {
      throw Exception('Invalid check-out response.');
    }

    return EmpDashCheckOutResult.fromJson(
      Map<String, dynamic>.from(response),
    );
  }
}