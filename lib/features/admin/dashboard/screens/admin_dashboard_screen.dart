import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/permissions/app_permissions.dart'; // PERMISSION
import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import '../../../../data/services/leave_service.dart';
import '../../../../data/services/expense_service.dart';
import '../../attendance_notifications/widgets/check_in_out_notifications_screen.dart';
import '../../audit_trail/screens/audit_trail_screen.dart';
import '../../branches/screens/branches_screen.dart';
import '../../departments/screens/department_screen.dart';
import '../../employees/models/admin_employee_access.dart'; // PERMISSION
import '../../employees/models/admin_employee_model.dart';
import '../../employees/screens/admin_employees_screen.dart';
import '../../expenses/screens/expense_screen.dart';
import '../../field_tracking/screens/field_tracking_screen.dart';
import '../../payroll/screens/payroll_screen.dart';
import '../../reports/widgets/reports_main_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../shift_roster/screens/shift_roster_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../leaves/screens/leave_screen.dart';
import '../../team_roles/screens/team_roles_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// MY SPACE: the employee screens, reused inside this dashboard
import '../../../employee/dashboard/screens/emp_dashboard_screen.dart';
import '../../../employee/expense_claims/screens/employee_submit_expense_claim_screen.dart';
import '../../../employee/leave/screens/emp_apply_leave_screen.dart';
import '../../../employee/salary/screens/employee_salary_screen.dart';

