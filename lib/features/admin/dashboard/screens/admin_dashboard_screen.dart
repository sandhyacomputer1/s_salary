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
import '../../employees/screens/admin_employees_screen.dart';
import '../../expenses/screens/expense_screen.dart';
import '../../field_tracking/screens/field_tracking_screen.dart';
import '../../payroll/screens/payroll_screen.dart';
import '../../reports/widgets/reports_main_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../shift_roster/screens/shift_roster_screen.dart';
import '../../employees/screens/add_employee_screen.dart';
import '../../employees/screens/employee_details_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../leaves/screens/leave_screen.dart';
import '../../team_roles/screens/team_roles_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/admin_notifications_panel/admin_notifications_panel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {

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
  List<Employee> _employees = [];
  List<Employee> _archivedEmployees = [];
  int _pendingLeaves = 0;
  int _pendingExpenses = 0;
  LicenseInfo? _license; // NEW: data for the "Software Expiry Details" card


  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // SIDEBAR & NAVIGATION STATE
  bool _isSidebarCollapsed = false;
  int _selectedScreenIndex = 0;

  // CLOCK
  Timer? _clockTimer;
  String _currentDate = '';
  String _currentTime = '';

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _updateDateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _updateDateTime(),
    );
    _loadDashboardData();
    _loadLicense(); // NEW

    // Ask for permissions as soon as the dashboard is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestStartupPermissions();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _entranceController.dispose();
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
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final employeeResults = await Future.wait([
        _employeeService.getEmployees(status: 'active'),
        _employeeService.getArchivedEmployees(),
      ]);
      final activeEmployees = employeeResults[0] as List<Employee>;
      final archivedEmployees = employeeResults[1] as List<Employee>;

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
        _employees = activeEmployees;
        _archivedEmployees = archivedEmployees;
        _pendingLeaves = pendingLeaveCount;
        _pendingExpenses = pendingExpenseCount;
        _isLoading = false;
        _isRefreshing = false;
      });
      _entranceController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _loadLicense(); // NEW
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
      onViewAll: () => setState(() => _selectedScreenIndex = 8),
      // tapping the pending cards opens Leaves / Expenses
      onOpenLeaves: () => setState(() => _selectedScreenIndex = 3),
      onOpenExpenses: () => setState(() => _selectedScreenIndex = 7),
    );
  }
  void _onNavigationSelected(int index) {
    if (_isMobile) Navigator.pop(context); // Close drawer on mobile
    setState(() => _selectedScreenIndex = index);
  }

  /// Opens a full page from the sidebar (closes the drawer first on phone).
  void _pushScreen(Widget screen) {
    if (_isMobile) Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
        ),        const SizedBox(width: 10),
      ],
    );
  }
  Widget _buildBodyContent() {
    if (_selectedScreenIndex == 1) return const AdminEmployeesScreen(embedded: true);
    if (_selectedScreenIndex == 2) return const CalendarScreen(embedded: true);
    if (_selectedScreenIndex == 3) return const LeaveScreen(embedded: true);
    if (_selectedScreenIndex == 4) return const ShiftRosterScreen(embedded: true); // Add this
    if (_selectedScreenIndex == 5) return const FieldTrackingScreen(embedded: true); // Add this
    if (_selectedScreenIndex == 6) return const DepartmentScreen(embedded: true); // Add this
    if (_selectedScreenIndex == 7) return const ExpenseScreen(embedded: true); // Add this
    if (_selectedScreenIndex == 8) return const CheckInOutNotificationsScreen(embedded: true);
    if (_selectedScreenIndex == 9) return const AuditTrailScreen(embedded: true);
    if (_selectedScreenIndex == 10) return const PayrollScreen(embedded: true); // Add this
    if (_selectedScreenIndex == 11) return const BranchesScreen(embedded: true);
    if (_selectedScreenIndex == 12) return const TeamRolesScreen(embedded: true);
    if (_selectedScreenIndex == 13) return const SettingsScreen(embedded: true); // Add this
    if (_selectedScreenIndex == 14) return const ReportsMainScreen();

    return _buildOverviewDashboard();
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
                () => _onNavigationSelected(1), // Changed from _openEmployeesFromDrawer to _onNavigationSelected(1)
            selectedIndex: 1
        ),

        _SideItem(
            Icons.calendar_month_outlined,
            'Calendar',
                () => _onNavigationSelected(2), // Changed from _pushScreen
            selectedIndex: 2
        ),

        _SideItem(
            Icons.schedule_outlined,
            'Shift Roster',
                () => _onNavigationSelected(4), // Changed from _pushScreen
            selectedIndex: 4
        ),

        _SideItem(
            Icons.location_on_outlined,
            'Field Tracking',
                () => _onNavigationSelected(5), // Changed from _pushScreen
            selectedIndex: 5
        ),

        // ✅ CHANGED THIS LINE:
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
                () => _onNavigationSelected(10), // Changed from _pushScreen
            selectedIndex: 10
        ),

        _SideItem(
            Icons.receipt_long_outlined,
            'Expenses',
                () => _onNavigationSelected(7), // Changed from _pushScreen
            selectedIndex: 7
        ),
      ]),

      _SideSection('COMPANY & SECURITY', [

        _SideItem(
            Icons.business_outlined,
            'Branches',
                () => _onNavigationSelected(11), // Was _pushScreen
            selectedIndex: 11
        ),

        _SideItem(
            Icons.admin_panel_settings_outlined,
            'Team & Roles',
                () => _onNavigationSelected(12), // Was _pushScreen
            selectedIndex: 12
        ),

        _SideItem(
            Icons.settings_outlined,
            'Settings',
                () => _onNavigationSelected(13), // Changed from _pushScreen
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
  // OVERVIEW DASHBOARD CONTENT
  // ==========================================================

  Widget _buildOverviewDashboard() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return _buildErrorState();

    final mobile = _isMobile;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(mobile ? 14 : 22, mobile ? 16 : 22, mobile ? 14 : 22, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            SizedBox(height: mobile ? 16 : 24),
            _buildSummaryCards(),
            SizedBox(height: mobile ? 18 : 28),
            _staggeredIn(4, _buildInsightsSection(mobile)),
            SizedBox(height: mobile ? 18 : 28),
            _buildEmployeeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    final mobile = _isMobile;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company Dashboard', style: TextStyle(fontSize: mobile ? 22 : 27, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 6),
        Text('Manage your workforce and company activities.', style: TextStyle(fontSize: mobile ? 13 : 14, color: Colors.grey.shade600)),
      ],
    );

    if (mobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titleBlock, const SizedBox(height: 12), _buildDateTimeChip(compact: true)]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
          child: Row(children: [
            const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 7),
            Text('Live dashboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          ]),
        ),
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

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < _mobileBreakpoint;
        final columns = width >= 1100 ? 4 : 2;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: compact ? 10 : 16,
            mainAxisSpacing: compact ? 10 : 16,
            mainAxisExtent: compact ? 84 : 104,
          ),
          children: [
            _staggeredIn(0, _DashboardSummaryCard(title: 'Active Employees', value: _employees.length.toString(), icon: Icons.people_outline_rounded, accent: const Color(0xFFE96832), highlighted: true, compact: compact)),
            _staggeredIn(1, _DashboardSummaryCard(title: 'Pending Leaves', value: _pendingLeaves.toString(), icon: Icons.event_note_outlined, accent: const Color(0xFFE8A317), compact: compact)),
            _staggeredIn(2, _DashboardSummaryCard(title: 'Pending Expenses', value: _pendingExpenses.toString(), icon: Icons.receipt_long_outlined, accent: const Color(0xFF7A5AF8), compact: compact)),
            _staggeredIn(3, _DashboardSummaryCard(title: 'Archived Employees', value: _archivedEmployees.length.toString(), icon: Icons.person_off_outlined, accent: const Color(0xFF64748B), compact: compact)),
          ],
        );
      },
    );
  }

  Widget _buildInsightsSection(bool mobile) {
    final snapshot = _buildCardShell(
      mobile: mobile,
      title: 'Workforce Snapshot',
      subtitle: 'Active employees, leaves, expenses & archive at a glance',
      icon: Icons.insights_outlined,
      child: _buildSnapshotChart(mobile),
    );

    final departments = _buildCardShell(
      mobile: mobile,
      title: 'Employees by Department',
      subtitle: _employees.isEmpty ? 'No active employees yet' : 'Top ${_departmentBreakdown().length} departments by headcount',
      icon: Icons.account_tree_outlined,
      child: _buildDepartmentChart(mobile),
    );

    final quickActions = _buildQuickActions(mobile);

    if (mobile) {
      return Column(children: [snapshot, const SizedBox(height: 14), departments, const SizedBox(height: 14), quickActions]);
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: snapshot),
              const SizedBox(width: 16),
              Expanded(child: departments),
            ],
          ),
        ),
        const SizedBox(height: 16),
        quickActions,
      ],
    );
  }

  Widget _buildCardShell({required bool mobile, required String title, required String subtitle, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFFFEEE7), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 18, color: _primary)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                ])),
              ],
            ),
            SizedBox(height: mobile ? 16 : 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotChart(bool mobile) {
    final metrics = <_MetricData>[
      _MetricData(label: 'Active Employees', value: _employees.length, icon: Icons.people_outline_rounded, color: const Color(0xFFE96832)),
      _MetricData(label: 'Pending Leaves', value: _pendingLeaves, icon: Icons.event_note_outlined, color: const Color(0xFFE8A317)),
      _MetricData(label: 'Pending Expenses', value: _pendingExpenses, icon: Icons.receipt_long_outlined, color: const Color(0xFF7A5AF8)),
      _MetricData(label: 'Archived Employees', value: _archivedEmployees.length, icon: Icons.person_off_outlined, color: const Color(0xFF64748B)),
    ];

    var maxValue = 1;
    for (final metric in metrics) {
      if (metric.value > maxValue) maxValue = metric.value;
    }

    if (mobile) {
      return Column(
        children: [
          Row(children: [Expanded(child: _buildGaugeTile(metrics[0], maxValue, mobile)), Expanded(child: _buildGaugeTile(metrics[1], maxValue, mobile))]),
          const SizedBox(height: 20),
          Row(children: [Expanded(child: _buildGaugeTile(metrics[2], maxValue, mobile)), Expanded(child: _buildGaugeTile(metrics[3], maxValue, mobile))]),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      runSpacing: 20,
      children: metrics.map((metric) => SizedBox(width: 150, child: _buildGaugeTile(metric, maxValue, mobile))).toList(),
    );
  }

  Widget _buildGaugeTile(_MetricData metric, int maxValue, bool mobile) {
    final fraction = maxValue == 0 ? 0.0 : metric.value / maxValue;
    final size = mobile ? 84.0 : 92.0;

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, animatedFraction, _) {
            return SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _RingGaugePainter(fraction: animatedFraction, color: metric.color, trackColor: _pageBg, strokeWidth: 8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(metric.icon, size: 17, color: metric.color),
                      const SizedBox(height: 3),
                      Text(metric.value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(metric.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      ],
    );
  }

  static const List<Color> _departmentPalette = [Color(0xFFE96832), Color(0xFF2878FF), Color(0xFF18864B), Color(0xFF7A5AF8), Color(0xFFE8A317), Color(0xFFC62828)];

  Widget _buildDepartmentChart(bool mobile) {
    final breakdown = _departmentBreakdown();

    if (breakdown.isEmpty) {
      return _emptyChartPlaceholder('No department data yet — add employees to see the breakdown here.');
    }

    final total = breakdown.fold<int>(0, (sum, e) => sum + e.value);
    final segments = <double>[];
    final colors = <Color>[];

    for (var i = 0; i < breakdown.length; i++) {
      segments.add(breakdown[i].value.toDouble());
      colors.add(_departmentPalette[i % _departmentPalette.length]);
    }

    final donut = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return SizedBox(
          width: 152,
          height: 152,
          child: CustomPaint(
            painter: _DonutPainter(values: segments, colors: colors, trackColor: _pageBg, strokeWidth: 18, progress: progress),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(total.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _textDark)),
                  Text('Employees', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        );
      },
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < breakdown.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == breakdown.length - 1 ? 0 : 10),
            child: Row(
              children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
                const SizedBox(width: 9),
                Expanded(child: Text(breakdown[i].key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _textDark))),
                const SizedBox(width: 8),
                Text('${breakdown[i].value}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors[i])),
                const SizedBox(width: 6),
                Text('(${total == 0 ? 0 : (breakdown[i].value * 100 / total).round()}%)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
      ],
    );

    if (mobile) {
      return Column(children: [donut, const SizedBox(height: 18), legend]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [donut, const SizedBox(width: 24), Expanded(child: legend)],
    );
  }

  Widget _emptyChartPlaceholder(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600))),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool mobile) {
    final actions = [
      ('Add Employee', Icons.person_add_alt_1_rounded, _openAddEmployee),
      ('View All Employees', Icons.people_alt_outlined, _openEmployees),
      ('Refresh Data', Icons.refresh_rounded, _isLoading ? null : _refreshDashboard),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions.map((action) {
          final (label, icon, onTap) = action;
          return OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 17),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textDark,
              side: const BorderSide(color: Color(0xFFD9DEE7)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmployeeSection() {
    final mobile = _isMobile;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmployeeSectionHeader(mobile),
            SizedBox(height: mobile ? 14 : 20),
            const Divider(height: 1),
            const SizedBox(height: 4),
            if (_employees.isEmpty)
              _buildEmptyEmployees()
            else if (mobile)
              _buildEmployeeList()
            else
              _buildEmployeeTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSectionHeader(bool mobile) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Employees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 4),
        Text('${_employees.length} active employees in your company', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );

    final viewAllButton = OutlinedButton.icon(
      onPressed: _openEmployees,
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: const Text('View All'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD9DEE7)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    final addButton = FilledButton.icon(
      onPressed: _openAddEmployee,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
      label: const Text('Add Employee'),
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleBlock, const SizedBox(height: 14), Row(children: [Expanded(child: viewAllButton), const SizedBox(width: 10), Expanded(child: addButton)])],
      );
    }

    return Row(children: [Expanded(child: titleBlock), viewAllButton, const SizedBox(width: 10), addButton]);
  }

  Widget _buildEmployeeList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _employees.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEDEFF3)),
      itemBuilder: (context, index) {
        final employee = _employees[index];
        return InkWell(
          onTap: () => _openEmployeeDetails(employee),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _buildAvatar(employee.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name.trim().isEmpty ? 'Unnamed Employee' : employee.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                      const SizedBox(height: 3),
                      Text('${_displayValue(employee.employeeCode)}  •  ${_displayValue(employee.department)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563))),
                      const SizedBox(height: 2),
                      Text(_displayValue(employee.phone), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF7A8494))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: employee.status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(_initials(name), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569)))),
    );
  }

  Widget _buildEmployeeTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth < 850 ? 850 : constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 48,
              dataRowMinHeight: 68,
              dataRowMaxHeight: 72,
              horizontalMargin: 8,
              columnSpacing: 28,
              dividerThickness: 0.6,
              headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7B8493), letterSpacing: 0.4),
              columns: const [
                DataColumn(label: Text('EMPLOYEE')),
                DataColumn(label: Text('CODE')),
                DataColumn(label: Text('DEPARTMENT')),
                DataColumn(label: Text('MOBILE')),
                DataColumn(label: Text('STATUS')),
              ],
              rows: _employees.map((employee) {
                return DataRow(
                  onSelectChanged: (_) => _openEmployeeDetails(employee),
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 210,
                        child: Row(
                          children: [
                            Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(9)), child: Center(child: Text(_initials(employee.name), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569))))),
                            const SizedBox(width: 11),
                            Expanded(child: Text(employee.name.trim().isEmpty ? 'Unnamed Employee' : employee.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)))),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(_displayValue(employee.employeeCode), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)))),
                    DataCell(Text(_displayValue(employee.department), style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
                    DataCell(Text(_displayValue(employee.phone), style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
                    DataCell(_StatusBadge(status: employee.status)),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyEmployees() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.people_outline_rounded, size: 32, color: Color(0xFF94A3B8))),
          const SizedBox(height: 14),
          const Text('No active employees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Add your first employee to get started.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: _openAddEmployee, icon: const Icon(Icons.person_add_alt_1_rounded, size: 17), label: const Text('Add Employee'), style: FilledButton.styleFrom(backgroundColor: _primary)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 62, height: 62, decoration: BoxDecoration(color: const Color(0xFFFFF1F1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFDC2626))),
            const SizedBox(height: 16),
            const Text('Unable to load dashboard', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'Something went wrong.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _loadDashboardData, icon: const Icon(Icons.refresh_rounded), label: const Text('Try Again'), style: FilledButton.styleFrom(backgroundColor: _primary)),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HELPERS & ACTIONS
  // ==========================================================

  Future<void> _openEmployeesFromDrawer() async {
    if (_isMobile) Navigator.pop(context);
    await _openEmployees();
  }

  Future<void> _openEmployees() async {
    await Navigator.pushNamed(context, AppRoutes.employees);
    await _loadDashboardData();
  }

  Future<void> _openEmployeeDetails(Employee employee) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeDetailsScreen(employee: employee)));
    await _loadDashboardData();
  }

  Future<void> _openAddEmployee() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen()));
    if (result == true) await _loadDashboardData();

  }

  Future<void> _logout() async {
    if (_isMobile) Navigator.pop(context);
    await SecureStorage.clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
  }

  String _displayValue(String value) => value.trim().isEmpty ? '—' : value;

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  List<MapEntry<String, int>> _departmentBreakdown() {
    final counts = <String, int>{};
    for (final employee in _employees) {
      final department = employee.department.trim();
      final key = department.isEmpty ? 'Unassigned' : department;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(6).toList();
  }

  Widget _staggeredIn(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.7);
    final animation = CurvedAnimation(parent: _entranceController, curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: animation,
      builder: (context, builtChild) => Opacity(opacity: animation.value.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, (1 - animation.value) * 16), child: builtChild)),
      child: child,
    );
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

