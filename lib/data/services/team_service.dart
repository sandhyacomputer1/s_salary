import '../../core/network/api_client.dart';

class TeamService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Map<String, dynamic>>> getTeamMembers() async {
    final response = await _apiClient.get('/companies/sub-admins');

    if (response is! List) {
      throw Exception('Invalid team response.');
    }

    return response
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}