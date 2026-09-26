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
  // PUT /expenses/:id/approve
  // ============================================================

  static String approveExpense(String id) {
    return '/expenses/$id/approve';
  }
}