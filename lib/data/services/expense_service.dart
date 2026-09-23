import '../../core/network/api_client.dart';

class ExpenseService {
  final ApiClient _apiClient = ApiClient();

  // ==========================================================
  // GET EMPLOYEE EXPENSES
  // GET /expenses/employee/:employeeId
  // ==========================================================

  Future<List<Map<String, dynamic>>> getEmployeeExpenses(
      String employeeId,
      ) async {
    final response = await _apiClient.get(
      '/expenses/employee/$employeeId',
    );

    if (response is! List) {
      throw Exception(
        'Invalid employee expenses response.',
      );
    }

    return response
        .map(
          (item) => Map<String, dynamic>.from(
        item,
      ),
    )
        .toList();
  }

  // ==========================================================
  // GET PENDING EXPENSE COUNT
  // ==========================================================

  Future<int> getPendingExpenseCount(
      String employeeId,
      ) async {
    final expenses =
    await getEmployeeExpenses(
      employeeId,
    );

    int count = 0;

    for (final expense in expenses) {
      final status =
          expense['status']
              ?.toString()
              .toLowerCase() ??
              '';

      if (status == 'pending') {
        count++;
      }
    }

    return count;
  }
}