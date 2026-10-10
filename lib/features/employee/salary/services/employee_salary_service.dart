// lib/features/employee/salary/services/employee_salary_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/employee_salary_breakdown_model.dart';
import '../models/employee_salary_slip_model.dart';
import '../models/employee_salary_structure_model.dart';

class EmployeeSalaryService {
  final ApiClient _client;

  EmployeeSalaryService({ApiClient? client}) : _client = client ?? ApiClient();

  /// GET /salary/structure/:employeeId
  Future<EmployeeSalaryStructureModel> fetchStructure(String employeeId) async {
    final data = await _client.get('/salary/structure/$employeeId');
    if (data is! Map) {
      throw Exception('Unexpected salary structure response.');
    }
    return EmployeeSalaryStructureModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// GET /salary/slips/:employeeId
  Future<List<EmployeeSalarySlipModel>> fetchSlips(String employeeId) async {
    final data = await _client.get('/salary/slips/$employeeId');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (e) => EmployeeSalarySlipModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  /// GET /salary/slip/:employeeId?month=&year=  (JSON)
  Future<EmployeeSalaryBreakdownModel> fetchSlipDetail({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    final data = await _client.get(
      '/salary/slip/$employeeId?month=$month&year=$year',
    );
    if (data is! Map) {
      throw Exception('Unexpected salary slip response.');
    }
    return EmployeeSalaryBreakdownModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// GET /salary/slip/:employeeId?month=&year=&format=html
  ///
  /// The response is HTML, NOT JSON. Do not route this through ApiClient.
  Future<String> fetchSlipHtml({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    final token = await SecureStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication required. Please login again.');
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/salary/slip/$employeeId'
      '?month=$month&year=$year&format=html',
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'text/html', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Unable to load payslip (status ${response.statusCode}).',
      );
    }
    if (response.body.isEmpty) {
      throw Exception('Payslip document was empty.');
    }
    return response.body;
  }
}

final employeeSalaryServiceProvider = Provider<EmployeeSalaryService>((ref) {
  return EmployeeSalaryService();
});
