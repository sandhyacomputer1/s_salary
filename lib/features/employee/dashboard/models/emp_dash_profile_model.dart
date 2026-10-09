class EmpDashCompanyModel {
  final String id;
  final String companyName;
  final String address;

  const EmpDashCompanyModel({
    required this.id,
    required this.companyName,
    required this.address,
  });

  factory EmpDashCompanyModel.fromJson(Map<String, dynamic> json) {
    return EmpDashCompanyModel(
      id: json['_id']?.toString() ?? '',
      companyName: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }
}

class EmpDashProfileModel {
  final String id;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final String designation;
  final String department;
  final String employmentType;
  final String workMode;
  final EmpDashCompanyModel? company;

  const EmpDashProfileModel({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.department,
    required this.employmentType,
    required this.workMode,
    required this.company,
  });

  /// Real response shape from GET /employees/me:
  /// { "employee": {...}, "user": {...}, "company": {...}, "settings": {...} }
  /// — confirmed via Postman. NOT a flat object.
  factory EmpDashProfileModel.fromJson(Map<String, dynamic> json) {
    final employeeJson = json['employee'];
    final userJson = json['user'];
    final companyJson = json['company'];

    final employee = employeeJson is Map
        ? Map<String, dynamic>.from(employeeJson)
        : <String, dynamic>{};

    final user = userJson is Map
        ? Map<String, dynamic>.from(userJson)
        : <String, dynamic>{};

    return EmpDashProfileModel(
      id: employee['_id']?.toString() ?? '',
      employeeCode: employee['employeeCode']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString() ?? '',
      designation: employee['designation']?.toString() ?? '',
      department: employee['department']?.toString() ?? '',
      employmentType: employee['employmentType']?.toString() ?? '',
      workMode: employee['workMode']?.toString() ?? '',
      company: companyJson is Map
          ? EmpDashCompanyModel.fromJson(
        Map<String, dynamic>.from(companyJson),
      )
          : null,
    );
  }

  String get displayName => name.trim().isEmpty ? 'Employee' : name;

  String get companyName {
    if (company == null || company!.companyName.trim().isEmpty) {
      return '—';
    }
    return company!.companyName;
  }
}