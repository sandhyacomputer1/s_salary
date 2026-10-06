import '../../../../core/network/api_client.dart';

import '../endpoints/expense_endpoints.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // GET ALL EXPENSES
  // ============================================================

  Future<List<ExpenseModel>> getExpenses() async {
    final response = await _apiClient.get(
      ExpenseEndpoints.expenses,
    );

    if (response is! List) {
      throw Exception(
        'Invalid expenses response.',
      );
    }

    return response
        .map(
          (json) => ExpenseModel.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  // ============================================================
  // CREATE EXPENSE
  // ============================================================

  Future<ExpenseModel> createExpense(
      Map<String, dynamic> data,
      ) async {
    final response = await _apiClient.post(
      ExpenseEndpoints.createExpense,
      body: data,
    );

    if (response is! Map) {
      throw Exception(
        'Invalid create expense response.',
      );
    }

    return ExpenseModel.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // APPROVE EXPENSE
  // PUT /expenses/:id/status  Body: {"status": "approved"}
  // ============================================================

  Future<void> approveExpense(
      String expenseId,
      ) async {
    await _apiClient.put(
      ExpenseEndpoints.updateStatus(
        expenseId,
      ),
      body: {
        'status': 'approved',
      },
    );
  }

  // ============================================================
  // REJECT EXPENSE
  // PUT /expenses/:id/status  Body: {"status": "rejected"}
  // ============================================================

  Future<void> rejectExpense(
      String expenseId,
      ) async {
    await _apiClient.put(
      ExpenseEndpoints.updateStatus(
        expenseId,
      ),
      body: {
        'status': 'rejected',
      },
    );
  }

  // ============================================================
  // GET EMPLOYEE NAMES
  // Returns a map of employee _id -> name, built from GET /employees.
  // Used to show the employee's real name on expense cards/details
  // (the expenses API's employeeId object only has _id and
  // employeeCode, no name).
  // ============================================================

  Future<Map<String, String>> getEmployeeNames() async {
    final response = await _apiClient.get(
      ExpenseEndpoints.employees,
    );

    if (response is! List) {
      throw Exception('Invalid employees response.');
    }

    final map = <String, String>{};

    for (final item in response) {
      if (item is! Map) continue;

      final employee = Map<String, dynamic>.from(item);

      final id = employee['_id']?.toString();
      final name = employee['name']?.toString();

      if (id != null &&
          id.isNotEmpty &&
          name != null &&
          name.trim().isNotEmpty) {
        map[id] = name;
      }
    }

    return map;
  }
}