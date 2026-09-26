class ExpenseEmployeeModel {
  final String id;
  final String employeeCode;

  const ExpenseEmployeeModel({
    required this.id,
    required this.employeeCode,
  });

  factory ExpenseEmployeeModel.fromJson(Map<String, dynamic> json) {
    return ExpenseEmployeeModel(
      id: json['_id']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
    );
  }
}

class ExpenseModel {
  final String id;
  final ExpenseEmployeeModel? employee;
  final String companyId;
  final String category;
  final double amount;
  final String description;
  final String billUrl;
  final DateTime? expenseDate;
  final String status;
  final DateTime? submittedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? actionedAt;
  final String approvedBy;

  const ExpenseModel({
    required this.id,
    required this.employee,
    required this.companyId,
    required this.category,
    required this.amount,
    required this.description,
    required this.billUrl,
    required this.expenseDate,
    required this.status,
    required this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.actionedAt,
    required this.approvedBy,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final employeeJson = json['employeeId'];

    return ExpenseModel(
      id: json['_id']?.toString() ?? '',

      employee: employeeJson is Map
          ? ExpenseEmployeeModel.fromJson(
        Map<String, dynamic>.from(employeeJson),
      )
          : null,

      companyId: json['companyId']?.toString() ?? '',

      category: json['category']?.toString() ?? '',

      amount: _toDouble(json['amount']),

      description: json['description']?.toString() ?? '',

      billUrl: json['billUrl']?.toString() ?? '',

      expenseDate: _parseDate(json['expenseDate']),

      status: json['status']?.toString().toLowerCase() ?? 'pending',

      submittedAt: _parseDate(json['submittedAt']),

      createdAt: _parseDate(json['createdAt']),

      updatedAt: _parseDate(json['updatedAt']),

      actionedAt: _parseDate(json['actionedAt']),

      approvedBy: json['approvedBy']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());

    return parsed;
  }

  String get employeeCode {
    if (employee == null) {
      return '—';
    }

    if (employee!.employeeCode.trim().isEmpty) {
      return '—';
    }

    return employee!.employeeCode;
  }

  bool get isPending {
    return status == 'pending';
  }

  bool get isApproved {
    return status == 'approved';
  }

  bool get isRejected {
    return status == 'rejected';
  }
}