import '../../core/network/api_client.dart';

class BranchService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getBranches() async {
    final response = await _apiClient.get('/companies/branches');

    if (response is! List) {
      throw Exception('Invalid branches response.');
    }

    return response
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}