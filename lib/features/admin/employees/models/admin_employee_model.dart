/// Employee row for the Admin Employee Directory.
class AdminEmployeeModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String employeeCode;
  final String designation;
  final String department;
  final String workMode; // in_house | field
  final String employmentType; // full_time | part_time | contract | intern
  final String status; // active | on_leave | terminated
  final bool portalAccess;
  final DateTime? dateOfJoining;

  // personal details
  final DateTime? dob;
  final String gender;
  final String address;
  final String emergencyContact;
  final String bloodGroup;
  final String maritalStatus;

  // bank details
  final String accountNumber;
  final String ifsc;
  final String bankName;
  final String upiId;

  /// Comes from the salary-structure API, not from /employees.
  final double? baseSalary;

  const AdminEmployeeModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.workMode,
    required this.employmentType,
    required this.status,
    required this.portalAccess,
    this.dateOfJoining,
    this.dob,
    this.gender = '',
    this.address = '',
    this.emergencyContact = '',
    this.bloodGroup = '',
    this.maritalStatus = '',
    this.accountNumber = '',
    this.ifsc = '',
    this.bankName = '',
    this.upiId = '',
    this.baseSalary,
  });

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static String _s(dynamic v) => v == null ? '' : v.toString();

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory AdminEmployeeModel.fromJson(Map<String, dynamic> json) {
    final user = _map(json['userId']);
    final personal = _map(json['personalDetails']);
    final bank = _map(json['bankDetails']);

    final name = _s(json['name']).isNotEmpty ? _s(json['name']) : _s(user['name']);
    final email =
    _s(json['email']).isNotEmpty ? _s(json['email']) : _s(user['email']);
    final phone =
    _s(json['phone']).isNotEmpty ? _s(json['phone']) : _s(user['phone']);

    return AdminEmployeeModel(
      id: _s(json['_id']),
      userId: json['userId'] is Map ? _s(user['_id']) : _s(json['userId']),
      name: name,
      email: email,
      phone: phone,
      employeeCode: _s(json['employeeCode']),
      designation: _s(json['designation']),
      department: _s(json['department']),
      workMode: _s(json['workMode']).isEmpty ? 'in_house' : _s(json['workMode']),
      employmentType: _s(json['employmentType']),
      status: _s(json['status']).isEmpty ? 'active' : _s(json['status']),
      portalAccess: json['portalAccess'] == true,
      dateOfJoining: _date(json['dateOfJoining']),
      dob: _date(personal['dob']),
      gender: _s(personal['gender']),
      address: _s(personal['address']),
      emergencyContact: _s(personal['emergencyContact']),
      bloodGroup: _s(personal['bloodGroup']),
      maritalStatus: _s(personal['maritalStatus']),
      accountNumber: _s(bank['accountNumber']),
      ifsc: _s(bank['ifsc']),
      bankName: _s(bank['bankName']),
      upiId: _s(bank['upiId']),
    );
  }

  AdminEmployeeModel copyWith({double? baseSalary}) {
    return AdminEmployeeModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      phone: phone,
      employeeCode: employeeCode,
      designation: designation,
      department: department,
      workMode: workMode,
      employmentType: employmentType,
      status: status,
      portalAccess: portalAccess,
      dateOfJoining: dateOfJoining,
      dob: dob,
      gender: gender,
      address: address,
      emergencyContact: emergencyContact,
      bloodGroup: bloodGroup,
      maritalStatus: maritalStatus,
      accountNumber: accountNumber,
      ifsc: ifsc,
      bankName: bankName,
      upiId: upiId,
      baseSalary: baseSalary ?? this.baseSalary,
    );
  }

  // ---------- display helpers ----------

  String get initials {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool get isFieldEmployee => workMode == 'field';
  String get workModeLabel => isFieldEmployee ? 'Field' : 'In-House';

  String get employmentTypeLabel {
    switch (employmentType) {
      case 'full_time':
        return 'Full Time';
      case 'part_time':
        return 'Part Time';
      case 'contract':
        return 'Contract';
      case 'intern':
        return 'Intern';
      default:
        return '—';
    }
  }

  String get joiningLabel => adminEmpFormatDate(dateOfJoining);
  String get salaryLabel =>
      baseSalary == null ? '—' : adminEmpRupees(baseSalary!);
}

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "30 Oct 2026". Uses the UTC date so date-only values never shift a day.
String adminEmpFormatDate(DateTime? d) {
  if (d == null) return '—';
  final u = d.toUtc();
  return '${u.day} ${_kMonths[u.month - 1]} ${u.year}';
}

/// "dd-mm-yyyy" used inside form fields.
String adminEmpFieldDate(DateTime? d) {
  if (d == null) return 'dd-mm-yyyy';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}-${two(d.month)}-${d.year}';
}

/// "₹1,22,000" Indian digit grouping.
String adminEmpRupees(double value) {
  final s = value.round().toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}