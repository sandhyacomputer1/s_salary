class Employee {
  final String id;
  final String name;
  final String email;
  final String employeeCode;
  final String designation;
  final String department;
  final String employmentType;
  final String workMode;
  final String status;

  // ============================================================
  // NEW FIELD
  // ============================================================

  final String phone;

  // ============================================================
  // OPTIONAL FIELDS
  // ============================================================

  final DateTime? dateOfJoining;
  final double? monthlySalary;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.employmentType,
    required this.workMode,
    required this.status,
    required this.phone,
    this.dateOfJoining,
    this.monthlySalary,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory Employee.fromJson(
      Map<String, dynamic> json,
      ) {
    return Employee(
      id:
      json['_id']?.toString() ?? '',

      name:
      json['name']?.toString() ?? '',

      email:
      json['email']?.toString() ?? '',

      employeeCode:
      json['employeeCode']
          ?.toString() ??
          '',

      designation:
      json['designation']
          ?.toString() ??
          '',

      department:
      json['department']
          ?.toString() ??
          '',

      employmentType:
      json['employmentType']
          ?.toString() ??
          '',

      workMode:
      json['workMode']
          ?.toString() ??
          '',

      status:
      json['status']?.toString() ??
          '',

      // --------------------------------------------------------
      // PHONE
      // --------------------------------------------------------

      phone:
      json['phone']?.toString() ??
          '',

      // --------------------------------------------------------
      // DATE OF JOINING
      // --------------------------------------------------------

      dateOfJoining:
      _parseDate(
        json['dateOfJoining'],
      ),

      // --------------------------------------------------------
      // MONTHLY SALARY
      // --------------------------------------------------------

      monthlySalary:
      _parseSalary(
        json['monthlySalary'],
      ),
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Employee copyWith({
    String? phone,
  }) {
    return Employee(
      id: id,
      name: name,
      email: email,
      employeeCode:
      employeeCode,
      designation:
      designation,
      department:
      department,
      employmentType:
      employmentType,
      workMode:
      workMode,
      status:
      status,
      phone:
      phone ?? this.phone,
      dateOfJoining:
      dateOfJoining,
      monthlySalary:
      monthlySalary,
    );
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  static DateTime? _parseDate(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // PARSE SALARY
  // ============================================================

  static double? _parseSalary(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }
}