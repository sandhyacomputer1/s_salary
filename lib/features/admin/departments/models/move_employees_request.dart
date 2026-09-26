// =================================================================
// MOVE EMPLOYEES REQUEST
//
// Request model used when moving one or more employees to another
// department.
// =================================================================

class MoveEmployeesRequest {
  final String departmentId;
  final List<String> employeeIds;

  const MoveEmployeesRequest({
    required this.departmentId,
    required this.employeeIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'employeeIds': employeeIds,
    };
  }
}