// =================================================================
// HELPER CLASSES
// =================================================================

class _DashboardSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final bool highlighted;
  final bool compact;

  const _DashboardSummaryCard({required this.title, required this.value, required this.icon, required this.accent, this.highlighted = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final iconBox = compact ? 38.0 : 48.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Stack(
        children: [
          if (highlighted)
            Positioned(left: 0, top: 0, bottom: 0, width: 4, child: Container(decoration: const BoxDecoration(color: Color(0xFFE96832), borderRadius: BorderRadius.only(topLeft: Radius.circular(13), bottomLeft: Radius.circular(13))))),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(width: iconBox, height: iconBox, decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(compact ? 10 : 12)), child: Icon(icon, size: compact ? 20 : 24, color: accent)),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value, style: TextStyle(fontSize: compact ? 21 : 25, fontWeight: FontWeight.w700, height: 1.1, color: const Color(0xFF18212F))),
                        SizedBox(height: compact ? 2 : 3),
                        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 11.5 : 12, height: 1.2, fontWeight: FontWeight.w500, color: const Color(0xFF7A8494))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final isActive = normalized == 'active';
    final label = status.trim().isEmpty ? 'N/A' : status;
    final background = isActive ? const Color(0xFFE9F8EF) : const Color(0xFFFDECEC);
    final foreground = isActive ? const Color(0xFF18864B) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: foreground, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label[0].toUpperCase() + label.substring(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground)),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _MetricData({required this.label, required this.value, required this.icon, required this.color});
}

