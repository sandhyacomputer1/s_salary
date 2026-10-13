import 'team_member_model.dart';

/// One selectable module tile in the Role Permissions dialog.
class PermissionModule {
  final String key; // exactly as stored in settings.rolePermissions
  final String label;
  final String group;

  const PermissionModule({
    required this.key,
    required this.label,
    required this.group,
  });
}

class PermissionCatalog {
  PermissionCatalog._();

  /// Every role in the settings sample includes this key. It is not shown as a
  /// tile (the "14" in "3 / 14 Granted" excludes it) and is never removed.
  static const String dashboardKey = 'dashboard';

  static const List<PermissionModule> modules = [
    PermissionModule(
      key: 'employees',
      label: 'Employees Directory',
      group: 'Workforce',
    ),
    PermissionModule(
      key: 'departments',
      label: 'Departments',
      group: 'Workforce',
    ),
    PermissionModule(
      key: 'calendar',
      label: 'Company Calendar & Holidays',
      group: 'Workforce',
    ),
    PermissionModule(
      key: 'shift_roster',
      label: 'Shift Roster & Planner',
      group: 'Workforce',
    ),
    PermissionModule(
      key: 'field_tracking',
      label: 'Field GPS Tracking',
      group: 'Workforce',
    ),
    PermissionModule(
      key: 'leaves',
      label: 'Leave Requests',
      group: 'Workforce',
    ),
    PermissionModule(
      key: 'notifications',
      label: 'Notifications',
      group: 'Workforce',
    ),
    PermissionModule(
      key: 'reports',
      label: 'Reports & Matrix',
      group: 'Workforce',
    ),
    PermissionModule(
      key: 'payroll',
      label: 'Payroll & Salary',
      group: 'Finance',
    ),
    PermissionModule(
      key: 'expenses',
      label: 'Expenses',
      group: 'Finance',
    ),
    PermissionModule(
      key: 'branches',
      label: 'Branches & Locations',
      group: 'Company & Security',
    ),
    PermissionModule(
      key: 'team',
      label: 'Team & Roles',
      group: 'Company & Security',
    ),
    PermissionModule(
      key: 'settings',
      label: 'Company Settings',
      group: 'Company & Security',
    ),
    PermissionModule(
      key: 'audit',
      label: 'Audit Trail',
      group: 'Company & Security',
    ),
  ];

  static final Set<String> keySet = modules.map((m) => m.key).toSet();
}

/// Working copy of settings.rolePermissions:
///   { "manager": ["dashboard", "employees", ...], "hr": [...], ... }
///
/// Keys the app doesn't know about (and "dashboard") are kept untouched, so
/// saving never silently drops permissions that exist on the server.
class RolePermissions {
  RolePermissions(Map<String, Set<String>> data)
      : _data = {
    for (final e in data.entries) e.key: Set<String>.from(e.value),
  };

  final Map<String, Set<String>> _data;

  /// Roles that can be edited in the dialog (the owner is not editable).
  static const List<String> editableRoles = TeamRole.assignable;

  /// Parses the GET /companies/me response. Accepts either
  /// { settings: { rolePermissions: {...} } } or the settings object itself.
  factory RolePermissions.fromResponse(dynamic body) {
    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

    final root = asMap(body);
    final settings =
    root['settings'] is Map ? asMap(root['settings']) : root;
    final raw = asMap(settings['rolePermissions']);

    final data = <String, Set<String>>{};

    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is List) {
        data[entry.key] = value.map((e) => e.toString()).toSet();
      }
    }

    return RolePermissions(data);
  }

  /// False when the server has no saved list for this role yet.
  bool isConfigured(String role) => _data.containsKey(role);

  bool has(String role, String key) => _data[role]?.contains(key) ?? false;

  /// Number of module tiles granted (excludes "dashboard").
  int grantedCount(String role) {
    final keys = _data[role];
    if (keys == null) return 0;
    return PermissionCatalog.keySet.where(keys.contains).length;
  }

  Set<String> _ensure(String role) =>
      _data.putIfAbsent(role, () => <String>{PermissionCatalog.dashboardKey});

  void setModule(String role, String key, bool granted) {
    final keys = _ensure(role);
    if (granted) {
      keys.add(key);
    } else {
      keys.remove(key);
    }
  }

  void selectAll(String role) {
    _ensure(role).addAll(PermissionCatalog.keySet);
  }

  void clearAll(String role) {
    _ensure(role).removeAll(PermissionCatalog.keySet);
  }

  RolePermissions copy() => RolePermissions(_data);

  bool sameAs(RolePermissions other) {
    final roles = {..._data.keys, ...other._data.keys};

    for (final role in roles) {
      final a = _data[role] ?? <String>{};
      final b = other._data[role] ?? <String>{};
      if (a.length != b.length || !a.containsAll(b)) return false;
    }

    return true;
  }

  /// { role: [keys...] } for every configured role, in a stable order.
  Map<String, List<String>> toJson() {
    final order = <String>[
      PermissionCatalog.dashboardKey,
      ...PermissionCatalog.modules.map((m) => m.key),
    ];
    final orderSet = order.toSet();

    final result = <String, List<String>>{};

    for (final entry in _data.entries) {
      final known = order.where(entry.value.contains).toList();
      final unknown = entry.value.difference(orderSet).toList()..sort();
      result[entry.key] = [...known, ...unknown];
    }

    return result;
  }
}