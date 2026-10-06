import '../../../../core/network/api_client.dart';

import '../endpoints/leave_endpoints.dart';
import '../models/leave_model.dart';

/// Wraps the result of an approve/reject call.
/// Approve responses include a leave balance; reject responses do not.
class LeaveActionResult {
  final LeaveModel leave;
  final LeaveBalanceModel? balance;

  const LeaveActionResult({
    required this.leave,
    this.balance,
  });
}

class LeaveService {
  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // GET ALL COMPANY LEAVES
  // Optional: filter by status (pending/approved/rejected/cancelled)
  // ============================================================

  Future<List<LeaveModel>> getLeaves({String? status}) async {
    final query = (status != null && status.trim().isNotEmpty)
        ? '?status=$status'
        : '';

    final response = await _apiClient.get(
      '${LeaveEndpoints.leaves}$query',
    );

    if (response is! List) {
      throw Exception('Invalid leaves response.');
    }

    return response
        .map(
          (json) => LeaveModel.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  // ============================================================
  // GET LEAVES FOR A SPECIFIC COMPANY
  // ============================================================

  Future<List<LeaveModel>> getLeavesByCompany(String companyId) async {
    final response = await _apiClient.get(
      LeaveEndpoints.leavesByCompany(companyId),
    );

    if (response is! List) {
      throw Exception('Invalid leaves response.');
    }

    return response
        .map(
          (json) => LeaveModel.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  // ============================================================
  // GET LEAVES FOR A SPECIFIC EMPLOYEE
  // ============================================================

  Future<List<LeaveModel>> getLeavesByEmployee(String employeeId) async {
    final response = await _apiClient.get(
      LeaveEndpoints.leavesByEmployee(employeeId),
    );

    if (response is! List) {
      throw Exception('Invalid leaves response.');
    }

    return response
        .map(
          (json) => LeaveModel.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  // ============================================================
  // APPROVE LEAVE
  // PUT /leaves/:id/status  Body: {"status": "approved"}
  //
  // Success response shape:
  // { "leave": {...}, "balance": {...} }
  // ============================================================

  Future<LeaveActionResult> approveLeave(String leaveId) async {
    final response = await _apiClient.put(
      LeaveEndpoints.updateStatus(leaveId),
      body: {
        'status': 'approved',
      },
    );

    if (response is! Map) {
      throw Exception('Invalid approve leave response.');
    }

    final map = Map<String, dynamic>.from(response);

    final leaveJson = map['leave'];

    if (leaveJson is! Map) {
      throw Exception('Invalid approve leave response: missing leave data.');
    }

    final leave = LeaveModel.fromJson(
      Map<String, dynamic>.from(leaveJson),
    );

    final balanceJson = map['balance'];

    final balance = balanceJson is Map
        ? LeaveBalanceModel.fromJson(
      Map<String, dynamic>.from(balanceJson),
    )
        : null;

    return LeaveActionResult(leave: leave, balance: balance);
  }

  // ============================================================
  // REJECT LEAVE
  // PUT /leaves/:id/status  Body: {"status": "rejected"}
  //
  // Success response shape: the leave object directly (no wrapper).
  // ============================================================

  Future<LeaveActionResult> rejectLeave(String leaveId) async {
    final response = await _apiClient.put(
      LeaveEndpoints.updateStatus(leaveId),
      body: {
        'status': 'rejected',
      },
    );

    if (response is! Map) {
      throw Exception('Invalid reject leave response.');
    }

    final leave = LeaveModel.fromJson(
      Map<String, dynamic>.from(response),
    );

    return LeaveActionResult(leave: leave);
  }

  // ============================================================
  // GET EMPLOYEE NAMES
  // Returns a map of employee _id -> name, built from GET /employees.
  // Used to show the employee's real name on leave cards/details
  // (the leaves API's employeeId object only has _id and employeeCode).
  // ============================================================

  Future<Map<String, String>> getEmployeeNames() async {
    final response = await _apiClient.get(
      LeaveEndpoints.employees,
    );

    if (response is! List) {
      throw Exception('Invalid employees response.');
    }

    final map = <String, String>{};

    for (final item in response) {
      if (item is! Map) continue;

      final employee = Map<String, dynamic>.from(item);

      final id = employee['_id']?.toString();
      final name = employee['name']?.toString();

      if (id != null &&
          id.isNotEmpty &&
          name != null &&
          name.trim().isNotEmpty) {
        map[id] = name;
      }
    }

    return map;
  }
}