import '../services/admin_session_profile_service.dart';
import '../widgets/admin_brand_logo.dart';
import '../widgets/admin_notifications_panel/admin_notifications_panel.dart';
import 'admin_overview_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  // ==========================================================
  // BREAKPOINTS & COLORS
  // ==========================================================

  static const double _mobileBreakpoint = 800;
  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  static const Color _primary = Color(0xFFE96832);
  static const Color _primaryTint = Color(0xFFFFEEE7);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);

  // Sidebar sizes
  static const double _sidebarWidth = 260;
  static const double _sidebarCollapsedWidth = 76;

  /// Below this width the sidebar shows its icon-only layout.
  static const double _sidebarCollapseThreshold = 150;

  // ==========================================================
  // SERVICES & DATA
  // ==========================================================

  final EmployeeService _employeeService = EmployeeService();
  final LeaveService _leaveService = LeaveService();
  final ExpenseService _expenseService = ExpenseService();
  /// The permission pop-ups are shown once each time the app is opened.
  static bool _askedThisSession = false;

  // Which permissions to ask when the dashboard opens
  static const bool _askNotificationPermission = true;
  static const bool _askLocationPermission = false; // turn on if admin uses GPS
  static const bool _askCameraPermission = false; // turn on if admin takes photos

  // Numbers for the bell badge. (The overview screen loads its own data.)
  int _pendingLeaves = 0;
  int _pendingExpenses = 0;
  LicenseInfo? _license; // data for the "Software Expiry Details" card

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;
  bool _isRefreshing = false;

  // SIDEBAR & NAVIGATION STATE
  bool _isSidebarCollapsed = false;
  int _selectedScreenIndex = 0;

  /// Changing this value rebuilds the Overview screen (reloads its data).
  int _overviewReload = 0;

  /// Changing this value rebuilds the Employees screen, so clicking
  /// "Employees" in the sidebar always shows the list (not an open profile).
  int _employeesResetKey = 0;

  /// Employee profile that the Employees screen should open directly
  /// (set when the person icon is tapped on the Overview).
  AdminEmployeeModel? _pendingProfile;

  /// Name + role of the logged-in person (sidebar footer).
  AdminSessionProfile _me = const AdminSessionProfile(name: 'Admin', roleLabel: 'Admin');

  // PERMISSION: false until the logged-in person's role is known.
  // Until then only the Overview is available (so HR / Accountant never
  // see a full menu for a moment).
  bool _profileLoaded = false;

  // CLOCK
  Timer? _clockTimer;
  String _currentDate = '';
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _updateDateTime(),
    );
    _loadDashboardData();
    _loadLicense();
    _loadMyProfile();

    // Ask for permissions as soon as the dashboard is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStartupPermissions();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    if (!mounted) return;
    setState(() {
      _currentDate = '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
      _currentTime = '$hour:$minute $period';
    });
  }

  Future<bool?> _askDialog({
    required String title,
    required String message,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Color(0xFF4B5563),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: _primary),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _requestStartupPermissions() async {
    if (_askedThisSession) return;
    _askedThisSession = true;

    if (kIsWeb) return; // the browser asks by itself on the web

    final blocked = <String>[]; // permissions that can only be fixed in Settings

    try {
      // 1) Notifications (Android 13+ / iOS)
      if (_askNotificationPermission) {
        var notif = await Permission.notification.status;
        if (notif.isDenied) notif = await Permission.notification.request();
        if (notif.isPermanentlyDenied) blocked.add('Notifications');
      }

      // 2) Location (optional)
      if (_askLocationPermission) {
        var location = await Geolocator.checkPermission();
        if (location == LocationPermission.denied) {
          location = await Geolocator.requestPermission();
        }
        if (location == LocationPermission.deniedForever) {
          blocked.add('Location');
        }
      }

      // 3) Camera (optional)
      if (_askCameraPermission) {
        var camera = await Permission.camera.status;
        if (camera.isDenied) camera = await Permission.camera.request();
        if (camera.isPermanentlyDenied) blocked.add('Camera');
      }
    } catch (e) {
      debugPrint('PERMISSION REQUEST ERROR: $e');
    }

    // Something was blocked ("Don't ask again") -> only Settings can fix it.
    if (blocked.isNotEmpty && mounted) {
      final open = await _askDialog(
        title: '${blocked.join(' & ')} blocked',
        message:
        'Please allow ${blocked.join(' and ')} in the app settings to '
            'receive check-in and check-out alerts.',
        action: 'Open Settings',
      );
      if (open == true) await openAppSettings();
    }
  }

  /// Loads the numbers for the notification bell (pending leaves / expenses).
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final employeeResults = await Future.wait([
        _employeeService.getEmployees(status: 'active'),
      ]);
      final activeEmployees = employeeResults[0] as List<Employee>;

      int pendingLeaveCount = 0;
      if (activeEmployees.isNotEmpty) {
        final leaveResults = await Future.wait(activeEmployees.map((employee) async {
          try {
            final balance = await _leaveService.getLeaveBalance(employee.id);
            final value = balance['pendingApprovals'];
            return value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
          } catch (_) { return 0; }
        }));
        for (final value in leaveResults) { pendingLeaveCount += value; }
      }

      int pendingExpenseCount = 0;
      if (activeEmployees.isNotEmpty) {
        final expenseResults = await Future.wait(activeEmployees.map((employee) async {
          try { return await _expenseService.getPendingExpenseCount(employee.id); } catch (_) { return 0; }
        }));
        for (final value in expenseResults) { pendingExpenseCount += value; }
      }

      if (!mounted) return;
      setState(() {
        _pendingLeaves = pendingLeaveCount;
        _pendingExpenses = pendingExpenseCount;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _overviewReload++; // reload the Overview screen too
    });
    _loadLicense();
    _loadMyProfile(); // PERMISSION: pick up role / permission changes
    await _loadDashboardData();
  }

  /// Who is logged in: admin / owner / HR / accountant / manager.
  Future<void> _loadMyProfile() async {
    AdminSessionProfile profile = _me;
    try {
      profile = await AdminSessionProfileService().load();
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');
    }

    // MY SPACE: the employee screens read the employee id from storage,
    // so make sure this login's own employee id is saved there.
    await _syncEmployeeId(profile.employeeId);

    if (!mounted) return;
    setState(() {
      _me = profile;
      _profileLoaded = true; // PERMISSION: role is now known
    });
  }

  /// MY SPACE: saves this person's own employee id (only if it changed).
  Future<void> _syncEmployeeId(String employeeId) async {
    if (employeeId.isEmpty) return;
    try {
      final saved = await SecureStorage.getEmployeeId();
      if (saved != employeeId) {
        await SecureStorage.saveEmployeeId(employeeId);
      }
    } catch (e) {
      debugPrint('EMPLOYEE ID SAVE ERROR: $e');
    }
  }

  /// Loads the licence data (start date, valid until, duration).
  Future<void> _loadLicense() async {
    final info = await LicenseInfo.fetch();
    if (!mounted) return;
    setState(() => _license = info);
  }

  // ==========================================================
  // PERMISSION (role based access)
  // ==========================================================

  /// Name of each screen in the company's saved permission list
  /// (settings.rolePermissions from the server).
  static const Map<int, String> _screenKeys = {
    0: 'dashboard',
    1: 'employees',
    2: 'calendar',
    3: 'leaves',
    4: 'shift_roster',
    5: 'field_tracking',
    6: 'departments',
    7: 'expenses',
    8: 'notifications',
    9: 'audit',
    10: 'payroll',
    11: 'branches',
    12: 'team',
    13: 'settings',
    14: 'reports',
  };

  // MY SPACE screens (own check-in, leaves, expenses, payslips).
  // They are not part of the company's saved permission list: they depend
  // on having an employee record (and, for payslips, on the API rules).
  static const int _mySpaceFirst = 15;
  static const int _myAttendance = 15;
  static const int _myLeaves = 16;
  static const int _myExpenses = 17;
  static const int _myPayslips = 18;

  /// Sub-role of the logged-in admin: owner | general_admin | hr |
  /// accountant | manager (API reference, section 3.1).
  /// An admin whose sub-role is unknown is treated as general_admin.
  String get _subRoleKey =>
      _me.subRole.isNotEmpty ? _me.subRole : AppPermissions.subGeneralAdmin;

  /// Owner and general admin always have full access (the server's saved
  /// list has no entry for them).
  bool get _isOwnerLevel =>
      _subRoleKey == AppPermissions.subOwner ||
          _subRoleKey == AppPermissions.subGeneralAdmin;

  /// MY SPACE: does this login have its own employee record?
  bool get _hasEmployeeRecord => _me.employeeId.isNotEmpty;

  /// MY SPACE rules (API reference):
  ///  - check-in / check-out, leaves, expenses: every admin with an employee
  ///  - payslips (GET /salary/slips): employee, accountant, manager only
  bool _canOpenMySpace(int index) {
    if (!_profileLoaded || !_hasEmployeeRecord) return false;
    if (index == _myPayslips) {
      return _subRoleKey == AppPermissions.subAccountant ||
          _subRoleKey == AppPermissions.subManager;
    }
    return true;
  }

  /// Fallback module for a screen (used only if the server sent no list).
  AppModule? _moduleForIndex(int index) {
    switch (index) {
      case 1:
        return AppModule.employees;
      case 3:
        return AppModule.leaves;
      case 4:
        return AppModule.shifts;
      case 5:
        return AppModule.attendance; // Field Tracking
      case 6:
        return AppModule.departments;
      case 7:
        return AppModule.expenses;
      case 8:
        return AppModule.attendance; // Check-in / check-out notifications
      case 9:
        return AppModule.auditLogs;
      case 10:
        return AppModule.payroll;
      case 11:
        return AppModule.branches;
      case 12:
        return AppModule.subAdmins; // Team & Roles
      case 13:
        return AppModule.settings;
      case 14:
        return AppModule.reports;
      default:
        return null; // 0 = Overview, 2 = Calendar
    }
  }

  bool _can(AppModule module, [AppAction action = AppAction.view]) {
    return AppPermissions.can(
      role: AppPermissions.roleAdmin,
      subRole: _subRoleKey,
      module: module,
      action: action,
    );
  }

  /// Can the logged-in person open this screen?
  ///   0. MY SPACE screens -> own rules (employee record, API role list)
  ///   1. owner / general admin  -> yes
  ///   2. the company's saved list from the server -> must contain the screen
  ///   3. no list from the server -> built-in fallback (app_permissions.dart)
  bool _canOpenIndex(int index) {
    if (index == 0) return true; // Overview is always available
    if (!_profileLoaded) return false; // role not known yet
    if (index >= _mySpaceFirst) return _canOpenMySpace(index);
    if (_isOwnerLevel) return true;

    final key = _screenKeys[index];
    if (key == null) return true;

    if (_me.permissions.isNotEmpty) return _me.permissions.contains(key);

    final module = _moduleForIndex(index);
    if (module == null) return true;
    return _can(module);
  }

  /// Can the logged-in person do this action (create / edit / delete) in a
  /// module? Owner and general admin: always. Others: the built-in map in
  /// app_permissions.dart. No entry there = view only.
  bool _canDo(AppModule module, AppAction action) {
    if (!_profileLoaded) return false;
    if (_isOwnerLevel) return true;
    return _can(module, action);
  }

  /// Approve / reject leaves. Everyone else who can open Leaves only views.
  bool get _canManageLeaves => _canDo(AppModule.leaves, AppAction.edit);

  /// Approve / reject expenses. Everyone else who can open Expenses only views.
  bool get _canManageExpenses => _canDo(AppModule.expenses, AppAction.edit);

  /// Generate / email payroll, refund PF, set salary. Everyone else who can
  /// open Payroll only views.
  bool get _canManagePayroll => _canDo(AppModule.payroll, AppAction.edit);

  /// What this role may do with employees (Employees screen, Overview and
  /// the employee profile).
  AdminEmployeeAccess get _employeeAccess => AdminEmployeeAccess(
    canCreate: _canDo(AppModule.employees, AppAction.create),
    canEdit: _canDo(AppModule.employees, AppAction.edit),
    canDelete: _canDo(AppModule.employees, AppAction.delete),
    // Salary is payroll data: only roles that can open Payroll (screen 10)
    // see it. To let everyone who can open Employees see salary, change
    // this line to:  canSeeSalary: true,
    canSeeSalary: _canOpenIndex(10),
    // Profile tabs follow the matching dashboard screens:
    canSeeAttendance:
    _canOpenIndex(1) || _canOpenIndex(8) || _canOpenIndex(5),
    canSeeLeaves: _canOpenIndex(3),
    canSeeExpenses: _canOpenIndex(7),
  );

  /// Bell numbers only count what this person is allowed to see.
  int get _leavesBadge => _canOpenIndex(3) ? _pendingLeaves : 0;
  int get _expensesBadge => _canOpenIndex(7) ? _pendingExpenses : 0;

  /// The number shown on the red badge of the bell icon.
  int get _notificationCount => adminNotificationCount(
    license: _license,
    pendingLeaves: _leavesBadge,
    pendingExpenses: _expensesBadge,
  );

  /// Opens the notifications panel under the bell icon.
  Future<void> _openNotificationsPanel() {
    return showAdminNotificationsPanel(
      context,
      license: _license,
      pendingLeaves: _leavesBadge,
      pendingExpenses: _expensesBadge,
      // "View all notifications" -> the check-in / check-out notifications screen
      onViewAll: () => _goTo(8),
      // tapping the pending cards opens Leaves / Expenses
      onOpenLeaves: () => _goTo(3),
      onOpenExpenses: () => _goTo(7),
    );
  }

  /// Switches the screen WITHOUT touching the drawer.
  void _goTo(int index) {
    if (!_canOpenIndex(index)) return; // PERMISSION: blocked screen
    setState(() {
      if (index == 1) {
        _pendingProfile = null; // sidebar "Employees" always shows the list
        _employeesResetKey++;
      }
      _selectedScreenIndex = index;
    });
  }

  /// Sidebar tap: closes the drawer on phones, then switches.
  void _onNavigationSelected(int index) {
    if (_isMobile) Navigator.pop(context); // Close drawer on mobile
    _goTo(index);
  }

  /// Person icon on the Overview -> Employees screen with this profile open.
  void _openProfileFromOverview(AdminEmployeeModel employee) {
    if (!_canOpenIndex(1)) return; // PERMISSION: no access to Employees
    setState(() {
      _pendingProfile = employee;
      _employeesResetKey++;
      _selectedScreenIndex = 1;
    });
  }

  // ==========================================================
  // BUILD LAYOUT
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // Mobile layout uses standard Drawer
    if (_isMobile) {
      return Scaffold(
        backgroundColor: _pageBg,
        drawer: Drawer(
          width: 280,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          child: _buildSidebar(isMobileDrawer: true),
        ),
        appBar: _buildAppBar(),
        body: SafeArea(child: _buildBodyContent()),
      );
    }

    // Web/Desktop layout uses a persistent Sidebar Row
    return Scaffold(
      backgroundColor: _pageBg,
      body: Row(
        children: [
          // Persistent Sidebar (width animates when collapsing / expanding)
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            width: _isSidebarCollapsed ? _sidebarCollapsedWidth : _sidebarWidth,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: _border)),
            ),
            child: _buildSidebar(isMobileDrawer: false),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildBodyContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String titleText = 'Company Dashboard';
    if (_selectedScreenIndex == 1) titleText = 'Employees';
    if (_selectedScreenIndex == 2) titleText = 'Calendar';
    if (_selectedScreenIndex == 3) titleText = 'Leave Requests';
    if (_selectedScreenIndex == 4) titleText = 'Shift Roster & Planner';
    if (_selectedScreenIndex == 5) titleText = 'Field GPS Tracking';
    if (_selectedScreenIndex == 6) titleText = 'Departments';
    if (_selectedScreenIndex == 7) titleText = 'Expenses';
    if (_selectedScreenIndex == 8) {
      // shorter on phones so it fits in the top bar
      titleText = _isMobile
          ? 'Notifications'
          : 'Check-In & Check-Out Notifications';
    }
    if (_selectedScreenIndex == 9) titleText = 'Audit Trail';
    if (_selectedScreenIndex == 10) titleText = 'Payroll & Salary';
    if (_selectedScreenIndex == 11) titleText = 'Branches & Locations';
    if (_selectedScreenIndex == 12) titleText = 'Team & Roles';
    if (_selectedScreenIndex == 13) titleText = 'Settings';
    if (_selectedScreenIndex == 14) titleText = 'Reports & Matrix';
    if (_selectedScreenIndex == _myAttendance) titleText = 'My Attendance';
    if (_selectedScreenIndex == _myLeaves) titleText = 'My Leaves';
    if (_selectedScreenIndex == _myExpenses) titleText = 'My Expenses';
    if (_selectedScreenIndex == _myPayslips) titleText = 'My Payslips';

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: _isMobile ? 4 : 20,
      title: Row(
        children: [
          if (!_isMobile) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Flexible + ellipsis = a long title can never overflow
          Flexible(
            child: Text(
              titleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (!_isMobile) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: _buildDateTimeChip(),
          ),
          const SizedBox(width: 8),
        ],
        IconButton(
          tooltip: 'Refresh Dashboard',
          onPressed: _isLoading ? null : _refreshDashboard,
          icon: _isRefreshing
              ? const SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: _openNotificationsPanel,
          icon: Badge(
            isLabelVisible: _notificationCount > 0,
            label: Text('$_notificationCount'),
            backgroundColor: const Color(0xFFE53935),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildDateTimeChip({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 13, vertical: compact ? 8 : 9),
      decoration: BoxDecoration(color: compact ? Colors.white : _pageBg, borderRadius: BorderRadius.circular(9), border: Border.all(color: _border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF6B7280)),
          const SizedBox(width: 7),
          Flexible(child: Text(_currentDate, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)))),
          const SizedBox(width: 12),
          const Icon(Icons.access_time_outlined, size: 15, color: _primary),
          const SizedBox(width: 6),
          Text(_currentTime, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
        ],
      ),
    );
  }

  /// PERMISSION: shown if someone reaches a screen their role cannot open.
  Widget _buildNoAccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _primaryTint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: _primary, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'No access',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your role does not have permission to open this screen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() => _selectedScreenIndex = 0),
              style: FilledButton.styleFrom(backgroundColor: _primary),
              child: const Text('Go to Overview'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    // PERMISSION: never build a screen this role is not allowed to open
    if (!_canOpenIndex(_selectedScreenIndex)) return _buildNoAccess();

    if (_selectedScreenIndex == 1) {
      return AdminEmployeesScreen(
        key: ValueKey('employees-$_employeesResetKey'),
        embedded: true,
        initialProfile: _pendingProfile,
        access: _employeeAccess, // PERMISSION
      );
    }
    if (_selectedScreenIndex == 2) return const CalendarScreen(embedded: true);
    if (_selectedScreenIndex == 3) {
      // PERMISSION: view only unless this role may manage leaves
      return LeaveScreen(embedded: true, canManage: _canManageLeaves);
    }
    if (_selectedScreenIndex == 4) return const ShiftRosterScreen(embedded: true);
    if (_selectedScreenIndex == 5) return const FieldTrackingScreen(embedded: true);
    if (_selectedScreenIndex == 6) return const DepartmentScreen(embedded: true);
    if (_selectedScreenIndex == 7) {
      // PERMISSION: view only unless this role may manage expenses
      return ExpenseScreen(embedded: true, canManage: _canManageExpenses);
    }
    if (_selectedScreenIndex == 8) return const CheckInOutNotificationsScreen(embedded: true);
    if (_selectedScreenIndex == 9) return const AuditTrailScreen(embedded: true);
    if (_selectedScreenIndex == 10) {
      // PERMISSION: view only unless this role may manage payroll
      return PayrollScreen(embedded: true, canManage: _canManagePayroll);
    }
    if (_selectedScreenIndex == 11) return const BranchesScreen(embedded: true);
    if (_selectedScreenIndex == 12) return const TeamRolesScreen(embedded: true);
    if (_selectedScreenIndex == 13) return const SettingsScreen(embedded: true);
    if (_selectedScreenIndex == 14) return const ReportsMainScreen();

    // MY SPACE: the employee screens, reused as they are
    if (_selectedScreenIndex == _myAttendance) {
      return const EmpDashboardScreen(embedded: true);
    }
    if (_selectedScreenIndex == _myLeaves) {
      return const EmpApplyLeaveScreen(embedded: true);
    }
    if (_selectedScreenIndex == _myExpenses) {
      return const EmployeeSubmitExpenseClaimScreen(embedded: true);
    }
    if (_selectedScreenIndex == _myPayslips) {
      return const EmployeeSalaryScreen(embedded: true);
    }

    // PERMISSION: wait for the role, so the Overview is loaded only once
    // and with the right parts (no flash of cards this role cannot see)
    if (!_profileLoaded) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    // Overview (matches the web dashboard)
    // PERMISSION: each role gets only the parts it can use
    return AdminOverviewScreen(
      key: ValueKey('overview-$_overviewReload'),
      canSeeEmployees: _canOpenIndex(1),
      canSeeAttendance: _canOpenIndex(1) || _canOpenIndex(8) || _canOpenIndex(5),
      canSeeLeaves: _canOpenIndex(3),
      canSeeExpenses: _canOpenIndex(7),
      employeeAccess: _employeeAccess,
      onViewAllEmployees: () => _goTo(1),
      onViewAllLeaves: () => _goTo(3),
      onViewAllExpenses: () => _goTo(7),
      onOpenProfile: _openProfileFromOverview,
      onDataChanged: _loadDashboardData, // keeps the bell badge up to date
    );
  }

  // ==========================================================
  // SIDEBAR
  // ==========================================================

  /// The menu, grouped in parts. Add / remove items here.
  /// PERMISSION: items (and empty groups) the role cannot open are removed.
  List<_SideSection> _sidebarSections() {
    final all = <_SideSection>[
      _SideSection('OVERVIEW', [
        _SideItem(Icons.dashboard_outlined,
            'Overview', () => _onNavigationSelected(0),
            selectedIndex: 0
        ),

      ]),

      // MY SPACE: the person's own check-in, leaves, expenses and payslips
      _SideSection('MY SPACE', [
        _SideItem(
            Icons.how_to_reg_outlined,
            'My Attendance',
                () => _onNavigationSelected(_myAttendance),
            selectedIndex: _myAttendance
        ),

        _SideItem(
            Icons.event_note_outlined,
            'My Leaves',
                () => _onNavigationSelected(_myLeaves),
            selectedIndex: _myLeaves
        ),

        _SideItem(
            Icons.request_quote_outlined,
            'My Expenses',
                () => _onNavigationSelected(_myExpenses),
            selectedIndex: _myExpenses
        ),

        _SideItem(
            Icons.description_outlined,
            'My Payslips',
                () => _onNavigationSelected(_myPayslips),
            selectedIndex: _myPayslips
        ),
      ]),

      _SideSection('WORKFORCE', [
        _SideItem(
            Icons.people_outline,
            'Employees',
                () => _onNavigationSelected(1),
            selectedIndex: 1
        ),

        _SideItem(
            Icons.calendar_month_outlined,
            'Calendar',
                () => _onNavigationSelected(2),
            selectedIndex: 2
        ),

        _SideItem(
            Icons.schedule_outlined,
            'Shift Roster',
                () => _onNavigationSelected(4),
            selectedIndex: 4
        ),

        _SideItem(
            Icons.location_on_outlined,
            'Field Tracking',
                () => _onNavigationSelected(5),
            selectedIndex: 5
        ),

        _SideItem(Icons.event_available_outlined,
            'Leaves',
                () => _onNavigationSelected(3),
            selectedIndex: 3
        ),

        _SideItem(Icons.account_tree_outlined,
            'Departments', () => _onNavigationSelected(6),
            selectedIndex: 6
        ),

        _SideItem(Icons.notifications_active_outlined,
            'Notifications', () => _onNavigationSelected(8),
            selectedIndex: 8
        ),
        _SideItem(Icons.table_chart_outlined,
            'Reports & Matrix', () => _onNavigationSelected(14),
            selectedIndex: 14
        ),
      ]),
      _SideSection('FINANCE', [

        _SideItem(
            Icons.payments_outlined,
            'Payroll & Salary',
                () => _onNavigationSelected(10),
            selectedIndex: 10
        ),

        _SideItem(
            Icons.receipt_long_outlined,
            'Expenses',
                () => _onNavigationSelected(7),
            selectedIndex: 7
        ),
      ]),

      _SideSection('COMPANY & SECURITY', [

        _SideItem(
            Icons.business_outlined,
            'Branches',
                () => _onNavigationSelected(11),
            selectedIndex: 11
        ),

        _SideItem(
            Icons.admin_panel_settings_outlined,
            'Team & Roles',
                () => _onNavigationSelected(12),
            selectedIndex: 12
        ),

        _SideItem(
            Icons.settings_outlined,
            'Settings',
                () => _onNavigationSelected(13),
            selectedIndex: 13
        ),

        _SideItem(Icons.shield_outlined,
            'Audit Trail', () => _onNavigationSelected(9),
            selectedIndex: 9
        ),
      ]),
    ];

    // PERMISSION: keep only what this role can open, drop empty groups
    final visible = <_SideSection>[];
    for (final section in all) {
      final items = section.items
          .where((item) =>
      item.selectedIndex == null || _canOpenIndex(item.selectedIndex!))
          .toList();
      if (items.isNotEmpty) visible.add(_SideSection(section.title, items));
    }
    return visible;
  }

  Widget _buildSidebar({required bool isMobileDrawer}) {
    // The layout is chosen from the REAL width, so nothing overflows while
    // the sidebar animates between open and collapsed.
    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsed =
            !isMobileDrawer && constraints.maxWidth < _sidebarCollapseThreshold;

        final sections = _sidebarSections();
        final menu = <Widget>[];
        var order = 0;

        for (var s = 0; s < sections.length; s++) {
          final section = sections[s];

          if (collapsed) {
            if (s > 0) menu.add(_sectionDivider());
          } else {
            menu.add(_drawerSection(section.title, first: s == 0));
          }

          for (final item in section.items) {
            menu.add(_sidebarTile(item, collapsed, order));
            order++;
          }
        }

        return ClipRect(
          child: Container(
            color: Colors.white,
            child: SafeArea(
              child: Column(
                children: [
                  _sidebarBrand(collapsed, isMobileDrawer),
                  const Divider(height: 1, color: _border),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12, vertical: 8),
                      children: menu,
                    ),
                  ),
                  const Divider(height: 1, color: _border),
                  _sidebarFooter(collapsed),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // BRAND + COLLAPSE BUTTON
  // ----------------------------------------------------------

  Widget _sidebarBrand(bool collapsed, bool isMobileDrawer) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
        child: Column(
          children: [
            const AdminBrandLogo(size: 42),
            const SizedBox(height: 12),
            _collapseButton(),
          ],
        ),
      );
    }

    // same as the web: logo + "Sandhya Salary"
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, isMobileDrawer ? 16 : 12, 16),
      child: Row(
        children: [
          const AdminBrandLogo(size: 42),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sandhya Salary',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (!isMobileDrawer) ...[
            const SizedBox(width: 8),
            _collapseButton(),
          ],
        ],
      ),
    );
  }

  /// Small bordered square button. The arrow rotates when the sidebar
  /// opens / closes.
  Widget _collapseButton() {
    return Tooltip(
      message: _isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: const BorderSide(color: _border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          hoverColor: _primaryTint,
          onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: AnimatedRotation(
                turns: _isSidebarCollapsed ? 0.5 : 0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                child: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF6B7280)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SECTIONS + ITEMS
  // ----------------------------------------------------------

  Widget _drawerSection(String title, {bool first = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, first ? 6 : 16, 12, 6),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.9)),
    );
  }

  Widget _sectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Divider(height: 1, color: Color(0xFFEDEFF3)),
    );
  }

  Widget _sidebarTile(_SideItem item, bool collapsed, int order) {
    final selected = item.selectedIndex != null && _selectedScreenIndex == item.selectedIndex;

    final Widget tile;

    if (collapsed) {
      // Icon-only
      tile = Tooltip(
        message: item.title,
        waitDuration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: selected ? _primaryTint : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              hoverColor: const Color(0xFFF3F4F6),
              onTap: item.onTap,
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Icon(item.icon, size: 22, color: selected ? _primary : const Color(0xFF1F2937)),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Icon + label, with an accent bar on the selected item
      tile = Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Material(
          color: selected ? _primaryTint : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: const Color(0xFFF3F4F6),
            onTap: item.onTap,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: 3,
                    height: selected ? 18 : 0,
                    decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 9),
                  Icon(item.icon, size: 22, color: selected ? _primary : const Color(0xFF1F2937)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? _primary : const Color(0xFF111827),
                      ),
                      child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Slide-in + fade. Replays when the sidebar opens (drawer opens, or
    // expands from collapsed) because the key changes with the layout.
    return TweenAnimationBuilder<double>(
      key: ValueKey('${item.title}-$collapsed'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + order * 40),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * -14, 0),
            child: child,
          ),
        );
      },
      child: tile,
    );
  }

  // ----------------------------------------------------------
  // FOOTER (profile + logout)
  // ----------------------------------------------------------

  Widget _sidebarFooter(bool collapsed) {
    final avatar = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: _primaryTint, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(
        _me.initials,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _primary),
      ),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(message: '${_me.name} · ${_me.roleLabel}', child: avatar),
            const SizedBox(height: 6),
            IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              icon: const Icon(Icons.logout_outlined, size: 20, color: Color(0xFF374151)),
            ),
          ],
        ),
      );
    }

    // name of the person who logged in + their role (Company Owner, HR Admin ...)
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
        decoration: BoxDecoration(
          color: _pageBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDEFF3)),
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _me.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _me.roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.logout_outlined, size: 20, color: Color(0xFF374151)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Future<void> _logout() async {
    if (_isMobile) Navigator.pop(context);
    await SecureStorage.clearSession();

    // MY SPACE: the next person must never see this person's attendance data
    EmpDashboardScreen.clearCache();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }
}

// =================================================================
// SIDEBAR DATA
// =================================================================

class _SideSection {
  final String title;
  final List<_SideItem> items;
  const _SideSection(this.title, this.items);
}

class _SideItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// Value of _selectedScreenIndex that makes this item look selected.
  /// null = opens a separate page, never shown as selected.
  final int? selectedIndex;

  const _SideItem(this.icon, this.title, this.onTap, {this.selectedIndex});
}