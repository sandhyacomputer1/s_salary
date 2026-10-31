import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import '../models/admin_employee_profile_models.dart';
import '../services/admin_employee_profile_service.dart';
import '../widgets/admin_employee_theme.dart';
import '../widgets/admin_profile_attendance_tab.dart';
import '../widgets/admin_profile_common.dart';
import '../widgets/admin_profile_expenses_tab.dart';
import '../widgets/admin_profile_header_card.dart';
import '../widgets/admin_profile_leave_tab.dart';
import '../widgets/admin_profile_overview_tab.dart';
import '../widgets/admin_profile_personal_tab.dart';
import '../widgets/admin_profile_salary_tab.dart';
import '../widgets/admin_profile_stat_cards.dart';
import '../widgets/admin_profile_tab_bar.dart';

/// Full employee profile (opened from the person icon in the directory).
/// Tabs: Overview | Attendance & Logs | Personal | Leave | Salary | Expenses
class AdminEmployeeProfileScreen extends StatefulWidget {
  final AdminEmployeeModel employee;

  /// true = shown inside the dashboard (sidebar + top bar stay visible), so no
  /// Scaffold / own top bar. [onBack] is called by "← All Employees".
  final bool embedded;
  final VoidCallback? onBack;

  const AdminEmployeeProfileScreen({
    super.key,
    required this.employee,
    this.embedded = false,
    this.onBack,
  });

  static Future<void> open(BuildContext context, AdminEmployeeModel employee) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminEmployeeProfileScreen(employee: employee)),
    );
  }

  @override
  State<AdminEmployeeProfileScreen> createState() => _AdminEmployeeProfileScreenState();
}

class _AdminEmployeeProfileScreenState extends State<AdminEmployeeProfileScreen> {
  final AdminEmployeeProfileService _service = AdminEmployeeProfileService();

  int _tab = 0;
  int _reloadKey = 0;

  bool _loadingTop = true;
  AdminAttendanceSummary _summary = const AdminAttendanceSummary();
  AdminProfileExtra _extra = const AdminProfileExtra();

  @override
  void initState() {
    super.initState();
    _loadTop();
  }

  Future<T?> _safe<T>(Future<T> f) async {
    try {
      return await f;
    } catch (_) {
      return null;
    }
  }

  /// Summary (stat cards + overview) and company info for the current month.
  Future<void> _loadTop() async {
    setState(() => _loadingTop = true);
    final now = DateTime.now();
    final id = widget.employee.id;

    final results = await Future.wait([
      _safe(_service.getAttendanceSummary(id, now.month, now.year)),
      _safe(_service.getExtra(id)),
    ]);

    if (!mounted) return;
    setState(() {
      _summary = (results[0] as AdminAttendanceSummary?) ?? const AdminAttendanceSummary();
      _extra = (results[1] as AdminProfileExtra?) ?? const AdminProfileExtra();
      _loadingTop = false;
    });
  }

  void _refresh() {
    setState(() => _reloadKey++);
    _loadTop();
  }

  // ------------------------------------------------------------
  // build
  // ------------------------------------------------------------

  void _back() {
    if (widget.embedded) {
      widget.onBack?.call();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    final pad = wide ? 30.0 : 14.0;

    final scroll = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 18, pad, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: _back,
                style: TextButton.styleFrom(
                  foregroundColor: AdminEmpColors.muted,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  'All Employees',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              // inside the dashboard the top bar has no refresh for this page
              if (widget.embedded)
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _refresh,
                  icon: _loadingTop
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AdminEmpColors.primary),
                  )
                      : const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AdminProfileHeaderCard(employee: widget.employee, extra: _extra),
          const SizedBox(height: 24),
          AdminProfileStatCards(summary: _summary),
          const SizedBox(height: 26),
          AdminProfileTabBar(
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: ValueKey('$_tab-$_reloadKey'),
            child: _tabBody(),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return Container(color: AdminEmpColors.bg, child: scroll);
    }

    return Scaffold(
      backgroundColor: AdminEmpColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(wide),
            Expanded(child: scroll),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool wide) {
    final now = DateTime.now();

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: wide ? 30 : 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          if (!wide)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          if (wide)
            const Text(
              'Company Admin',
              style: TextStyle(fontSize: 15.5, color: AdminEmpColors.muted),
            ),
          if (wide)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('/', style: TextStyle(fontSize: 15.5, color: AdminEmpColors.muted)),
            ),
          Expanded(
            child: Text(
              widget.employee.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AdminEmpColors.text,
              ),
            ),
          ),
          if (wide) ...[
            Text(
              adminEmpFormatDate(now),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminEmpColors.text),
            ),
            const SizedBox(width: 12),
          ],
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: _loadingTop
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AdminEmpColors.primary),
            )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _tabBody() {
    switch (_tab) {
      case 1:
        return AdminProfileAttendanceTab(employee: widget.employee, service: _service);
      case 2:
        return AdminProfilePersonalTab(employee: widget.employee);
      case 3:
        return AdminProfileLeaveTab(employee: widget.employee, service: _service);
      case 4:
        return AdminProfileSalaryTab(employee: widget.employee, service: _service);
      case 5:
        return AdminProfileExpensesTab(employee: widget.employee, service: _service);
      default:
        return AdminProfileOverviewTab(
          employee: widget.employee,
          summary: _summary,
          extra: _extra,
        );
    }
  }
}