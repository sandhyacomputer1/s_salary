// /// Role & permission model for S Salary.
// ///
// /// Based on the Android API reference:
// /// - role: super_admin | admin | employee
// /// - subRole (admins only): owner | general_admin | hr | accountant | manager
// /// - owner, general_admin and manager have FULL access
// /// - hr = people / leave / attendance focus
// /// - accountant = payroll / expense focus
// ///
// /// NOTE: the server grants every admin full access regardless of subRole,
// /// so this is for UI gating ONLY. It is not a security boundary.
//
// enum AppModule {
//   overview,
//   employees,
//   attendance,
//   leaves,
//   payroll,
//   expenses,
//   reports,
//   holidays,
//   branches,
//   departments,
//   shifts,
//   settings,
//   subAdmins,
//   auditLogs,
// }
//
// enum AppAction { view, create, edit, delete }
//
// class AppPermissions {
//   AppPermissions._();
//
//   static const String roleSuperAdmin = 'super_admin';
//   static const String roleAdmin = 'admin';
//   static const String roleEmployee = 'employee';
//
//   static const String subOwner = 'owner';
//   static const String subGeneralAdmin = 'general_admin';
//   static const String subHr = 'hr';
//   static const String subAccountant = 'accountant';
//   static const String subManager = 'manager';
//
//   static const Set<AppAction> _all = {
//     AppAction.view,
//     AppAction.create,
//     AppAction.edit,
//     AppAction.delete,
//   };
//   static const Set<AppAction> _viewOnly = {AppAction.view};
//   static const Set<AppAction> _viewEdit = {AppAction.view, AppAction.edit};
//
//   /// Permissions for HR: people, leave and attendance focus.
//   static const Map<AppModule, Set<AppAction>> _hr = {
//     AppModule.overview: _viewOnly,
//     AppModule.employees: _all,
//     AppModule.attendance: _viewEdit,
//     AppModule.leaves: _viewEdit,
//     AppModule.holidays: _all,
//     AppModule.reports: _viewOnly,
//     AppModule.branches: _viewOnly,
//     AppModule.departments: _viewOnly,
//     AppModule.shifts: _viewOnly,
//   };
//
//   /// Permissions for Accountant: payroll and expense focus.
//   static const Map<AppModule, Set<AppAction>> _accountant = {
//     AppModule.overview: _viewOnly,
//     AppModule.employees: _viewOnly,
//     AppModule.attendance: _viewOnly,
//     AppModule.payroll: _all,
//     AppModule.expenses: _viewEdit,
//     AppModule.reports: _viewOnly,
//   };
//
//   /// Normalises a raw value from the API.
//   static String _norm(String? v) => (v ?? '').trim().toLowerCase();
//
//   /// True when the user has full access to everything.
//   static bool isFullAccess({required String? role, required String? subRole}) {
//     final r = _norm(role);
//     final s = _norm(subRole);
//     if (r == roleSuperAdmin) return true;
//     if (r != roleAdmin) return false;
//     // owner, general_admin, manager (and unknown/empty admin sub-role)
//     // are full access, matching the API reference.
//     return s != subHr && s != subAccountant;
//   }
//
//   /// Returns the actions allowed for [module].
//   static Set<AppAction> actionsFor({
//     required String? role,
//     required String? subRole,
//     required AppModule module,
//   }) {
//     final r = _norm(role);
//     final s = _norm(subRole);
//
//     // Employees never see admin modules.
//     if (r != roleAdmin && r != roleSuperAdmin) return const {};
//
//     if (isFullAccess(role: role, subRole: subRole)) return _all;
//
//     switch (s) {
//       case subHr:
//         return _hr[module] ?? const {};
//       case subAccountant:
//         return _accountant[module] ?? const {};
//       default:
//         return const {};
//     }
//   }
//
//   static bool can({
//     required String? role,
//     required String? subRole,
//     required AppModule module,
//     AppAction action = AppAction.view,
//   }) {
//     return actionsFor(role: role, subRole: subRole, module: module)
//         .contains(action);
//   }
//
//   /// Modules this user can open (for building the sidebar).
//   static List<AppModule> visibleModules({
//     required String? role,
//     required String? subRole,
//   }) {
//     return AppModule.values
//         .where((m) => can(role: role, subRole: subRole, module: m))
//         .toList();
//   }
// }




