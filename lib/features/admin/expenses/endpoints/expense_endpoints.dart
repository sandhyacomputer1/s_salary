class ExpenseEndpoints {
  ExpenseEndpoints._();

  // ============================================================
  // GET /expenses
  // ============================================================

  static const String expenses = '/expenses';

  // ============================================================
  // POST /expenses
  // ============================================================

  static const String createExpense = '/expenses';

  // ============================================================
  // PUT /expenses/:id/status
  // Body: {"status": "approved" | "rejected"}
  // Used for BOTH approve and reject.
  // ============================================================

  static String updateStatus(String id) {
    return '/expenses/$id/status';
  }
}