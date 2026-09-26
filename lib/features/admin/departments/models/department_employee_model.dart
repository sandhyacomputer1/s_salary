// // =================================================================
// // DEPARTMENT EMPLOYEE MODEL
// //
// // Represents an employee displayed inside a department.
// //
// // Based on the actual employee API response:
// //
// // {
// //   "employee": {...},
// //   "user": {...},
// //   "company": {...},
// //   "documents": [],
// //   "attendance": [],
// //   "leaves": [],
// //   "expenses": [],
// //   "salaryStructures": [],
// //   "payrolls": []
// // }
// //
// // For the Department module we only keep the employee/user fields
// // required for displaying and moving employees.
// // =================================================================
//
// class DepartmentEmployeeModel {
//   final String id;
//   final String userId;
//   final String employeeCode;
//
//   final String name;
//   final String email;
//   final String? phone;
//
//   final String? designation;
//   final String? department;
//
//   final String? companyId;
//   final String? branchId;
//
//   final String? workMode;
//   final String? employmentType;
//
//   final DateTime? dateOfJoining;
//
//   final bool portalAccess;
//   final String? status;
//   final bool isActive;
//
//   const DepartmentEmployeeModel({
//     required this.id,
//     required this.userId,
//     required this.employeeCode,
//     required this.name,
//     required this.email,
//     this.phone,
//     this.designation,
//     this.department,
//     this.companyId,
//     this.branchId,
//     this.workMode,
//     this.employmentType,
//     this.dateOfJoining,
//     this.portalAccess = false,
//     this.status,
//     this.isActive = true,
//   });
//
//   // ===============================================================
//   // FROM JSON
//   //
//   // This supports the actual API structure where employee and user
//   // are returned as separate objects.
//   //
//   // It also supports a direct employee object, which is useful if
//   // another Department endpoint returns employees directly.
//   // ===============================================================
//
//   factory DepartmentEmployeeModel.fromJson(
//       Map<String, dynamic> json,
//       ) {
//     final employee = json['employee'] is Map
//         ? Map<String, dynamic>.from(json['employee'])
//         : json;
//
//     final user = json['user'] is Map
//         ? Map<String, dynamic>.from(json['user'])
//         : <String, dynamic>{};
//
//     return DepartmentEmployeeModel(
//       id: (
//           employee['_id'] ??
//               employee['id'] ??
//               ''
//       ).toString(),
//
//       userId: (
//           employee['userId'] ??
//               user['_id'] ??
//               user['id'] ??
//               ''
//       ).toString(),
//
//       employeeCode: (
//           employee['employeeCode'] ??
//               ''
//       ).toString(),
//
//       name: (
//           user['name'] ??
//               employee['name'] ??
//               ''
//       ).toString(),
//
//       email: (
//           user['email'] ??
//               employee['email'] ??
//               ''
//       ).toString(),
//
//       phone: _nullableString(
//         user['phone'] ??
//             employee['phone'],
//       ),
//
//       designation: _nullableString(
//         employee['designation'],
//       ),
//
//       department: _nullableString(
//         employee['department'],
//       ),
//
//       companyId: _nullableString(
//         employee['companyId'] ??
//             user['companyId'],
//       ),
//
//       branchId: _nullableString(
//         employee['branchId'],
//       ),
//
//       workMode: _nullableString(
//         employee['workMode'],
//       ),
//
//       employmentType: _nullableString(
//         employee['employmentType'],
//       ),
//
//       dateOfJoining: DateTime.tryParse(
//         employee['dateOfJoining']?.toString() ?? '',
//       ),
//
//       portalAccess: employee['portalAccess'] == true,
//
//       status: _nullableString(
//         employee['status'],
//       ),
//
//       isActive: user.isEmpty
//           ? employee['status']?.toString().toLowerCase() == 'active'
//           : user['isActive'] == true,
//     );
//   }
//
//   // ===============================================================
//   // TO JSON
//   //
//   // Used when we need a simple employee representation.
//   // ===============================================================
//
//   Map<String, dynamic> toJson() {
//     return {
//       '_id': id,
//       'userId': userId,
//       'employeeCode': employeeCode,
//       'name': name,
//       'email': email,
//       if (phone != null) 'phone': phone,
//       if (designation != null) 'designation': designation,
//       if (department != null) 'department': department,
//       if (companyId != null) 'companyId': companyId,
//       if (branchId != null) 'branchId': branchId,
//       if (workMode != null) 'workMode': workMode,
//       if (employmentType != null) 'employmentType': employmentType,
//       if (dateOfJoining != null)
//         'dateOfJoining': dateOfJoining!.toIso8601String(),
//       'portalAccess': portalAccess,
//       if (status != null) 'status': status,
//       'isActive': isActive,
//     };
//   }
//
//   // ===============================================================
//   // COPY WITH
//   // ===============================================================
//
//   DepartmentEmployeeModel copyWith({
//     String? id,
//     String? userId,
//     String? employeeCode,
//     String? name,
//     String? email,
//     String? phone,
//     String? designation,
//     String? department,
//     String? companyId,
//     String? branchId,
//     String? workMode,
//     String? employmentType,
//     DateTime? dateOfJoining,
//     bool? portalAccess,
//     String? status,
//     bool? isActive,
//   }) {
//     return DepartmentEmployeeModel(
//       id: id ?? this.id,
//       userId: userId ?? this.userId,
//       employeeCode: employeeCode ?? this.employeeCode,
//       name: name ?? this.name,
//       email: email ?? this.email,
//       phone: phone ?? this.phone,
//       designation: designation ?? this.designation,
//       department: department ?? this.department,
//       companyId: companyId ?? this.companyId,
//       branchId: branchId ?? this.branchId,
//       workMode: workMode ?? this.workMode,
//       employmentType: employmentType ?? this.employmentType,
//       dateOfJoining: dateOfJoining ?? this.dateOfJoining,
//       portalAccess: portalAccess ?? this.portalAccess,
//       status: status ?? this.status,
//       isActive: isActive ?? this.isActive,
//     );
//   }
//
//   // ===============================================================
//   // HELPERS
//   // ===============================================================
//
//   static String? _nullableString(dynamic value) {
//     if (value == null) return null;
//
//     final text = value.toString().trim();
//
//     if (text.isEmpty || text == 'null') {
//       return null;
//     }
//
//     return text;
//   }
// }


