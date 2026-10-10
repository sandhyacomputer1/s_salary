// lib/features/employee/profile/services/employee_profile_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/employee_profile_details_model.dart';
import '../models/employee_profile_model.dart';

class EmployeeProfileService {
  final ApiClient _client;

  EmployeeProfileService({ApiClient? client})
      : _client = client ?? ApiClient();

  /// GET /employees/me — full self profile.
  Future<EmployeeProfileModel> fetchMyProfile() async {
    final data = await _client.get('/employees/me');
    if (data is! Map) {
      throw Exception('Unexpected profile response.');
    }
    return EmployeeProfileModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// PUT /employees/:id/personal-details
  ///
  /// `employeeDocId` must be the employee document `_id` returned by
  /// `GET /employees/me`. Not the user id.
  ///
  /// The request accepts personalDetails and bankDetails either nested
  /// (as sent here) or flat. Enum values must be lowercase.
  Future<void> updatePersonalDetails({
    required String employeeDocId,
    required PersonalDetails personal,
    required BankDetails bank,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'personalDetails': personal.toUpdateJson(),
      'bankDetails': bank.toUpdateJson(),
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };
    await _client.put(
      '/employees/$employeeDocId/personal-details',
      body: body,
    );
  }
}

final employeeProfileServiceProvider =
Provider<EmployeeProfileService>((ref) {
  return EmployeeProfileService();
});