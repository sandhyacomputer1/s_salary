/// What the logged-in person may do with employees.
///
/// Built once by the dashboard (from the role) and handed to the Employees
/// screen, the Overview and the employee profile, so all follow the same rules.
class AdminEmployeeAccess {
  /// Add Employee, Bulk Import.
  final bool canCreate;

  /// Access & credentials, Set salary (when salary is visible).
  final bool canEdit;

  /// Archive, Restore, Delete permanently.
  final bool canDelete;

  /// Salary column / amount, Set salary and the profile's Salary tab.
  /// (Payroll data.)
  final bool canSeeSalary;

  /// Profile: Attendance & Logs tab.
  final bool canSeeAttendance;

  /// Profile: Leave tab.
  final bool canSeeLeaves;

  /// Profile: Expenses tab.
  final bool canSeeExpenses;

  const AdminEmployeeAccess({
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.canSeeSalary = true,
    this.canSeeAttendance = true,
    this.canSeeLeaves = true,
    this.canSeeExpenses = true,
  });

  /// Everything allowed (the old behaviour).
  static const AdminEmployeeAccess full = AdminEmployeeAccess();

  /// Salary can only be set by someone who may edit AND see salary.
  bool get canManageSalary => canEdit && canSeeSalary;

  /// True when no employee action / column is hidden.
  /// (The profile tab flags are separate: they never change the list.)
  bool get isFull => canCreate && canEdit && canDelete && canSeeSalary;

  @override
  bool operator ==(Object other) =>
      other is AdminEmployeeAccess &&
          other.canCreate == canCreate &&
          other.canEdit == canEdit &&
          other.canDelete == canDelete &&
          other.canSeeSalary == canSeeSalary &&
          other.canSeeAttendance == canSeeAttendance &&
          other.canSeeLeaves == canSeeLeaves &&
          other.canSeeExpenses == canSeeExpenses;

  @override
  int get hashCode => Object.hash(
    canCreate,
    canEdit,
    canDelete,
    canSeeSalary,
    canSeeAttendance,
    canSeeLeaves,
    canSeeExpenses,
  );
}