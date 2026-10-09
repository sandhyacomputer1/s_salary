import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/secure_storage.dart';
import 'emp_dashboard_screen.dart';
import '../../leave/screens/emp_apply_leave_screen.dart';
import '../../daily_report/screens/emp_daily_report_screen.dart';

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
  static const Color border = Color(0xFFE1E5EA);
  static const Color sidebarBg = Color(0xFFFFFFFF);

  static const double _railBreakpoint = 900;

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

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const EmpDashboardScreen();
      case 1:
        return const EmpDailyReportScreen(embedded: true);
      case 2:
        return const EmpApplyLeaveScreen(embedded: true);
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _railBreakpoint;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                _buildSidebar(isDrawer: false),
                Expanded(child: _buildScreen(_selectedIndex)),
              ],
            ),
          );
        }

        return Scaffold(
          drawer: Drawer(
            width: 280,
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
                fontSize: 16,
              ),
            ),
          ),
          body: _buildScreen(_selectedIndex),
        );
      },
    );
  }

  Widget _buildSidebar({required bool isDrawer}) {
    return Container(
      width: isDrawer ? null : 260,
      color: sidebarBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sandhya Salary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = index == _selectedIndex;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: isSelected ? primaryLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _onSelect(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: 19,
                                color: isSelected ? primary : textMedium,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected ? primary : textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: border),
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
                        Icon(
                          Icons.logout_rounded,
                          size: 19,
                          color: Color(0xFFD64545),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD64545),
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
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.icon, this.activeIcon);
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