// =================================================================
// DEPARTMENT EMPLOYEE MODEL
// =================================================================

class DepartmentEmployeeModel {
  final String id;
  final String userId;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final String designation;
  final String department;
  final String workMode;
  final String employmentType;
  final String status;

  const DepartmentEmployeeModel({
    required this.id,
    required this.userId,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.designation,
    required this.department,
    required this.workMode,
    required this.employmentType,
    required this.status,
  });

  factory DepartmentEmployeeModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final employee = json['employee'] is Map
        ? Map<String, dynamic>.from(json['employee'])
        : json;

    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : <String, dynamic>{};

    return DepartmentEmployeeModel(
      id: (employee['_id'] ?? '').toString(),

      userId: (employee['userId'] ?? user['_id'] ?? '').toString(),

      employeeCode:
      (employee['employeeCode'] ?? '').toString(),

      name:
      (user['name'] ?? employee['name'] ?? '').toString(),

      email:
      (user['email'] ?? '').toString(),

      phone:
      (user['phone'] ?? '').toString(),

      designation:
      (employee['designation'] ?? '').toString(),

      department:
      (employee['department'] ?? '').toString(),

      workMode:
      (employee['workMode'] ?? '').toString(),

      employmentType:
      (employee['employmentType'] ?? '').toString(),

      status:
      (employee['status'] ?? '').toString(),
    );
  }
}