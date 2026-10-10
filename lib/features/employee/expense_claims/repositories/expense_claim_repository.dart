import '../models/expense_claim_model.dart';
import '../models/expense_claim_summary_model.dart';
import '../services/expense_claim_service.dart';

// ⚠️ Fix this import to match where SecureStorage lives in your project.
import '../../../../core/storage/secure_storage.dart';

/// Result of loading the history: claims plus totals derived from them.
class ExpenseClaimsResult {
  final List<ExpenseClaimModel> claims;
  final ExpenseClaimSummaryModel summary;

  const ExpenseClaimsResult({required this.claims, required this.summary});
}

class ExpenseClaimRepository {
  final ExpenseClaimService _service;

  ExpenseClaimRepository({ExpenseClaimService? service})
      : _service = service ?? ExpenseClaimService();

  /// Loads the logged-in employee's claims (newest expense date first)
  /// and the summary derived from them.
  Future<ExpenseClaimsResult> getMyClaims() async {
    try {
      final employeeId = await _requireEmployeeId();
      final claims = await _service.fetchEmployeeClaims(employeeId);

      // Presentation order only: newest expense date first, missing dates last.
      claims.sort((a, b) {
        final da = a.expenseDate;
        final db = b.expenseDate;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      return ExpenseClaimsResult(
        claims: claims,
        summary: ExpenseClaimSummaryModel.fromClaims(claims),
      );
    } catch (e) {
      throw Exception(_cleanMessage(e));
    }
  }

  /// Returns normally only if the server accepted the claim (2xx).
  /// Throws an Exception with the server's message otherwise
  /// (e.g. 400 invalid amount, 409 duplicate pending claim).
  Future<void> submitClaim({
    required String category,
    required double amount,
    required DateTime expenseDate,
    required String description,
    String? billUrl,
  }) async {
    try {
      await _service.submitClaim(
        category: category,
        amount: amount,
        expenseDate: expenseDate,
        description: description,
        billUrl: billUrl,
      );
    } catch (e) {
      throw Exception(_cleanMessage(e));
    }
  }

  Future<String> _requireEmployeeId() async {
    final id = await SecureStorage.getEmployeeId();
    if (id == null || id.isEmpty) {
      throw Exception('Employee profile not found. Please login again.');
    }
    return id;
  }

  String _cleanMessage(Object e) {
    return e.toString().replaceFirst('Exception: ', '').trim();
  }
}