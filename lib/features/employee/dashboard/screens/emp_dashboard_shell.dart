import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../attendance/screens/employee_attendance_screen.dart';
import '../../profile/screens/employee_profile_screen.dart';
import '../../salary/screens/employee_salary_screen.dart';
import 'emp_dashboard_screen.dart';
import '../../leave/screens/emp_apply_leave_screen.dart';
import '../../daily_report/screens/emp_daily_report_screen.dart';
import '../../expense_claims/screens/employee_submit_expense_claim_screen.dart';

class EmpDashboardShell extends StatefulWidget {
  const EmpDashboardShell({super.key});

  @override
  State<EmpDashboardShell> createState() => _EmpDashboardShellState();
}

class _EmpDashboardShellState extends State<EmpDashboardShell> {
  int _selectedIndex = 0;

  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFEEE7);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE5E7EB);
  static const Color pageBg = Color(0xFFF7F8FA);
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFD64545);

  static const double _railBreakpoint = 900;

  // Index of each item must match the switch in _buildScreen.
  static const List<_NavItem> _navItems = [
    _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _NavItem('Daily Work Report', Icons.assignment_outlined,
        Icons.assignment_rounded),
    _NavItem('Apply Leave', Icons.event_note_outlined,
        Icons.event_note_rounded),
    _NavItem('Attendance Calendar', Icons.calendar_month_outlined,
        Icons.calendar_month_rounded),
    _NavItem('Field GPS Tracking', Icons.location_on_outlined,
        Icons.location_on_rounded),
    _NavItem('Expense Claims', Icons.receipt_long_outlined,
        Icons.receipt_long_rounded),
    _NavItem('My Salary', Icons.currency_rupee_outlined,
        Icons.currency_rupee_rounded),
    _NavItem('My Profile', Icons.person_outline_rounded,
        Icons.person_rounded),
  ];

  // Sidebar parts. Each section lists indexes of _navItems.
  static const List<_NavSection> _sections = [
    _NavSection('OVERVIEW', [0]),
    _NavSection('WORK', [1, 2, 3, 4]),
    _NavSection('FINANCE', [5, 6]),
    _NavSection('ACCOUNT', [7]),
  ];

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const EmpDashboardScreen(embedded: true);
      case 1:
        return const EmpDailyReportScreen(embedded: true);
      case 2:
        return const EmpApplyLeaveScreen(embedded: true);
      case 3:
        return const EmployeeAttendanceScreen(embedded: true);
      case 5:
        return const EmployeeSubmitExpenseClaimScreen(embedded: true);
      case 6:
        return const EmployeeSalaryScreen(embedded: true);
      case 7:
        return const EmployeeProfileScreen(embedded: true);
      default:
        return _PlaceholderScreen(title: _navItems[index].label);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: primary),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await SecureStorage.clearSession();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  void _onSelect(int index) {
    setState(() => _selectedIndex = index);

    if (MediaQuery.of(context).size.width < _railBreakpoint) {
      Navigator.of(context).maybePop();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _railBreakpoint;

        if (isWide) {
          return Scaffold(
            backgroundColor: pageBg,
            body: Row(
              children: [
                _buildSidebar(isDrawer: false),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(),
                      Expanded(child: _buildContent()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: pageBg,
          drawer: Drawer(
            width: 280,
            backgroundColor: sidebarBg,
            child: _buildSidebar(isDrawer: true),
          ),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: textDark),
            title: Text(
              _navItems[_selectedIndex].label,
              style: const TextStyle(
                color: textDark,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: _buildContent(),
        );
      },
    );
  }

  /// Fades and slides the page in whenever the sidebar selection changes.
  Widget _buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) {
        return Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_selectedIndex),
        child: _buildScreen(_selectedIndex),
      ),
    );
  }

  // ==========================================================
  // TOP BAR (wide screens)
  // ==========================================================

  Widget _buildTopBar() {
    final item = _navItems[_selectedIndex];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(item.activeIcon, size: 18, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Align(
                key: ValueKey<int>(_selectedIndex),
                alignment: Alignment.centerLeft,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SIDEBAR
  // ==========================================================

  Widget _buildSidebar({required bool isDrawer}) {
    // Running counter so every tile gets its own entrance delay.
    var order = 0;

    final menu = <Widget>[];

    for (final section in _sections) {
      menu.add(_sectionHeader(section.title));

      for (final index in section.indices) {
        menu.add(_navTile(index, order));
        order++;
      }
    }

    return Container(
      width: isDrawer ? null : 260,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --------------------------------------------------
            // BRAND
            // --------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sandhya Salary',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Employee Portal',
                          style: TextStyle(fontSize: 11, color: textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: border),

            // --------------------------------------------------
            // MENU (grouped in parts)
            // --------------------------------------------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: menu,
              ),
            ),

            const Divider(height: 1, color: border),

            // --------------------------------------------------
            // LOGOUT
            // --------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _handleLogout,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 19, color: danger),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF98A1AF),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _navTile(int index, int order) {
    final item = _navItems[index];
    final isSelected = index == _selectedIndex;

    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _onSelect(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 11, 12, 11),
              child: Row(
                children: [
                  // Accent bar that grows in on the selected item.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 3,
                    height: isSelected ? 18 : 0,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey<bool>(isSelected),
                      size: 19,
                      color: isSelected ? primary : textMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? primary : textDark,
                      ),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Slide-in + fade when the sidebar first appears.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + order * 50),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * -16, 0),
            child: child,
          ),
        );
      },
      child: tile,
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.icon, this.activeIcon);
}

class _NavSection {
  final String title;
  final List<int> indices;

  const _NavSection(this.title, this.indices);
}

/// Placeholder shown for sidebar items whose screens aren't built yet.
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  static const Color textDark = Color(0xFF18212F);
  static const Color textLight = Color(0xFF8A93A1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction_rounded,
              size: 48,
              color: textLight,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coming soon',
              style: TextStyle(fontSize: 13, color: textLight),
            ),
          ],
        ),
      ),
    );
  }
}