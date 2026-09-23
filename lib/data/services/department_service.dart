import '../../core/network/api_client.dart';

class DepartmentService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getDepartments() async {
    final response = await _apiClient.get('/departments');

    if (response is! List) {
      throw Exception('Invalid departments response.');
    }

    return response
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}