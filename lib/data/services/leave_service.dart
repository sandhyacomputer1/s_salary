import '../../core/network/api_client.dart';

class LeaveService {
  final ApiClient _apiClient = ApiClient();

  // ==========================================================
  // GET LEAVE BALANCE
  // GET /leaves/balances/:employeeId
  // ==========================================================

  Future<Map<String, dynamic>> getLeaveBalance(
      String employeeId,
      ) async {
    final response = await _apiClient.get(
      '/leaves/balances/$employeeId',
    );

    if (response is! Map) {
      throw Exception(
        'Invalid leave balance response.',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }
}