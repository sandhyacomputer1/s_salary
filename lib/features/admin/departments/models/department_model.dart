// ============================================================================
// DEPARTMENT MODEL
//
// Represents a company department returned by the Department API.
//
// API response example:
//
// {
//   "_id": "6aa24726c5cb298149f7091b",
//   "companyId": "6a9e617344820148a2086515",
//   "name": "Accounts",
//   "code": "ACC",
//   "description": "Finance, Billing & Accounting",
//   "managerId": null,
//   "createdAt": "2026-09-10T05:59:02.241Z",
//   "updatedAt": "2026-09-10T05:59:02.241Z",
//   "employeeCount": 0
// }
// ============================================================================

class DepartmentModel {
  final String id;
  final String companyId;
  final String name;
  final String code;
  final String description;
  final String? managerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int employeeCount;

  const DepartmentModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.description,
    this.managerId,
    this.createdAt,
    this.updatedAt,
    this.employeeCount = 0,
  });

  // ==========================================================================
  // FROM JSON
  // ==========================================================================

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),

      companyId: (json['companyId'] ?? '').toString(),

      name: (json['name'] ?? '').toString(),

      code: (json['code'] ?? '').toString(),

      description: (json['description'] ?? '').toString(),

      managerId: json['managerId']?.toString(),

      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ),

      updatedAt: DateTime.tryParse(
        json['updatedAt']?.toString() ?? '',
      ),

      employeeCount: _toInt(
        json['employeeCount'],
      ),
    );
  }

  // ==========================================================================
  // TO JSON
  //
  // Used when creating/updating a department.
  //
  // We do NOT send:
  // - _id
  // - companyId
  // - createdAt
  // - updatedAt
  // - employeeCount
  // - __v
  //
  // Those are backend/database controlled fields.
  // ==========================================================================

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'description': description,
    };
  }

  // ==========================================================================
  // COPY WITH
  //
  // Useful when updating a department locally after API response.
  // ==========================================================================

  DepartmentModel copyWith({
    String? id,
    String? companyId,
    String? name,
    String? code,
    String? description,
    String? managerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? employeeCount,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      employeeCount: employeeCount ?? this.employeeCount,
    );
  }

  // ==========================================================================
  // INTEGER PARSER
  // ==========================================================================

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  @override
  String toString() {
    return 'DepartmentModel('
        'id: $id, '
        'companyId: $companyId, '
        'name: $name, '
        'code: $code, '
        'description: $description, '
        'managerId: $managerId, '
        'employeeCount: $employeeCount'
        ')';
  }
}