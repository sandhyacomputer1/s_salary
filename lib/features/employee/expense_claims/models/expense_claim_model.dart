/// Status values returned by the S Salary API.
enum ExpenseClaimStatus {
  pending,
  approved,
  rejected,
  reimbursed,
  cancelled,
  unknown;

  static ExpenseClaimStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return ExpenseClaimStatus.pending;
      case 'approved':
        return ExpenseClaimStatus.approved;
      case 'rejected':
        return ExpenseClaimStatus.rejected;
      case 'reimbursed':
        return ExpenseClaimStatus.reimbursed;
      case 'cancelled':
        return ExpenseClaimStatus.cancelled;
      default:
        return ExpenseClaimStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case ExpenseClaimStatus.pending:
        return 'Pending';
      case ExpenseClaimStatus.approved:
        return 'Approved';
      case ExpenseClaimStatus.rejected:
        return 'Rejected';
      case ExpenseClaimStatus.reimbursed:
        return 'Reimbursed';
      case ExpenseClaimStatus.cancelled:
        return 'Cancelled';
      case ExpenseClaimStatus.unknown:
        return 'Unknown';
    }
  }
}

class ExpenseClaimModel {
  final String id;
  final String category;
  final double amount;

  /// Server sends midnight UTC (e.g. 2026-10-06T00:00:00.000Z).
  /// Display using UTC parts to avoid a day shift.
  final DateTime? expenseDate;

  final String? description;

  /// Null when the server sends "" or nothing.
  final String? billUrl;

  final ExpenseClaimStatus status;
  final String? rawStatus;

  /// When the claim was submitted (UTC instant; show with .toLocal()).
  final DateTime? submittedAt;

  /// When the claim was last acted on (approved / rejected / reimbursed).
  final DateTime? actionedAt;

  const ExpenseClaimModel({
    required this.id,
    required this.category,
    required this.amount,
    this.expenseDate,
    this.description,
    this.billUrl,
    required this.status,
    this.rawStatus,
    this.submittedAt,
    this.actionedAt,
  });

  factory ExpenseClaimModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString();
    return ExpenseClaimModel(
      id: (json['_id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      amount: _toDouble(json['amount']),
      expenseDate: _toDate(json['expenseDate']),
      description: _toNullableString(json['description']),
      billUrl: _toNullableString(json['billUrl']),
      status: ExpenseClaimStatus.fromString(rawStatus),
      rawStatus: rawStatus,
      submittedAt: _toDate(json['submittedAt']),
      actionedAt: _toDate(json['actionedAt']),
    );
  }

  /// True when [billUrl] is a base64 data URI rather than a web link.
  bool get hasInlineBill => billUrl?.startsWith('data:') ?? false;

  /// True only for a real http(s) link.
  bool get hasBillLink {
    final u = billUrl;
    if (u == null) return false;
    final uri = Uri.tryParse(u);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static String? _toNullableString(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}