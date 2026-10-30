import '../../../../core/network/api_client.dart'; // TODO: fix path if different
import '../endpoints/admin_employee_endpoints.dart';
import '../models/admin_bulk_import_models.dart';
import '../models/admin_employee_create_request.dart';
import '../models/admin_employee_model.dart';
import '../models/admin_salary_structure_model.dart';

class AdminEmployeeService {
  final ApiClient _api = ApiClient();

  // ------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------

  /// Accepts a raw list OR a map wrapping the list.
  List<dynamic> _asList(dynamic res, [List<String> keys = const []]) {
    if (res is List) return res;
    if (res is Map) {
      for (final k in [...keys, 'employees', 'data', 'items', 'structures']) {
        final v = res[k];
        if (v is List) return v;
      }
    }
    return const [];
  }

  List<AdminEmployeeModel> _parseEmployees(dynamic res) {
    return _asList(res)
        .whereType<Map>()
        .map((e) => AdminEmployeeModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ------------------------------------------------------------
  // LIST
  // ------------------------------------------------------------

  Future<List<AdminEmployeeModel>> getActiveEmployees() async {
    final res = await _api.get(AdminEmployeeEndpoints.list);
    return _parseEmployees(res).where((e) => e.status != 'terminated').toList();
  }

  Future<List<AdminEmployeeModel>> getArchivedEmployees() async {
    final res = await _api.get(AdminEmployeeEndpoints.archived);
    return _parseEmployees(res).where((e) => e.status == 'terminated').toList();
  }

  // ------------------------------------------------------------
  // SALARY MAP  { employeeId : baseSalary }
  // ------------------------------------------------------------

  Future<Map<String, double>> getSalaryMap(String companyId) async {
    try {
      final res = await _api.get(AdminEmployeeEndpoints.salaryByCompany(companyId));
      final map = <String, double>{};
      for (final item in _asList(res)) {
        if (item is! Map) continue;
        final emp = item['employeeId'];
        final id = emp is Map ? emp['_id']?.toString() : emp?.toString();
        final base = double.tryParse('${item['baseSalary']}');
        if (id != null && base != null) map[id] = base;
      }
      return map;
    } catch (_) {
      // Salary column is optional. Never block the list because of it.
      return {};
    }
  }

  // ------------------------------------------------------------
  // DEPARTMENTS
  // ------------------------------------------------------------

  static const List<String> fallbackDepartments = [
    'Engineering', 'HR', 'Accounts', 'Management', 'Sales', 'Operations',
  ];

  Future<List<String>> getDepartments(String companyId) async {
    try {
      final res = await _api.get(AdminEmployeeEndpoints.departments(companyId));
      final names = <String>[];
      for (final d in _asList(res, ['departments'])) {
        final n = d is Map ? d['name']?.toString() : d?.toString();
        if (n != null && n.trim().isNotEmpty && !names.contains(n)) names.add(n);
      }
      return names.isEmpty ? fallbackDepartments : names;
    } catch (_) {
      return fallbackDepartments;
    }
  }

  // ------------------------------------------------------------
  // CREATE
  // ------------------------------------------------------------

  Future<AdminEmployeeCreateResult> createEmployee(
      AdminEmployeeCreateRequest request,
      ) async {
    final res = await _api.post(AdminEmployeeEndpoints.create, body: request.toJson());

    final map = res is Map ? Map<String, dynamic>.from(res) : <String, dynamic>{};
    final emp = map['employee'] is Map
        ? Map<String, dynamic>.from(map['employee'])
        : <String, dynamic>{};

    final id = emp['_id']?.toString() ?? '';
    var salarySaved = true;

    final base = request.baseSalary;
    if (base != null && base > 0 && id.isNotEmpty) {
      try {
        await saveSalaryStructure(id, base, request.dateOfJoining);
      } catch (_) {
        salarySaved = false;
      }
    }

    return AdminEmployeeCreateResult(
      employeeId: id,
      employeeCode: emp['employeeCode']?.toString() ?? '',
      tempPassword: map['tempPassword']?.toString(),
      salarySaved: salarySaved,
    );
  }

  Future<void> saveSalaryStructure(
      String employeeId,
      double baseSalary,
      DateTime effectiveFrom,
      ) async {
    await _api.post(
      AdminEmployeeEndpoints.salaryStructure(employeeId),
      body: {
        'baseSalary': baseSalary,
        'effectiveFrom': AdminEmployeeCreateRequest.apiDate(effectiveFrom),
        'allowances': [],
      },
    );
  }

  // ------------------------------------------------------------
  // ARCHIVE / RESTORE / DELETE
  // ------------------------------------------------------------

  /// Soft delete -> status = terminated (moves to the Archive tab).
  Future<void> archiveEmployee(String id) async {
    await _api.delete(AdminEmployeeEndpoints.byId(id));
  }

  Future<void> restoreEmployee(String id) async {
    await _api.put(AdminEmployeeEndpoints.restore(id));
  }

  Future<void> deletePermanently(String id) async {
    await _api.delete(AdminEmployeeEndpoints.permanent(id));
  }

  // ------------------------------------------------------------
  // BULK IMPORT
  // ------------------------------------------------------------

  Future<AdminBulkImportResult> bulkImport(
      List<AdminBulkImportEntry> entries,
      ) async {
    final res = await _api.post(
      AdminEmployeeEndpoints.bulkImport,
      body: {'employees': entries.map((e) => e.toJson()).toList()},
    );
    return AdminBulkImportResult.fromJson(res);
  }

  // ------------------------------------------------------------
  // SALARY STRUCTURE (Set Salary dialog)
  // ------------------------------------------------------------

  /// null when the employee has no structure yet (or the call fails).
  Future<AdminSalaryStructure?> getSalaryStructure(String employeeId) async {
    try {
      final res = await _api.get(AdminEmployeeEndpoints.salaryStructure(employeeId));
      return AdminSalaryStructure.fromResponse(res);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSalary(String employeeId, AdminSalaryStructure structure) async {
    await _api.post(
      AdminEmployeeEndpoints.salaryStructure(employeeId),
      body: structure.toJson(),
    );
  }

  // ------------------------------------------------------------
  // ACCESS & CREDENTIALS (lock dialog)
  // ------------------------------------------------------------

  /// PUT /employees/:id  - only the given fields are sent.
  Future<void> updateAccess(
      String employeeId, {
        required bool portalAccess,
        required String workMode,
        String? email,
        String? password,
      }) async {
    await _api.put(
      AdminEmployeeEndpoints.byId(employeeId),
      body: {
        'portalAccess': portalAccess,
        'workMode': workMode,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
      },
    );
  }
}