import 'expense_claim_model.dart';

/// Totals calculated on the device from the fetched claims.
/// The API has no summary endpoint, so these are NOT server-provided totals.
class ExpenseClaimSummaryModel {
  final int totalCount;
  final double totalAmount;

  final int pendingCount;
  final double pendingAmount;

  final int approvedCount;
  final double approvedAmount;

  final int rejectedCount;
  final double rejectedAmount;

  final int reimbursedCount;
  final double reimbursedAmount;

  const ExpenseClaimSummaryModel({
    this.totalCount = 0,
    this.totalAmount = 0,
    this.pendingCount = 0,
    this.pendingAmount = 0,
    this.approvedCount = 0,
    this.approvedAmount = 0,
    this.rejectedCount = 0,
    this.rejectedAmount = 0,
    this.reimbursedCount = 0,
    this.reimbursedAmount = 0,
  });

  /// Always true for this model; lets the UI label the figures honestly.
  bool get isDerived => true;

  factory ExpenseClaimSummaryModel.fromClaims(List<ExpenseClaimModel> claims) {
    int pendingC = 0, approvedC = 0, rejectedC = 0, reimbursedC = 0;
    double pendingA = 0, approvedA = 0, rejectedA = 0, reimbursedA = 0;

    for (final c in claims) {
      switch (c.status) {
        case ExpenseClaimStatus.pending:
          pendingC++;
          pendingA += c.amount;
          break;
        case ExpenseClaimStatus.approved:
          approvedC++;
          approvedA += c.amount;
          break;
        case ExpenseClaimStatus.rejected:
          rejectedC++;
          rejectedA += c.amount;
          break;
        case ExpenseClaimStatus.reimbursed:
          reimbursedC++;
          reimbursedA += c.amount;
          break;
        case ExpenseClaimStatus.cancelled:
        case ExpenseClaimStatus.unknown:
          break; // counted in total only
      }
    }

    return ExpenseClaimSummaryModel(
      totalCount: claims.length,
      totalAmount: claims.fold<double>(0, (sum, c) => sum + c.amount),
      pendingCount: pendingC,
      pendingAmount: pendingA,
      approvedCount: approvedC,
      approvedAmount: approvedA,
      rejectedCount: rejectedC,
      rejectedAmount: rejectedA,
      reimbursedCount: reimbursedC,
      reimbursedAmount: reimbursedA,
    );
  }
}