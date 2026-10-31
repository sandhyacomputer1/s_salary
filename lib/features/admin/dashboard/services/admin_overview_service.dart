import '../../../../core/network/api_client.dart'; // TODO: fix path if different
import '../models/admin_overview_models.dart';

/// Extra data for the dashboard overview (license limit + pending requests).
class AdminOverviewService {
  final ApiClient _api = ApiClient();

  List<Map<String, dynamic>> _list(dynamic res, List<String> keys) {
    List<dynamic> raw = const [];
    if (res is List) {
      raw = res;
    } else if (res is Map) {
      for (final k in [...keys, 'data', 'items']) {
        if (res[k] is List) {
          raw = res[k] as List;
          break;
        }
      }
    }
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// "5 / 10": the 10 comes from GET /companies/me -> license.maxEmployees.
  Future<int?> getMaxEmployees() async {
    final res = await _api.get('/companies/me');
    if (res is! Map) return null;
    final license = res['license'];
    if (license is! Map) return null;
    return int.tryParse('${license['maxEmployees']}');
  }

  Future<List<AdminPendingLeave>> getPendingLeaves() async {
    final res = await _api.get('/leaves?status=pending');
    return _list(res, ['leaves'])
        .where((j) => '${j['status'] ?? 'pending'}'.toLowerCase() == 'pending')
        .map(AdminPendingLeave.fromJson)
        .toList();
  }

  Future<List<AdminPendingExpense>> getPendingExpenses() async {
    final res = await _api.get('/expenses?status=pending');
    return _list(res, ['expenses'])
        .where((j) => '${j['status'] ?? 'pending'}'.toLowerCase() == 'pending')
        .map(AdminPendingExpense.fromJson)
        .toList();
  }
}