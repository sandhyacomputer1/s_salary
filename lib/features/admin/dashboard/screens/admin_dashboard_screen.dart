import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import '../../../../data/services/leave_service.dart';
import '../../../../data/services/expense_service.dart';
import '../../attendance_notifications/widgets/check_in_out_notifications_screen.dart';
import '../../audit_trail/screens/audit_trail_screen.dart';
import '../../branches/screens/branches_screen.dart';
import '../../departments/screens/department_screen.dart';
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
    await _loadDashboardData();
  }

  /// Loads the licence data (start date, valid until, duration).
  Future<void> _loadLicense() async {
    final info = await LicenseInfo.fetch();
    if (!mounted) return;
    setState(() => _license = info);
  }

  /// The number shown on the red badge of the bell icon.
  int get _notificationCount => adminNotificationCount(
    license: _license,
    pendingLeaves: _pendingLeaves,
    pendingExpenses: _pendingExpenses,
  );

  /// Opens the notifications panel under the bell icon.
  Future<void> _openNotificationsPanel() {
    return showAdminNotificationsPanel(
      context,
      license: _license,
      pendingLeaves: _pendingLeaves,
      pendingExpenses: _pendingExpenses,
      // "View all notifications" -> the check-in / check-out notifications screen
      onViewAll: () => _goTo(8),
      // tapping the pending cards opens Leaves / Expenses
      onOpenLeaves: () => _goTo(3),
      onOpenExpenses: () => _goTo(7),
    );
  }

  /// Switches the screen WITHOUT touching the drawer.
  void _goTo(int index) {
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

  Widget _buildBodyContent() {
    if (_selectedScreenIndex == 1) {
      return AdminEmployeesScreen(
        key: ValueKey('employees-$_employeesResetKey'),
        embedded: true,
        initialProfile: _pendingProfile,
      );
    }
    if (_selectedScreenIndex == 2) return const CalendarScreen(embedded: true);
    if (_selectedScreenIndex == 3) return const LeaveScreen(embedded: true);
    if (_selectedScreenIndex == 4) return const ShiftRosterScreen(embedded: true);
    if (_selectedScreenIndex == 5) return const FieldTrackingScreen(embedded: true);
    if (_selectedScreenIndex == 6) return const DepartmentScreen(embedded: true);
    if (_selectedScreenIndex == 7) return const ExpenseScreen(embedded: true);
    if (_selectedScreenIndex == 8) return const CheckInOutNotificationsScreen(embedded: true);
    if (_selectedScreenIndex == 9) return const AuditTrailScreen(embedded: true);
    if (_selectedScreenIndex == 10) return const PayrollScreen(embedded: true);
    if (_selectedScreenIndex == 11) return const BranchesScreen(embedded: true);
    if (_selectedScreenIndex == 12) return const TeamRolesScreen(embedded: true);
    if (_selectedScreenIndex == 13) return const SettingsScreen(embedded: true);
    if (_selectedScreenIndex == 14) return const ReportsMainScreen();

    // Overview (matches the web dashboard)
    return AdminOverviewScreen(
      key: ValueKey('overview-$_overviewReload'),
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
  List<_SideSection> _sidebarSections() {
    return [
      _SideSection('OVERVIEW', [
        _SideItem(Icons.dashboard_outlined,
            'Overview', () => _onNavigationSelected(0),
            selectedIndex: 0
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
    final logo = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: _primaryTint, borderRadius: BorderRadius.circular(11)),
      child: const Icon(Icons.account_balance_wallet_outlined, color: _primary, size: 22),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
        child: Column(
          children: [
            logo,
            const SizedBox(height: 12),
            _collapseButton(),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, isMobileDrawer ? 16 : 12, 16),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('S Salary', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark)),
                SizedBox(height: 2),
                Text('Company Admin', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Color(0xFF8A93A1))),
              ],
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
      child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF98A1AF), letterSpacing: 0.8)),
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
                  child: Icon(item.icon, size: 20, color: selected ? _primary : const Color(0xFF596273)),
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
              height: 42,
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
                  Icon(item.icon, size: 20, color: selected ? _primary : const Color(0xFF596273)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? _primary : const Color(0xFF374151),
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: _primaryTint, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.person_outline_rounded, color: _primary, size: 20),
    );

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: 6),
            IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              icon: const Icon(Icons.logout_outlined, size: 19, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        decoration: BoxDecoration(
          color: _pageBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDEFF3)),
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
                  SizedBox(height: 2),
                  Text('Company Owner', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Color(0xFF8A93A1))),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.logout_outlined, size: 19, color: Color(0xFF6B7280)),
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