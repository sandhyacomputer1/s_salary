import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import '../../../../data/services/leave_service.dart';
import '../../../../data/services/expense_service.dart';
import '../../shift_roster/screens/shift_roster_screen.dart';
import '../../employees/screens/add_employee_screen.dart';
import '../../employees/screens/employee_details_screen.dart';
import '../../calendar/screens/calendar_screen.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // BREAKPOINTS
  // ==========================================================

  /// Below this width the UI switches to the phone layout.
  static const double _mobileBreakpoint = 700;

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);

  // ==========================================================
  // SERVICES
  // ==========================================================

  final EmployeeService _employeeService = EmployeeService();

  final LeaveService _leaveService = LeaveService();

  final ExpenseService _expenseService = ExpenseService();

  // ==========================================================
  // DATA
  // ==========================================================

  List<Employee> _employees = [];

  List<Employee> _archivedEmployees = [];

  int _pendingLeaves = 0;

  int _pendingExpenses = 0;

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;

  bool _isRefreshing = false;

  String? _errorMessage;

  // ==========================================================
  // DATE / TIME
  // ==========================================================

  Timer? _clockTimer;

  String _currentDate = '';

  String _currentTime = '';

  // ==========================================================
  // ENTRANCE ANIMATION
  //
  // Cards and sections fade + slide in once data has loaded.
  // Runs again on every successful refresh.
  // ==========================================================

  late final AnimationController _entranceController;

  // ==========================================================
  // INIT
  // ==========================================================

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
          (_) {
        _updateDateTime();
      },
    );

    _loadDashboardData();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _clockTimer?.cancel();

    _entranceController.dispose();

    super.dispose();
  }

  // ==========================================================
  // DATE / TIME
  // ==========================================================

  void _updateDateTime() {
    final now = DateTime.now();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;

    final minute = now.minute.toString().padLeft(2, '0');

    final period = now.hour >= 12 ? 'PM' : 'AM';

    if (!mounted) {
      return;
    }

    setState(() {
      _currentDate = '${weekdays[now.weekday - 1]}, '
          '${now.day} '
          '${months[now.month - 1]} '
          '${now.year}';

      _currentTime = '$hour:$minute $period';
    });
  }

  // ==========================================================
  // LOAD DASHBOARD
  // ==========================================================

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // ------------------------------------------------------
      // 1. GET ACTIVE + ARCHIVED EMPLOYEES
      // ------------------------------------------------------

      final employeeResults = await Future.wait([
        _employeeService.getEmployees(
          status: 'active',
        ),
        _employeeService.getArchivedEmployees(),
      ]);

      final activeEmployees = employeeResults[0] as List<Employee>;

      final archivedEmployees = employeeResults[1] as List<Employee>;

      // ------------------------------------------------------
      // 2. PENDING LEAVES
      // ------------------------------------------------------

      int pendingLeaveCount = 0;

      // The API documentation exposes pendingApprovals
      // through each employee's leave balance.
      //
      // We sum the documented pendingApprovals values
      // for all active employees.

      if (activeEmployees.isNotEmpty) {
        final leaveResults = await Future.wait(
          activeEmployees.map(
                (employee) async {
              try {
                final balance = await _leaveService.getLeaveBalance(
                  employee.id,
                );

                final value = balance['pendingApprovals'];

                if (value is num) {
                  return value.toInt();
                }

                return int.tryParse(
                  value?.toString() ?? '',
                ) ??
                    0;
              } catch (_) {
                return 0;
              }
            },
          ),
        );

        for (final value in leaveResults) {
          pendingLeaveCount += value;
        }
      }

      // ------------------------------------------------------
      // 3. PENDING EXPENSES
      // ------------------------------------------------------

      int pendingExpenseCount = 0;

      if (activeEmployees.isNotEmpty) {
        final expenseResults = await Future.wait(
          activeEmployees.map(
                (employee) async {
              try {
                return await _expenseService.getPendingExpenseCount(
                  employee.id,
                );
              } catch (_) {
                return 0;
              }
            },
          ),
        );

        for (final value in expenseResults) {
          pendingExpenseCount += value;
        }
      }

      // ------------------------------------------------------
      // UPDATE UI
      // ------------------------------------------------------

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;

        _isRefreshing = false;

        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    await _loadDashboardData();
  }

  // ==========================================================
  // OPEN EMPLOYEE DETAILS
  // ==========================================================

  Future<void> _openEmployeeDetails(
      Employee employee,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailsScreen(
          employee: employee,
        ),
      ),
    );

    await _loadDashboardData();
  }

  // ==========================================================
  // OPEN ADD EMPLOYEE
  // ==========================================================

  Future<void> _openAddEmployee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEmployeeScreen(),
      ),
    );

    if (result == true) {
      await _loadDashboardData();
    }
  }

  // ==========================================================
  // OPEN EMPLOYEES
  // ==========================================================

  Future<void> _openEmployees() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.employees,
    );

    await _loadDashboardData();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  // ==========================================================
  // DATE / TIME CHIP
  // ==========================================================

  Widget _buildDateTimeChip({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 11 : 13,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: compact ? Colors.white : _pageBg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _currentDate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.access_time_outlined,
            size: 15,
            color: _primary,
          ),
          const SizedBox(width: 6),
          Text(
            _currentTime,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // APP BAR
  // ==========================================================

  PreferredSizeWidget _buildAppBar() {
    final mobile = _isMobile;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: mobile ? 4 : 20,
      title: Row(
        children: [
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
          const Text(
            'S Salary',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        // ----------------------------------------------------
        // DATE (desktop / tablet only, phone shows it in body)
        // ----------------------------------------------------

        if (!mobile) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: _buildDateTimeChip(),
          ),
          const SizedBox(width: 8),
        ],

        // ----------------------------------------------------
        // REFRESH
        // ----------------------------------------------------

        IconButton(
          tooltip: 'Refresh Dashboard',
          onPressed: _isLoading ? null : _refreshDashboard,
          icon: _isRefreshing
              ? const SizedBox(
            width: 19,
            height: 19,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Icon(Icons.refresh_rounded),
        ),

        // ----------------------------------------------------
        // NOTIFICATION
        // ----------------------------------------------------

        IconButton(
          tooltip: 'Notifications',
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),

        SizedBox(width: mobile ? 4 : 10),
      ],
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final mobile = _isMobile;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          mobile ? 14 : 22,
          mobile ? 16 : 22,
          mobile ? 14 : 22,
          35,
        ),
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

  // ==========================================================
  // PAGE HEADER
  // ==========================================================

  Widget _buildPageHeader() {
    final mobile = _isMobile;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Dashboard',
          style: TextStyle(
            fontSize: mobile ? 22 : 27,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage your workforce and company activities.',
          style: TextStyle(
            fontSize: mobile ? 13 : 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );

    // ------------------------------------------------------
    // PHONE: title, then date / time chip below
    // ------------------------------------------------------

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          _buildDateTimeChip(compact: true),
        ],
      );
    }

    // ------------------------------------------------------
    // DESKTOP / TABLET
    // ------------------------------------------------------

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.sync_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 7),
              Text(
                'Live dashboard',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SUMMARY CARDS
  // ==========================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final compact = width < _mobileBreakpoint;

        // 4 columns on wide screens, 2 on tablet AND phone
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
            _staggeredIn(
              0,
              _DashboardSummaryCard(
                title: 'Active Employees',
                value: _employees.length.toString(),
                icon: Icons.people_outline_rounded,
                accent: const Color(0xFFE96832),
                highlighted: true,
                compact: compact,
              ),
            ),
            _staggeredIn(
              1,
              _DashboardSummaryCard(
                title: 'Pending Leaves',
                value: _pendingLeaves.toString(),
                icon: Icons.event_note_outlined,
                accent: const Color(0xFFE8A317),
                compact: compact,
              ),
            ),
            _staggeredIn(
              2,
              _DashboardSummaryCard(
                title: 'Pending Expenses',
                value: _pendingExpenses.toString(),
                icon: Icons.receipt_long_outlined,
                accent: const Color(0xFF7A5AF8),
                compact: compact,
              ),
            ),
            _staggeredIn(
              3,
              _DashboardSummaryCard(
                title: 'Archived Employees',
                value: _archivedEmployees.length.toString(),
                icon: Icons.person_off_outlined,
                accent: const Color(0xFF64748B),
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // INSIGHTS SECTION
  //
  // Two charts built from data already fetched above — no
  // extra API calls. On wide screens they sit side by side;
  // on phones they stack.
  // ==========================================================

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
      subtitle: _employees.isEmpty
          ? 'No active employees yet'
          : 'Top ${_departmentBreakdown().length} departments by headcount',
      icon: Icons.account_tree_outlined,
      child: _buildDepartmentChart(mobile),
    );

    final quickActions = _buildQuickActions(mobile);

    if (mobile) {
      return Column(
        children: [
          snapshot,
          const SizedBox(height: 14),
          departments,
          const SizedBox(height: 14),
          quickActions,
        ],
      );
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

  Widget _buildCardShell({
    required bool mobile,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEE7),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 18, color: _primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: mobile ? 16 : 20),
            child,
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SNAPSHOT — 4 circular gauges, one per metric
  // ----------------------------------------------------------

  Widget _buildSnapshotChart(bool mobile) {
    final metrics = <_MetricData>[
      _MetricData(
        label: 'Active Employees',
        value: _employees.length,
        icon: Icons.people_outline_rounded,
        color: const Color(0xFFE96832),
      ),
      _MetricData(
        label: 'Pending Leaves',
        value: _pendingLeaves,
        icon: Icons.event_note_outlined,
        color: const Color(0xFFE8A317),
      ),
      _MetricData(
        label: 'Pending Expenses',
        value: _pendingExpenses,
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF7A5AF8),
      ),
      _MetricData(
        label: 'Archived Employees',
        value: _archivedEmployees.length,
        icon: Icons.person_off_outlined,
        color: const Color(0xFF64748B),
      ),
    ];

    var maxValue = 1;
    for (final metric in metrics) {
      if (metric.value > maxValue) maxValue = metric.value;
    }

    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      runSpacing: 20,
      children: metrics.map((metric) {
        return SizedBox(
          width: mobile ? 132 : 150,
          child: _buildGaugeTile(metric, maxValue, mobile),
        );
      }).toList(),
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
                painter: _RingGaugePainter(
                  fraction: animatedFraction,
                  color: metric.color,
                  trackColor: _pageBg,
                  strokeWidth: 8,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(metric.icon, size: 17, color: metric.color),
                      const SizedBox(height: 3),
                      Text(
                        metric.value.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Text(
          metric.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // DEPARTMENT DONUT — headcount share per department
  // ----------------------------------------------------------

  static const List<Color> _departmentPalette = [
    Color(0xFFE96832),
    Color(0xFF2878FF),
    Color(0xFF18864B),
    Color(0xFF7A5AF8),
    Color(0xFFE8A317),
    Color(0xFFC62828),
  ];

  Widget _buildDepartmentChart(bool mobile) {
    final breakdown = _departmentBreakdown();

    if (breakdown.isEmpty) {
      return _emptyChartPlaceholder(
        'No department data yet — add employees to see the breakdown here.',
      );
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
            painter: _DonutPainter(
              values: segments,
              colors: colors,
              trackColor: _pageBg,
              strokeWidth: 18,
              progress: progress,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    'Employees',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
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
            padding: EdgeInsets.only(
              bottom: i == breakdown.length - 1 ? 0 : 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: colors[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    breakdown[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${breakdown[i].value}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors[i],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${total == 0 ? 0 : (breakdown[i].value * 100 / total).round()}%)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    if (mobile) {
      return Column(
        children: [
          donut,
          const SizedBox(height: 18),
          legend,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        donut,
        const SizedBox(width: 24),
        Expanded(child: legend),
      ],
    );
  }

  Widget _emptyChartPlaceholder(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // QUICK ACTIONS
  // ----------------------------------------------------------

  Widget _buildQuickActions(bool mobile) {
    final actions = [
      (
      'Add Employee',
      Icons.person_add_alt_1_rounded,
      _openAddEmployee,
      ),
      (
      'View All Employees',
      Icons.people_alt_outlined,
      _openEmployees,
      ),
      (
      'Refresh Data',
      Icons.refresh_rounded,
      _isLoading ? null : _refreshDashboard,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================
  // EMPLOYEE SECTION
  // ==========================================================

  Widget _buildEmployeeSection() {
    final mobile = _isMobile;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // HEADER
            // ------------------------------------------------

            _buildEmployeeSectionHeader(mobile),

            SizedBox(height: mobile ? 14 : 20),

            const Divider(height: 1),

            const SizedBox(height: 4),

            // ------------------------------------------------
            // TABLE (wide) / LIST (phone)
            // ------------------------------------------------

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
        const Text(
          'Active Employees',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_employees.length} active employees in your company',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );

    final viewAllButton = OutlinedButton.icon(
      onPressed: _openEmployees,
      icon: const Icon(
        Icons.arrow_forward_rounded,
        size: 16,
      ),
      label: const Text('View All'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD9DEE7)),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    final addButton = FilledButton.icon(
      onPressed: _openAddEmployee,
      icon: const Icon(
        Icons.person_add_alt_1_rounded,
        size: 17,
      ),
      label: const Text('Add Employee'),
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    // PHONE: title on top, two equal buttons below
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: viewAllButton),
              const SizedBox(width: 10),
              Expanded(child: addButton),
            ],
          ),
        ],
      );
    }

    // DESKTOP / TABLET: single row
    return Row(
      children: [
        Expanded(child: titleBlock),
        viewAllButton,
        const SizedBox(width: 10),
        addButton,
      ],
    );
  }

  // ==========================================================
  // EMPLOYEE LIST (PHONE)
  // ==========================================================

  Widget _buildEmployeeList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _employees.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: Color(0xFFEDEFF3),
      ),
      itemBuilder: (context, index) {
        final employee = _employees[index];

        return InkWell(
          onTap: () => _openEmployeeDetails(employee),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(employee.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name.trim().isEmpty
                            ? 'Unnamed Employee'
                            : employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_displayValue(employee.employeeCode)}'
                            '  •  '
                            '${_displayValue(employee.department)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _displayValue(employee.phone),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A8494),
                        ),
                      ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPLOYEE TABLE (DESKTOP / TABLET)
  // ==========================================================

  Widget _buildEmployeeTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth < 850 ? 850 : constraints.maxWidth,
            ),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 48,
              dataRowMinHeight: 68,
              dataRowMaxHeight: 72,
              horizontalMargin: 8,
              columnSpacing: 28,
              dividerThickness: 0.6,
              headingTextStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B8493),
                letterSpacing: 0.4,
              ),
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
                    // --------------------------------------
                    // NAME
                    // --------------------------------------

                    DataCell(
                      SizedBox(
                        width: 210,
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  _initials(employee.name),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                employee.name.trim().isEmpty
                                    ? 'Unnamed Employee'
                                    : employee.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --------------------------------------
                    // CODE
                    // --------------------------------------

                    DataCell(
                      Text(
                        _displayValue(employee.employeeCode),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    // --------------------------------------
                    // DEPARTMENT
                    // --------------------------------------

                    DataCell(
                      Text(
                        _displayValue(employee.department),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),

                    // --------------------------------------
                    // MOBILE
                    // --------------------------------------

                    DataCell(
                      Text(
                        _displayValue(employee.phone),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),

                    // --------------------------------------
                    // STATUS
                    // --------------------------------------

                    DataCell(
                      _StatusBadge(status: employee.status),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // EMPTY EMPLOYEES
  // ==========================================================

  Widget _buildEmptyEmployees() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No active employees',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first employee to get started.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _openAddEmployee,
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              size: 17,
            ),
            label: const Text('Add Employee'),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR STATE
  // ==========================================================

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DRAWER
  // ==========================================================

  Widget _buildDrawer() {
    return Drawer(
      width: 255,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------
            // BRAND
            // -----------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEE7),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _primary,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'S Salary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Company Admin',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A93A1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // -----------------------------------------------
            // MENU
            // -----------------------------------------------

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                children: [
                  _drawerSection('OVERVIEW'),
                  _drawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Overview',
                    selected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  _drawerSection('WORKFORCE'),
                  _drawerItem(
                    icon: Icons.people_outline,
                    title: 'Employees',
                    onTap: _openEmployeesFromDrawer,
                  ),
                  _drawerItem(
                    icon: Icons.calendar_month_outlined,
                    title: 'Calendar',
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.schedule_outlined,
                    title: 'Shift Roster & Planner',
                    onTap: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ShiftRosterScreen(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.location_on_outlined,
                    title: 'Field GPS Tracking',
                  ),
                  _drawerItem(
                    icon: Icons.event_note_outlined,
                    title: 'Leave Requests',
                  ),
                  _drawerItem(
                    icon: Icons.account_tree_outlined,
                    title: 'Departments',
                  ),
                  const SizedBox(height: 10),
                  _drawerSection('FINANCE'),
                  _drawerItem(
                    icon: Icons.payments_outlined,
                    title: 'Payroll & Salary',
                  ),
                  _drawerItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Expenses',
                  ),
                  const SizedBox(height: 10),
                  _drawerSection('COMPANY & SECURITY'),
                  _drawerItem(
                    icon: Icons.business_outlined,
                    title: 'Branches & Locations',
                  ),
                  _drawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Team & Roles',
                  ),
                  _drawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // -----------------------------------------------
            // ADMIN PROFILE
            // -----------------------------------------------

            Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEE7),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Company Owner',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8A93A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Logout',
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout_outlined,
                      size: 19,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DRAWER SECTION
  // ==========================================================

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
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

  // ==========================================================
  // DRAWER ITEM
  // ==========================================================

  Widget _drawerItem({
    required IconData icon,
    required String title,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF1EB) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 11),
        leading: Icon(
          icon,
          size: 19,
          color: selected ? _primary : const Color(0xFF596273),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _primary : const Color(0xFF374151),
          ),
        ),
        onTap: onTap ??
                () {
              Navigator.pop(context);
            },
      ),
    );
  }

  // ==========================================================
  // EMPLOYEES FROM DRAWER
  // ==========================================================

  Future<void> _openEmployeesFromDrawer() async {
    Navigator.pop(context);

    await _openEmployees();
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  void _logout() {
    Navigator.pop(context);

    // Authentication logout will be
    // connected to SecureStorage later.
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String _displayValue(String value) {
    if (value.trim().isEmpty) {
      return '—';
    }

    return value;
  }

  String _initials(String name) {
    final clean = name.trim();

    if (clean.isEmpty) {
      return '?';
    }

    final parts = clean.split(
      RegExp(r'\s+'),
    );

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ==========================================================
  // STAGGERED ENTRANCE
  //
  // Wraps a widget with a fade + slide-up that plays as
  // _entranceController runs, offset by [index] so items
  // appear one after another rather than all at once.
  // ==========================================================

  Widget _staggeredIn(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.7);

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, builtChild) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 16),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }

  // ==========================================================
  // DEPARTMENT BREAKDOWN
  //
  // Computed from the already-loaded active employee list —
  // no extra API call needed.
  // ==========================================================

  List<MapEntry<String, int>> _departmentBreakdown() {
    final counts = <String, int>{};

    for (final employee in _employees) {
      final department = employee.department.trim();

      final key = department.isEmpty ? 'Unassigned' : department;

      counts[key] = (counts[key] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(6).toList();
  }
}

// =================================================================
// SUMMARY CARD
// =================================================================

class _DashboardSummaryCard extends StatelessWidget {
  final String title;

  final String value;

  final IconData icon;

  final Color accent;

  final bool highlighted;

  /// Smaller paddings / fonts for phones.
  final bool compact;

  const _DashboardSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.highlighted = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = compact ? 38.0 : 48.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ----------------------------------------------------
          // HIGHLIGHT BAR
          // ----------------------------------------------------

          if (highlighted)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE96832),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(13),
                    bottomLeft: Radius.circular(13),
                  ),
                ),
              ),
            ),

          // ----------------------------------------------------
          // CONTENT (vertically centred in the card)
          // ----------------------------------------------------

          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ------------------------------------------------
                  // ICON
                  // ------------------------------------------------

                  Container(
                    width: iconBox,
                    height: iconBox,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(compact ? 10 : 12),
                    ),
                    child: Icon(
                      icon,
                      size: compact ? 20 : 24,
                      color: accent,
                    ),
                  ),

                  SizedBox(width: compact ? 10 : 14),

                  // ------------------------------------------------
                  // TEXT
                  // ------------------------------------------------

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: compact ? 21 : 25,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: const Color(0xFF18212F),
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 3),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 11.5 : 12,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7A8494),
                          ),
                        ),
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

// =================================================================
// STATUS BADGE
// =================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();

    final isActive = normalized == 'active';

    final label = status.trim().isEmpty ? 'N/A' : status;

    final background =
    isActive ? const Color(0xFFE9F8EF) : const Color(0xFFFDECEC);

    final foreground =
    isActive ? const Color(0xFF18864B) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _capitalize(label),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

// =================================================================
// METRIC DATA (for the snapshot gauges)
// =================================================================

class _MetricData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

// =================================================================
// RING GAUGE PAINTER — single animated circular progress ring
// =================================================================

class _RingGaugePainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingGaugePainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) return;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159265 / 2;
    final sweepAngle = 2 * 3.14159265 * fraction.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingGaugePainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// =================================================================
// DONUT PAINTER — multi-segment donut that draws itself in as
// [progress] goes from 0 to 1
// =================================================================

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color trackColor;
  final double strokeWidth;
  final double progress;

  _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const twoPi = 2 * 3.14159265;
    const startAngle = -3.14159265 / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    final total = values.fold<double>(0, (sum, v) => sum + v);

    if (total <= 0 || progress <= 0) return;

    final revealedSweep = twoPi * progress.clamp(0.0, 1.0);

    var cursor = 0.0;

    for (var i = 0; i < values.length; i++) {
      final segmentSweep = twoPi * (values[i] / total);

      final drawSweep =
      (revealedSweep - cursor).clamp(0.0, segmentSweep);

      if (drawSweep > 0) {
        final segmentPaint = Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;

        canvas.drawArc(
          rect,
          startAngle + cursor,
          drawSweep,
          false,
          segmentPaint,
        );
      }

      cursor += segmentSweep;

      if (cursor >= revealedSweep) break;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}