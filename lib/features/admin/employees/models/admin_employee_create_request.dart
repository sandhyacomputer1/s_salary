/// Body for POST /employees (Add Employee dialog).
class AdminEmployeeCreateRequest {
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfJoining;
  final String department;
  final String employmentType;
  final double? baseSalary;
  final String workMode;

  /// 'none' | 'hr' | 'accountant' | 'manager'
  final String adminRole;

  final DateTime? dob;
  final String gender;
  final String address;
  final String emergencyContact;
  final String accountNumber;
  final String ifsc;
  final String bankName;

  const AdminEmployeeCreateRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfJoining,
    required this.department,
    required this.employmentType,
    required this.workMode,
    this.baseSalary,
    this.adminRole = 'none',
    this.dob,
    this.gender = 'male',
    this.address = '',
    this.emergencyContact = '',
    this.accountNumber = '',
    this.ifsc = '',
    this.bankName = '',
  });

  static String apiDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Map<String, dynamic> toJson() {
    final personal = <String, dynamic>{
      if (dob != null) 'dob': apiDate(dob!),
      if (gender.isNotEmpty) 'gender': gender.toLowerCase(),
      if (address.trim().isNotEmpty) 'address': address.trim(),
      if (emergencyContact.trim().isNotEmpty)
        'emergencyContact': emergencyContact.trim(),
    };

    final bank = <String, dynamic>{
      if (accountNumber.trim().isNotEmpty)
        'accountNumber': accountNumber.trim(),
      if (ifsc.trim().isNotEmpty) 'ifsc': ifsc.trim().toUpperCase(),
      if (bankName.trim().isNotEmpty) 'bankName': bankName.trim(),
    };

    return {
      'name': name.trim(),
      'email': email.trim(),
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
      'department': department,
      'dateOfJoining': apiDate(dateOfJoining),
      'employmentType': employmentType,
      'workMode': workMode,
      'portalAccess': true,
      if (adminRole != 'none') 'subRole': adminRole,
      if (personal.isNotEmpty) 'personalDetails': personal,
      if (bank.isNotEmpty) 'bankDetails': bank,
    };
  }
}

/// Result of POST /employees.
class AdminEmployeeCreateResult {
  final String employeeId;
  final String employeeCode;

  /// Shown ONCE by the server. Must be shown to the admin right away.
  final String? tempPassword;

  /// false if the employee was created but the base salary could not be saved.
  final bool salarySaved;

  const AdminEmployeeCreateResult({
    required this.employeeId,
    required this.employeeCode,
    required this.tempPassword,
    required this.salarySaved,
  });
}