import '../models/expense_claim_model.dart';

// ⚠️ Fix this import to match where ApiClient lives in your project.
import '../../../../core/network/api_client.dart';

class ExpenseClaimService {
  final ApiClient _api;

  /// Reuses the app's existing ApiClient (token + refresh handled there).
  ExpenseClaimService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  // GET /expenses/employee/:employeeId  -> bare JSON array, no pagination.
  Future<List<ExpenseClaimModel>> fetchEmployeeClaims(
      String employeeId,
      ) async {
    final data = await _api.get('/expenses/employee/$employeeId');

    if (data is! List) {
      throw Exception('Unexpected response while loading expense claims.');
    }

    return data
        .whereType<Map>()
        .map((e) => ExpenseClaimModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // POST /expenses
  // Body: category, amount, expenseDate (YYYY-MM-DD), description, billUrl (optional).
  // Errors (400 invalid amount, 409 duplicate) are thrown by ApiClient
  // with the server's message.
  Future<ExpenseClaimModel?> submitClaim({
    required String category,
    required double amount,
    required DateTime expenseDate,
    required String description,
    String? billUrl,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'amount': amount,
      'expenseDate': _formatDate(expenseDate),
      'description': description,
    };

    final bill = billUrl?.trim();
    if (bill != null && bill.isNotEmpty) {
      body['billUrl'] = bill;
    }

    final data = await _api.post('/expenses', body: body);

    return _parseSubmitResponse(data);
  }

  // The two docs disagree on the POST response shape, so accept both:
  //   raw document -> { "_id": ..., "status": ... }
  //   wrapped      -> { "message": ..., "expense": { ... } }
  ExpenseClaimModel? _parseSubmitResponse(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    final wrapped = map['expense'];
    if (wrapped is Map) {
      return ExpenseClaimModel.fromJson(Map<String, dynamic>.from(wrapped));
    }
    if (map['_id'] != null) {
      return ExpenseClaimModel.fromJson(map);
    }
    return null;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}