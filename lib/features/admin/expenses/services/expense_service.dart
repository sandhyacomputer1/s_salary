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
  // ============================================================

  Future<void> approveExpense(
      String expenseId,
      ) async {
    await _apiClient.put(
      ExpenseEndpoints.approveExpense(
        expenseId,
      ),
    );
  }
}