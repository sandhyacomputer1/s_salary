/// One filled row of the Bulk Import grid (sent to POST /employees/bulk-import).
class AdminBulkImportEntry {
  final String name;
  final String email;
  final String phone;
  final String department;
  final String workMode; // in_house | field
  final String employmentType; // full_time | part_time | contract | intern

  const AdminBulkImportEntry({
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.workMode,
    required this.employmentType,
  });

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'email': email.trim(),
    if (phone.trim().isNotEmpty) 'phone': phone.trim(),
    'department': department,
    'workMode': workMode,
    'employmentType': employmentType,
  };
}

/// An employee that was created by the import.
class AdminBulkImportedItem {
  final String employeeCode;
  final String name;
  final String email;
  final String department;

  /// Shown ONCE by the server.
  final String tempPassword;

  const AdminBulkImportedItem({
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.department,
    required this.tempPassword,
  });

  factory AdminBulkImportedItem.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => v == null ? '' : v.toString();
    return AdminBulkImportedItem(
      employeeCode: s(j['employeeCode']),
      name: s(j['name']),
      email: s(j['email']),
      department: s(j['department']),
      tempPassword: s(j['tempPassword']),
    );
  }
}

/// A row the server refused (e.g. "Email already exists in system").
class AdminBulkImportError {
  final String row;
  final String email;
  final String error;

  const AdminBulkImportError({
    required this.row,
    required this.email,
    required this.error,
  });

  factory AdminBulkImportError.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => v == null ? '' : v.toString();
    return AdminBulkImportError(
      row: s(j['row']),
      email: s(j['email']),
      error: s(j['error']),
    );
  }
}

class AdminBulkImportResult {
  final int importedCount;
  final List<AdminBulkImportedItem> imported;
  final List<AdminBulkImportError> errors;

  const AdminBulkImportResult({
    required this.importedCount,
    required this.imported,
    required this.errors,
  });

  factory AdminBulkImportResult.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{};

    List<T> parse<T>(dynamic v, T Function(Map<String, dynamic>) f) {
      if (v is! List) return <T>[];
      return v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
    }

    final imported = parse(map['imported'], AdminBulkImportedItem.fromJson);
    final errors = parse(map['errors'], AdminBulkImportError.fromJson);
    final count = int.tryParse('${map['importedCount']}') ?? imported.length;

    return AdminBulkImportResult(
      importedCount: count,
      imported: imported,
      errors: errors,
    );
  }
}