class _RingGaugePainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  _RingGaugePainter({required this.fraction, required this.color, required this.trackColor, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final trackPaint = Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);
    if (fraction <= 0) return;
    final progressPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    const startAngle = -3.14159265 / 2;
    final sweepAngle = 2 * 3.14159265 * fraction.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingGaugePainter oldDelegate) => oldDelegate.fraction != fraction || oldDelegate.color != color || oldDelegate.trackColor != trackColor || oldDelegate.strokeWidth != strokeWidth;
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color trackColor;
  final double strokeWidth;
  final double progress;
  _DonutPainter({required this.values, required this.colors, required this.trackColor, required this.strokeWidth, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const twoPi = 2 * 3.14159265;
    const startAngle = -3.14159265 / 2;
    final trackPaint = Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0 || progress <= 0) return;
    final revealedSweep = twoPi * progress.clamp(0.0, 1.0);
    var cursor = 0.0;
    for (var i = 0; i < values.length; i++) {
      final segmentSweep = twoPi * (values[i] / total);
      final drawSweep = (revealedSweep - cursor).clamp(0.0, segmentSweep);
      if (drawSweep > 0) {
        final segmentPaint = Paint()..color = colors[i % colors.length]..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.butt;
        canvas.drawArc(rect, startAngle + cursor, drawSweep, false, segmentPaint);
      }
      cursor += segmentSweep;
      if (cursor >= revealedSweep) break;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.values != values || oldDelegate.colors != colors || oldDelegate.trackColor != trackColor || oldDelegate.strokeWidth != strokeWidth;
}