/// Role & permission model for S Salary.
///
/// Based on the Android API reference:
/// - role: super_admin | admin | employee
/// - subRole (admins only): owner | general_admin | hr | accountant | manager
/// - owner and general_admin have FULL access
/// - hr = people / leave / attendance focus
/// - accountant = payroll / expense focus
///
/// The company's saved list (settings.rolePermissions from the server) is the
/// main source for which screens a role can open. This file is the FALLBACK
/// (used when that list is missing) and also decides view / create / edit /
/// delete inside a screen.
///
/// NOTE: the server grants every admin full access regardless of subRole,
/// so this is for UI gating ONLY. It is not a security boundary.

enum AppModule {
  overview,
  employees,
  attendance,
  leaves,
  payroll,
  expenses,
  reports,
  holidays,
  branches,
  departments,
  shifts,
  settings,
  subAdmins,
  auditLogs,
}

enum AppAction { view, create, edit, delete }

class AppPermissions {
  AppPermissions._();

  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';

  static const String subOwner = 'owner';
  static const String subGeneralAdmin = 'general_admin';
  static const String subHr = 'hr';
  static const String subAccountant = 'accountant';
  static const String subManager = 'manager';

  static const Set<AppAction> _all = {
    AppAction.view,
    AppAction.create,
    AppAction.edit,
    AppAction.delete,
  };
  static const Set<AppAction> _viewOnly = {AppAction.view};
  static const Set<AppAction> _viewEdit = {AppAction.view, AppAction.edit};

  /// HR (matches the server default: dashboard, employees, departments,
  /// calendar, shift_roster, field_tracking, leaves, notifications, reports).
  static const Map<AppModule, Set<AppAction>> _hr = {
    AppModule.overview: _viewOnly,
    AppModule.employees: _all,
    AppModule.attendance: _viewEdit,
    AppModule.leaves: _viewEdit,
    AppModule.holidays: _all,
    AppModule.reports: _viewOnly,
    AppModule.departments: _viewOnly,
    AppModule.shifts: _viewOnly,
  };

  /// Accountant (matches the server default: dashboard, payroll, expenses,
  /// reports).
  static const Map<AppModule, Set<AppAction>> _accountant = {
    AppModule.overview: _viewOnly,
    AppModule.payroll: _all,
    AppModule.expenses: _viewEdit,
    AppModule.reports: _viewOnly,
  };

  /// Normalises a raw value from the API.
  static String _norm(String? v) => (v ?? '').trim().toLowerCase();

  /// True when the user has full access to everything.
  static bool isFullAccess({required String? role, required String? subRole}) {
    final r = _norm(role);
    final s = _norm(subRole);
    if (r == roleSuperAdmin) return true;
    if (r != roleAdmin) return false;
    // owner, general_admin, manager (and unknown/empty admin sub-role)
    // are full access, matching the API reference.
    return s != subHr && s != subAccountant;
  }

  /// Returns the actions allowed for [module].
  static Set<AppAction> actionsFor({
    required String? role,
    required String? subRole,
    required AppModule module,
  }) {
    final r = _norm(role);
    final s = _norm(subRole);

    // Employees never see admin modules.
    if (r != roleAdmin && r != roleSuperAdmin) return const {};

    if (isFullAccess(role: role, subRole: subRole)) return _all;

    switch (s) {
      case subHr:
        return _hr[module] ?? const {};
      case subAccountant:
        return _accountant[module] ?? const {};
      default:
        return const {};
    }
  }

  static bool can({
    required String? role,
    required String? subRole,
    required AppModule module,
    AppAction action = AppAction.view,
  }) {
    return actionsFor(role: role, subRole: subRole, module: module)
        .contains(action);
  }

  /// Modules this user can open (for building the sidebar).
  static List<AppModule> visibleModules({
    required String? role,
    required String? subRole,
  }) {
    return AppModule.values
        .where((m) => can(role: role, subRole: subRole, module: m))
        .toList();
  }
}