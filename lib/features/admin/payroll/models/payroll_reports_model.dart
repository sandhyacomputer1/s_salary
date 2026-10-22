// lib/features/admin/payroll/models/payroll_reports_model.dart

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String _text(dynamic v) => v?.toString().trim() ?? '';

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

double? _firstNumber(List<Map<String, dynamic>> sources, List<String> keys) {
  for (final source in sources) {
    for (final key in keys) {
      final value = _toDouble(source[key]);
      if (value != null) return value;
    }
  }
  return null;
}

// =================================================================
// PT COMPLIANCE REPORT
// =================================================================

class PtReportRow {
  final String name;
  final String code;
  final double gross;
  final double pt;

  const PtReportRow({
    required this.name,
    required this.code,
    required this.gross,
    required this.pt,
  });

  factory PtReportRow.fromJson(Map<String, dynamic> json) {
    final emp = _asMap(json['employeeId']);
    final user = _asMap(emp['userId']);

    return PtReportRow(
      name: _text(user['name'] ?? emp['name']),
      code: _text(emp['employeeCode']),
      gross: _toDouble(json['grossSalary']) ?? 0,
      pt: _toDouble(json['ptDeduction']) ?? 0,
    );
  }
}

class PtReport {
  final List<PtReportRow> rows;
  final double totalCollected;

  const PtReport({required this.rows, required this.totalCollected});

  factory PtReport.fromResponse(dynamic body) {
    if (body is! Map) return const PtReport(rows: [], totalCollected: 0);
    final map = Map<String, dynamic>.from(body);
    final raw = map['records'] ?? map['employees'] ?? map['data'];

    final rows = (raw is List) ? raw
        .whereType<Map>()
        .map((e) => PtReportRow.fromJson(Map<String, dynamic>.from(e)))
        .toList() : <PtReportRow>[];

    return PtReport(
      rows: rows,
      totalCollected: _firstNumber([map], ['totalPT', 'total']) ?? 0,
    );
  }
}

// =================================================================
// PF ACCUMULATION & REFUND HISTORY
// =================================================================

class PfBalance {
  final String employeeId;
  final String name;
  final String code;
  final String status;
  final double accumulated;
  final double refunded;
  final double pending;

  const PfBalance({
    required this.employeeId,
    required this.name,
    required this.code,
    required this.status,
    required this.accumulated,
    required this.refunded,
    required this.pending,
  });

  bool get isActive => status.toLowerCase() == 'active' || status.toLowerCase() == 'accumulated';
  bool get canRefund => pending > 0 && employeeId.isNotEmpty;

  factory PfBalance.fromJson(Map<String, dynamic> json) {
    return PfBalance(
      employeeId: _text(json['employeeId']),
      name: _text(json['employeeName']),
      code: _text(json['employeeCode']),
      status: _text(json['employmentStatus'] ?? 'active'),
      accumulated: _toDouble(json['totalAccumulated']) ?? 0,
      refunded: _toDouble(json['totalRefunded']) ?? 0,
      pending: _toDouble(json['pendingBalance']) ?? 0,
    );
  }
}

class PfHistoryRecord {
  final String name;
  final String code;
  final int month;
  final int year;
  final double baseSalary;
  final double pfAmount;
  final String status;

  const PfHistoryRecord({
    required this.name,
    required this.code,
    required this.month,
    required this.year,
    required this.baseSalary,
    required this.pfAmount,
    required this.status,
  });

  factory PfHistoryRecord.fromJson(Map<String, dynamic> json) {
    final emp = _asMap(json['employeeId']);
    final user = _asMap(emp['userId']);

    return PfHistoryRecord(
      name: _text(user['name'] ?? emp['name']),
      code: _text(emp['employeeCode']),
      month: int.tryParse(json['month'].toString()) ?? 0,
      year: int.tryParse(json['year'].toString()) ?? 0,
      baseSalary: _toDouble(json['baseSalary']) ?? 0,
      pfAmount: _toDouble(json['pfAmount']) ?? 0,
      status: _text(json['status'] ?? 'accumulated'),
    );
  }
}

class PfReport {
  final List<PfBalance> balances;
  final List<PfHistoryRecord> history;
  final double totalAccumulated;
  final double totalPending;
  final double totalRefunded;

  const PfReport({
    required this.balances,
    required this.history,
    required this.totalAccumulated,
    required this.totalPending,
    required this.totalRefunded,
  });

  factory PfReport.fromResponse(dynamic body) {
    if (body is! Map) return _empty();
    final map = Map<String, dynamic>.from(body);

    // Section 1: Summaries
    final rawSummaries = map['employeeSummaries'] as List?;
    final balances = rawSummaries != null
        ? rawSummaries.whereType<Map>().map((e) => PfBalance.fromJson(Map<String, dynamic>.from(e))).toList()
        : <PfBalance>[];

    // Section 2: History
    final rawRecords = map['records'] as List?;
    final history = rawRecords != null
        ? rawRecords.whereType<Map>().map((e) => PfHistoryRecord.fromJson(Map<String, dynamic>.from(e))).toList()
        : <PfHistoryRecord>[];

    return PfReport(
      balances: balances,
      history: history,
      totalAccumulated: _toDouble(map['totalPFAccumulated']) ?? 0,
      totalPending: _toDouble(map['totalPendingRefund']) ?? 0,
      totalRefunded: _toDouble(map['totalRefunded']) ?? 0,
    );
  }

  static PfReport _empty() => const PfReport(
    balances: [], history: [], totalAccumulated: 0, totalPending: 0, totalRefunded: 0,
  );
}