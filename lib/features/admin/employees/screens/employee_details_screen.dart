import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import '../models/admin_employee_access.dart';
import 'edit_employee_screen.dart';

// ==========================================================
// STYLE
// ==========================================================

const double _mobileBreakpoint = 700;
const double _maxContentWidth = 1200;

const Color _primary = Color(0xFFE96832);
const Color _primaryLight = Color(0xFFFFF1EB);
const Color _textDark = Color(0xFF18212F);
const Color _textMedium = Color(0xFF4B5563);
const Color _textLight = Color(0xFF8A93A1);
const Color _border = Color(0xFFD9DEE5);
const Color _divider = Color(0xFFE9ECF0);
const Color _pageBackground = Color(0xFFF7F8FA);
const Color _danger = Color(0xFFC62828);

/// The sections of the employee details page.
enum _DetailTab {
  overview,
  employment,
  personal,
  bank,
  attendance,
  leaves,
  expenses,
  payroll,
}

/// Employee details.
///
/// Two ways to show it:
///  - `embedded: true`  -> inside the admin dashboard (the sidebar stays
///    visible). No Scaffold of its own. [onBack] is called by the
///    "← back" button, by the phone / browser back button and after an
///    employee is archived. Edit also opens INSIDE the dashboard.
///  - `embedded: false` -> full screen with its own Scaffold (the old way,
///    opened with Navigator.push).
///
/// PERMISSION: [access] decides what this role sees:
///  - Edit button      -> canEdit
///  - Archive button   -> canDelete
///  - Attendance       -> canSeeAttendance
///  - Leaves           -> canSeeLeaves
///  - Expenses         -> canSeeExpenses
///  - Payroll / salary -> canSeeSalary
/// The default is full access (the old behaviour).
class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;
  final AdminEmployeeAccess access;

  /// true = shown inside the dashboard (sidebar stays visible).
  final bool embedded;

  /// Embedded only: called when the person goes back (or after archiving).
  final VoidCallback? onBack;

  /// Embedded only: text of the back button, e.g. "All Departments".
  final String backLabel;

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
    this.access = AdminEmployeeAccess.full,
    this.embedded = false,
    this.onBack,
    this.backLabel = 'Back',
  });

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  // ==========================================================
  // SERVICES / CONTROLLERS
  // ==========================================================

  final EmployeeService _employeeService = EmployeeService();
  final ScrollController _scrollController = ScrollController();

  // ==========================================================
  // STATE
  // ==========================================================

  late final List<_DetailTab> _tabs;
  _DetailTab _selectedTab = _DetailTab.overview;

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _hasData = false;

  /// Embedded only: the edit form is open (inside the dashboard).
  bool _editing = false;

  String? _errorMessage;

  Map<String, dynamic> _employeeData = {};
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _personalDetails = {};
  Map<String, dynamic> _companyData = {};

  List<dynamic> _attendance = [];
  List<dynamic> _leaves = [];
  List<dynamic> _expenses = [];
  List<dynamic> _salaryStructures = [];
  List<dynamic> _payrolls = [];

  // ==========================================================
  // INIT / DISPOSE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _tabs = _visibleTabs();

    _loadEmployeeDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// PERMISSION: only the sections this role may see.
  List<_DetailTab> _visibleTabs() {
    final a = widget.access;

    return [
      _DetailTab.overview,
      _DetailTab.employment,
      _DetailTab.personal,
      _DetailTab.bank,
      if (a.canSeeAttendance) _DetailTab.attendance,
      if (a.canSeeLeaves) _DetailTab.leaves,
      if (a.canSeeExpenses) _DetailTab.expenses,
      if (a.canSeeSalary) _DetailTab.payroll,
    ];
  }

  String _tabLabel(_DetailTab tab) {
    switch (tab) {
      case _DetailTab.overview:
        return 'Overview';
      case _DetailTab.employment:
        return 'Employment';
      case _DetailTab.personal:
        return 'Personal';
      case _DetailTab.bank:
        return 'Bank Details';
      case _DetailTab.attendance:
        return 'Attendance';
      case _DetailTab.leaves:
        return 'Leaves';
      case _DetailTab.expenses:
        return 'Expenses';
      case _DetailTab.payroll:
        return 'Payroll';
    }
  }

  IconData _tabIcon(_DetailTab tab) {
    switch (tab) {
      case _DetailTab.overview:
        return Icons.dashboard_outlined;
      case _DetailTab.employment:
        return Icons.business_center_outlined;
      case _DetailTab.personal:
        return Icons.person_outline_rounded;
      case _DetailTab.bank:
        return Icons.account_balance_outlined;
      case _DetailTab.attendance:
        return Icons.access_time_outlined;
      case _DetailTab.leaves:
        return Icons.event_busy_outlined;
      case _DetailTab.expenses:
        return Icons.receipt_long_outlined;
      case _DetailTab.payroll:
        return Icons.payments_outlined;
    }
  }

  int? _tabCount(_DetailTab tab) {
    switch (tab) {
      case _DetailTab.attendance:
        return _attendance.length;
      case _DetailTab.leaves:
        return _leaves.length;
      case _DetailTab.expenses:
        return _expenses.length;
      case _DetailTab.payroll:
        return _payrolls.length + _salaryStructures.length;
      default:
        return null;
    }
  }

  void _selectTab(_DetailTab tab) {
    if (!_tabs.contains(tab) || tab == _selectedTab) return;
    setState(() => _selectedTab = tab);
  }

  /// Back: inside the dashboard it calls [onBack]; full screen pops the route.
  void _goBack() {
    if (widget.embedded) {
      widget.onBack?.call();
    } else {
      Navigator.maybePop(context);
    }
  }

  // ==========================================================
  // LOAD
  // ==========================================================

  /// [silent] = pull to refresh / after edit: the page stays on screen.
  Future<void> _loadEmployeeDetails({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _employeeService.getEmployeeById(
        widget.employee.id,
      );

      if (!mounted) return;

      final employee = response['employee'];
      final user = response['user'];
      final company = response['company'];

      final employeeData =
      employee is Map ? Map<String, dynamic>.from(employee) : <String, dynamic>{};

      final userData =
      user is Map ? Map<String, dynamic>.from(user) : <String, dynamic>{};

      final companyData = company is Map
          ? Map<String, dynamic>.from(company)
          : <String, dynamic>{};

      final personal = employeeData['personalDetails'];

      final personalDetails = personal is Map
          ? Map<String, dynamic>.from(personal)
          : <String, dynamic>{};

      List<dynamic> listOf(dynamic value) =>
          value is List ? List<dynamic>.from(value) : <dynamic>[];

      setState(() {
        _employeeData = employeeData;
        _userData = userData;
        _companyData = companyData;
        _personalDetails = personalDetails;

        _attendance = listOf(response['attendance']);
        _leaves = listOf(response['leaves']);
        _expenses = listOf(response['expenses']);
        _salaryStructures = listOf(response['salaryStructures']);
        _payrolls = listOf(response['payrolls']);

        _hasData = true;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      // A quiet refresh must not wipe a working page.
      if (silent && _hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    }
  }

  // ==========================================================
  // EDIT
  // ==========================================================

  Future<void> _openEditScreen() async {
    if (!widget.access.canEdit) return; // PERMISSION

    // Inside the dashboard: the form opens in the page area, the sidebar
    // stays visible.
    if (widget.embedded) {
      setState(() => _editing = true);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEmployeeScreen(
          employee: widget.employee,
          employeeData: _employeeData,
          userData: _userData,
          personalDetails: _personalDetails,
        ),
      ),
    );

    if (result == true) {
      await _loadEmployeeDetails(silent: true);
    }
  }

  /// Embedded only: closes the edit form, and refreshes after a save.
  void _closeEditor(bool saved) {
    if (!mounted) return;

    setState(() => _editing = false);

    if (saved) {
      _loadEmployeeDetails(silent: true);
    }
  }

  // ==========================================================
  // ARCHIVE
  // ==========================================================

  Future<void> _archiveEmployee() async {
    if (!widget.access.canDelete) return; // PERMISSION

    final name = _stringValue(
      _userData['name'],
      fallback: widget.employee.name,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Archive Employee',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          content: Text(
            'Are you sure you want to archive $name?',
            style: const TextStyle(
              fontSize: 14.5,
              color: _textMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _textMedium),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _employeeService.deleteEmployee(
        widget.employee.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee archived successfully.'),
        ),
      );

      if (widget.embedded) {
        // back to the list inside the dashboard
        widget.onBack?.call();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ==========================================================
  // VALUE HELPERS
  // ==========================================================

  String _stringValue(
      dynamic value, {
        String fallback = 'Not available',
      }) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty) return fallback;

    return text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not available';

    final date = DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return _stringValue(value);
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Not available';

    final text = value.toString().trim();

    if (text.isEmpty) return 'Not available';

    return text
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}'
          '${word.substring(1)}',
    )
        .join(' ');
  }

  String _bankValue(String key) {
    final bank = _employeeData['bankDetails'];

    if (bank is Map) {
      return _stringValue(bank[key]);
    }

    return 'Not available';
  }

  String _initials(String name) {
    final clean = name.trim();

    if (clean.isEmpty || clean == 'Not available') {
      return '?';
    }

    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // Full screen (pushed route): the route handles back by itself.
    if (!widget.embedded) return _buildPage();

    // Inside the dashboard, the edit form replaces the page. Back (phone /
    // browser) closes the form and returns to the details.
    if (_editing) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _closeEditor(false);
        },
        child: EditEmployeeScreen(
          key: const ValueKey('edit-employee'),
          employee: widget.employee,
          employeeData: _employeeData,
          userData: _userData,
          personalDetails: _personalDetails,
          embedded: true,
          backLabel: 'Employee Details',
          onClose: _closeEditor,
        ),
      );
    }

    // Details inside the dashboard. Back (phone / browser) returns to the
    // list the person came from instead of leaving the dashboard.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isDeleting) _goBack();
      },
      child: _buildPage(),
    );
  }

  Widget _buildPage() {
    final media = MediaQuery.of(context);

    // Large accessibility fonts must not break the layout on any platform.
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.2,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Phone / wide layout is chosen from the space THIS page really
          // has (inside the dashboard the sidebar takes part of the width).
          final mobile = constraints.maxWidth < _mobileBreakpoint;

          final content = Column(
            children: [
              _buildTopBar(mobile),
              Expanded(child: _buildBody(mobile)),
            ],
          );

          // Inside the dashboard: no Scaffold, the sidebar stays visible.
          if (widget.embedded) {
            return ColoredBox(color: _pageBackground, child: content);
          }

          return Scaffold(
            backgroundColor: _pageBackground,
            body: SafeArea(child: content),
          );
        },
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _viewOnlyTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 14, color: _textLight),
          SizedBox(width: 5),
          Text(
            'View only',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool mobile) {
    final busy = _isLoading || _isDeleting;
    final canEdit = widget.access.canEdit;
    final canDelete = widget.access.canDelete;
    final embedded = widget.embedded;

    return Container(
      width: double.infinity,
      height: embedded ? 58 : 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 4 : (embedded ? 20 : 16),
      ),
      child: Row(
        children: [
          if (embedded)
          // Inside the dashboard: "← All Departments"
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isDeleting ? null : _goBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    widget.backLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _textMedium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            IconButton(
              tooltip: 'Back',
              onPressed: _isDeleting ? null : _goBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: _textDark,
              ),
            ),
            if (!mobile) ...[
              const SizedBox(width: 2),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: _primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Employee Details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  if (!mobile) ...[
                    const SizedBox(height: 1),
                    const Text(
                      'View profile, records and payroll information.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          IconButton(
            tooltip: 'Refresh',
            onPressed: busy ? null : () => _loadEmployeeDetails(silent: true),
            icon: const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: _textDark,
            ),
          ),
          if (!canEdit && !canDelete) ...[
            const SizedBox(width: 4),
            _viewOnlyTag(),
            const SizedBox(width: 6),
          ] else if (mobile) ...[
            if (canEdit)
              IconButton(
                tooltip: 'Edit Employee',
                onPressed: busy ? null : _openEditScreen,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 21,
                  color: _textDark,
                ),
              ),
            if (canDelete)
              IconButton(
                tooltip: 'Archive',
                onPressed: busy ? null : _archiveEmployee,
                icon: _isDeleting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(
                  Icons.archive_outlined,
                  size: 21,
                  color: _danger,
                ),
              ),
          ] else ...[
            if (canDelete)
              OutlinedButton.icon(
                onPressed: busy ? null : _archiveEmployee,
                icon: _isDeleting
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.archive_outlined, size: 18),
                label: const Text('Archive'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _danger,
                  side: BorderSide(color: _danger.withValues(alpha: 0.4)),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            if (canDelete && canEdit) const SizedBox(width: 10),
            if (canEdit)
              FilledButton.icon(
                onPressed: busy ? null : _openEditScreen,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit Employee'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody(bool mobile) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final basePad = mobile ? 14.0 : 24.0;

        // Inside the dashboard the page uses the full width next to the
        // sidebar (like the other screens). Full screen on a very wide
        // display: the content is centered.
        final side = widget.embedded
            ? basePad
            : math.max(basePad, (width - _maxContentWidth) / 2);

        return RefreshIndicator(
          color: _primary,
          onRefresh: () => _loadEmployeeDetails(silent: true),
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(side, mobile ? 14 : 22, side, 36),
              children: [
                _buildHeroCard(mobile),
                SizedBox(height: mobile ? 14 : 18),
                _buildTabSelector(mobile),
                SizedBox(height: mobile ? 14 : 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey<_DetailTab>(_selectedTab),
                    child: _buildTabContent(_selectedTab),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // HERO CARD
  // ==========================================================

  Widget _buildHeroCard(bool mobile) {
    final name = _stringValue(
      _userData['name'],
      fallback: widget.employee.name,
    );

    final designation = _stringValue(
      _employeeData['designation'],
      fallback: widget.employee.designation,
    );

    final department = _stringValue(
      _employeeData['department'],
      fallback: widget.employee.department,
    );

    final code = _stringValue(
      _employeeData['employeeCode'],
      fallback: widget.employee.employeeCode,
    );

    final status = _stringValue(
      _employeeData['status'],
      fallback: widget.employee.status,
    );

    final email = _stringValue(_userData['email']);
    final phone = _stringValue(_userData['phone']);
    final workMode = _formatValue(_employeeData['workMode']);

    final subtitle = [designation, department]
        .where((value) => value != 'Not available')
        .join('  •  ');

    final avatar = Container(
      width: mobile ? 56 : 72,
      height: mobile ? 56 : 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(mobile ? 14 : 18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7A1A), Color(0xFFE0501E)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33E96832),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: mobile ? 20 : 26,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: mobile ? 20 : 26,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            _Badge(text: _formatValue(status)),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: mobile ? 13 : 14.5,
              color: _textMedium,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (code != 'Not available')
              _metaChip(Icons.badge_outlined, code),
            if (email != 'Not available')
              _metaChip(Icons.email_outlined, email),
            if (phone != 'Not available')
              _metaChip(Icons.phone_outlined, phone),
            if (workMode != 'Not available')
              _metaChip(Icons.location_on_outlined, workMode),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF7A1A), Color(0xFFE96832)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(mobile ? 16 : 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                SizedBox(width: mobile ? 14 : 20),
                Expanded(child: info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textLight),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION SELECTOR (pills)
  // ==========================================================

  Widget _buildTabSelector(bool mobile) {
    Widget pill(_DetailTab tab) {
      final selected = tab == _selectedTab;
      final count = _tabCount(tab);

      return Material(
        color: selected ? _primary : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _selectTab(tab),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? _primary : _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _tabIcon(tab),
                  size: 16,
                  color: selected ? Colors.white : _textMedium,
                ),
                const SizedBox(width: 7),
                Text(
                  _tabLabel(tab),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _textDark,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.25)
                          : _pageBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _textMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Phone: one row you can swipe sideways.
    if (mobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in _tabs)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: pill(tab),
              ),
          ],
        ),
      );
    }

    // Web / tablet: all pills visible, wrapping onto a second row if needed
    // (no sideways scrolling, so it works with a mouse too).
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final tab in _tabs) pill(tab)],
    );
  }

  // ==========================================================
  // SECTION CONTENT
  // ==========================================================

  Widget _buildTabContent(_DetailTab tab) {
    switch (tab) {
      case _DetailTab.overview:
        return _buildOverviewTab();
      case _DetailTab.employment:
        return _buildEmploymentTab();
      case _DetailTab.personal:
        return _buildPersonalTab();
      case _DetailTab.bank:
        return _buildBankTab();
      case _DetailTab.attendance:
        return _buildAttendanceTab();
      case _DetailTab.leaves:
        return _buildLeavesTab();
      case _DetailTab.expenses:
        return _buildExpensesTab();
      case _DetailTab.payroll:
        return _buildPayrollTab();
    }
  }

  // ---------------- OVERVIEW ----------------

  Widget _buildOverviewTab() {
    final a = widget.access;

    final stats = <Widget>[
      if (a.canSeeAttendance)
        _statTile(
          'Attendance Records',
          _attendance.length,
          Icons.access_time_outlined,
          _DetailTab.attendance,
        ),
      if (a.canSeeLeaves)
        _statTile(
          'Leave Records',
          _leaves.length,
          Icons.event_busy_outlined,
          _DetailTab.leaves,
        ),
      if (a.canSeeExpenses)
        _statTile(
          'Expense Records',
          _expenses.length,
          Icons.receipt_long_outlined,
          _DetailTab.expenses,
        ),
      if (a.canSeeSalary) ...[
        _statTile(
          'Salary Structures',
          _salaryStructures.length,
          Icons.payments_outlined,
          _DetailTab.payroll,
        ),
        _statTile(
          'Payroll Records',
          _payrolls.length,
          Icons.account_balance_wallet_outlined,
          _DetailTab.payroll,
        ),
      ],
    ];

    return Column(
      children: [
        if (stats.isNotEmpty)
          _card(
            title: 'Summary',
            icon: Icons.insights_outlined,
            child: _grid(stats, maxColumns: 5, minItemWidth: 150),
          ),
        _card(
          title: 'Key Details',
          icon: Icons.badge_outlined,
          child: _grid([
            _field(
              'Employee Code',
              _stringValue(_employeeData['employeeCode']),
              Icons.badge_outlined,
            ),
            _field(
              'Designation',
              _stringValue(_employeeData['designation']),
              Icons.workspace_premium_outlined,
            ),
            _field(
              'Department',
              _stringValue(_employeeData['department']),
              Icons.account_tree_outlined,
            ),
            _field(
              'Employment Type',
              _formatValue(_employeeData['employmentType']),
              Icons.business_center_outlined,
            ),
            _field(
              'Work Mode',
              _formatValue(_employeeData['workMode']),
              Icons.location_on_outlined,
            ),
            _field(
              'Date of Joining',
              _formatDate(_employeeData['dateOfJoining']),
              Icons.calendar_month_outlined,
            ),
            _field(
              'Email',
              _stringValue(_userData['email']),
              Icons.email_outlined,
            ),
            _field(
              'Phone',
              _stringValue(_userData['phone']),
              Icons.phone_outlined,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _statTile(
      String label,
      int value,
      IconData icon,
      _DetailTab target,
      ) {
    return InkWell(
      onTap: () => _selectTab(target),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 19, color: _primary),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFB6BDC8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: _textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- EMPLOYMENT ----------------

  Widget _buildEmploymentTab() {
    return Column(
      children: [
        _card(
          title: 'Employment Information',
          icon: Icons.business_center_outlined,
          child: _grid([
            _field(
              'Employee Code',
              _stringValue(_employeeData['employeeCode']),
              Icons.badge_outlined,
            ),
            _field(
              'Designation',
              _stringValue(_employeeData['designation']),
              Icons.workspace_premium_outlined,
            ),
            _field(
              'Department',
              _stringValue(_employeeData['department']),
              Icons.account_tree_outlined,
            ),
            _field(
              'Employment Type',
              _formatValue(_employeeData['employmentType']),
              Icons.business_center_outlined,
            ),
            _field(
              'Work Mode',
              _formatValue(_employeeData['workMode']),
              Icons.location_on_outlined,
            ),
            _field(
              'Date of Joining',
              _formatDate(_employeeData['dateOfJoining']),
              Icons.calendar_month_outlined,
            ),
            _field(
              'Status',
              _formatValue(_employeeData['status']),
              Icons.toggle_on_outlined,
            ),
          ]),
        ),
        _card(
          title: 'Company',
          icon: Icons.business,
          child: _grid([
            _field(
              'Company Name',
              _stringValue(_companyData['name']),
              Icons.business,
            ),
            _field(
              'Company Address',
              _stringValue(_companyData['address']),
              Icons.location_city_outlined,
            ),
            _field(
              'Timezone',
              _stringValue(_companyData['timezone']),
              Icons.access_time_outlined,
            ),
          ]),
        ),
      ],
    );
  }

  // ---------------- PERSONAL ----------------

  Widget _buildPersonalTab() {
    return Column(
      children: [
        _card(
          title: 'Contact Information',
          icon: Icons.contact_phone_outlined,
          child: _grid([
            _field(
              'Email',
              _stringValue(_userData['email']),
              Icons.email_outlined,
            ),
            _field(
              'Phone',
              _stringValue(_userData['phone']),
              Icons.phone_outlined,
            ),
            _field(
              'Address',
              _stringValue(_personalDetails['address']),
              Icons.home_outlined,
            ),
          ]),
        ),
        _card(
          title: 'Personal Information',
          icon: Icons.person_outline_rounded,
          child: _grid([
            _field(
              'Gender',
              _stringValue(_personalDetails['gender']),
              Icons.person_outline,
            ),
            _field(
              'Date of Birth',
              _formatDate(_personalDetails['dob']),
              Icons.cake_outlined,
            ),
          ]),
        ),
      ],
    );
  }

  // ---------------- BANK ----------------

  Widget _buildBankTab() {
    return _card(
      title: 'Bank Details',
      icon: Icons.account_balance_outlined,
      child: _grid([
        // The account number is hidden until the eye icon is tapped.
        _MaskedFieldTile(
          label: 'Account Number',
          value: _bankValue('accountNumber'),
          icon: Icons.account_balance,
        ),
        _field(
          'IFSC Code',
          _bankValue('ifsc'),
          Icons.numbers,
        ),
        _field(
          'Bank Name',
          _bankValue('bankName'),
          Icons.account_balance_outlined,
        ),
        _field(
          'UPI ID',
          _bankValue('upiId'),
          Icons.payment_outlined,
        ),
      ]),
    );
  }

  // ---------------- RECORD SECTIONS ----------------

  Widget _buildAttendanceTab() {
    return _card(
      title: 'Attendance Records (${_attendance.length})',
      icon: Icons.access_time_outlined,
      child: _recordsView(
        _attendance,
        emptyText: 'No attendance records found.',
        emptyIcon: Icons.access_time_outlined,
      ),
    );
  }

  Widget _buildLeavesTab() {
    return _card(
      title: 'Leave Records (${_leaves.length})',
      icon: Icons.event_busy_outlined,
      child: _recordsView(
        _leaves,
        emptyText: 'No leave records found.',
        emptyIcon: Icons.event_busy_outlined,
      ),
    );
  }

  Widget _buildExpensesTab() {
    return _card(
      title: 'Expense Records (${_expenses.length})',
      icon: Icons.receipt_long_outlined,
      child: _recordsView(
        _expenses,
        emptyText: 'No expense records found.',
        emptyIcon: Icons.receipt_long_outlined,
      ),
    );
  }

  Widget _buildPayrollTab() {
    return Column(
      children: [
        _card(
          title: 'Salary Structures (${_salaryStructures.length})',
          icon: Icons.payments_outlined,
          child: _recordsView(
            _salaryStructures,
            emptyText: 'No salary structures found.',
            emptyIcon: Icons.payments_outlined,
          ),
        ),
        _card(
          title: 'Payroll Records (${_payrolls.length})',
          icon: Icons.account_balance_wallet_outlined,
          child: _recordsView(
            _payrolls,
            emptyText: 'No payroll records found.',
            emptyIcon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // GENERIC RECORD VIEW  (table on wide, cards on phone)
  // ==========================================================

  static const List<String> _preferredColumns = [
    'date',
    'month',
    'year',
    'effective',
    'title',
    'type',
    'category',
    'checkin',
    'checkout',
    'clockin',
    'clockout',
    'from',
    'start',
    'to',
    'end',
    'days',
    'hours',
    'reason',
    'description',
    'amount',
    'basic',
    'gross',
    'net',
    'salary',
    'status',
  ];

  bool _isHiddenKey(String key) {
    final last = key.split('.').last;

    return last == '_id' ||
        last == 'id' ||
        last == '__v' ||
        (last.length > 2 && last.endsWith('Id'));
  }

  Map<String, dynamic> _flatten(Map<String, dynamic> source) {
    final result = <String, dynamic>{};

    source.forEach((key, value) {
      if (_isHiddenKey(key)) return;

      if (value is String || value is num || value is bool) {
        result[key] = value;
      } else if (value is Map) {
        value.forEach((subKey, subValue) {
          final flatKey = '$key.$subKey';

          if (_isHiddenKey(flatKey)) return;

          if (subValue is String || subValue is num || subValue is bool) {
            result[flatKey] = subValue;
          }
        });
      }
    });

    return result;
  }

  int _columnRank(String key) {
    final lower = key.toLowerCase();

    for (var i = 0; i < _preferredColumns.length; i++) {
      if (lower.contains(_preferredColumns[i])) {
        return i;
      }
    }

    return 100;
  }

  List<String> _pickColumns(
      List<Map<String, dynamic>> records,
      int maxColumns,
      ) {
    final keys = <String>[];

    for (final record in records.take(30)) {
      for (final key in record.keys) {
        if (!keys.contains(key)) {
          keys.add(key);
        }
      }
    }

    final indexed = keys.asMap().entries.toList()
      ..sort((a, b) {
        final rank = _columnRank(a.value).compareTo(_columnRank(b.value));

        if (rank != 0) return rank;

        return a.key.compareTo(b.key);
      });

    return indexed.map((entry) => entry.value).take(maxColumns).toList();
  }

  String _labelFor(String key) {
    final spaced = key
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
          (_) => ' ',
    )
        .trim();

    return spaced
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1)}',
    )
        .join(' ');
  }

  static const List<String> _moneyKeys = [
    'amount',
    'salary',
    'basic',
    'gross',
    'netpay',
    'net_pay',
    'deduction',
    'allowance',
    'bonus',
    'tax',
    'ctc',
    'hra',
    'reimburs',
  ];

  String _inr(num value) {
    final isInt = value == value.roundToDouble();

    final text = isInt ? value.toInt().toString() : value.toStringAsFixed(2);

    final parts = text.split('.');

    var integer = parts[0];

    final negative = integer.startsWith('-');

    if (negative) integer = integer.substring(1);

    if (integer.length > 3) {
      final last3 = integer.substring(integer.length - 3);

      var rest = integer.substring(0, integer.length - 3);

      final groups = <String>[];

      while (rest.length > 2) {
        groups.insert(0, rest.substring(rest.length - 2));

        rest = rest.substring(0, rest.length - 2);
      }

      if (rest.isNotEmpty) groups.insert(0, rest);

      integer = '${groups.join(',')},$last3';
    }

    final decimals = parts.length > 1 ? '.${parts[1]}' : '';

    return '₹${negative ? '-' : ''}$integer$decimals';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatCell(String key, dynamic value) {
    if (value == null) return '—';

    if (value is bool) return value ? 'Yes' : 'No';

    if (value is num) {
      final lower = key.toLowerCase();

      final isMoney =
          !lower.contains('days') && _moneyKeys.any((k) => lower.contains(k));

      if (isMoney) return _inr(value);

      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(2);
    }

    final text = value.toString().trim();

    if (text.isEmpty) return '—';

    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text)) {
      final parsed = DateTime.tryParse(text);

      if (parsed != null) {
        final date = parsed.toLocal();

        final dateText = '${_twoDigits(date.day)}/'
            '${_twoDigits(date.month)}/'
            '${date.year}';

        final dateOnly = text.length <= 10 || text.contains('T00:00:00');

        if (dateOnly) return dateText;

        final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

        final period = date.hour >= 12 ? 'PM' : 'AM';

        return '$dateText  $hour:${_twoDigits(date.minute)} $period';
      }
    }

    if (RegExp(r'^[a-z]+(_[a-z]+)+$').hasMatch(text)) {
      return _formatValue(text);
    }

    if (text.length > 1 && text == text.toLowerCase()) {
      return '${text[0].toUpperCase()}${text.substring(1)}';
    }

    return text;
  }

  Widget _recordsView(
      List<dynamic> list, {
        required String emptyText,
        required IconData emptyIcon,
      }) {
    final records = list
        .whereType<Map>()
        .map((item) => _flatten(Map<String, dynamic>.from(item)))
        .where((record) => record.isNotEmpty)
        .toList();

    if (records.isEmpty) {
      return _emptyBox(emptyText, emptyIcon);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 640) {
          return _recordCards(records);
        }

        // As many columns as fit (at least 150 px each).
        final maxColumns = math.min(7, math.max(3, (width / 150).floor()));

        return _recordTable(records, _pickColumns(records, maxColumns));
      },
    );
  }

  // ---------------- TABLE ----------------

  Widget _recordTable(
      List<Map<String, dynamic>> records,
      List<String> columns,
      ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // header row
          Container(
            color: const Color(0xFFFAFBFC),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                for (final key in columns)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        _labelFor(key).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: Color(0xFF7B8493),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _divider),

          // data rows
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _divider),
            _recordRow(records[i], columns),
          ],
        ],
      ),
    );
  }

  Widget _recordRow(Map<String, dynamic> record, List<String> columns) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final key in columns)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _recordCell(key, record[key], columns.first == key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recordCell(String key, dynamic value, bool isFirst) {
    final text = _formatCell(key, value);
    final isStatus = key.toLowerCase().endsWith('status');

    if (isStatus && text != '—') {
      return Align(
        alignment: Alignment.centerLeft,
        child: _Badge(text: text),
      );
    }

    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
        color: isFirst ? _textDark : _textMedium,
      ),
    );
  }

  // ---------------- CARDS (PHONE) ----------------

  Widget _recordCards(List<Map<String, dynamic>> records) {
    final columns = _pickColumns(records, 8);

    return Column(
      children: [
        for (var i = 0; i < records.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == records.length - 1 ? 0 : 10,
            ),
            child: _recordCard(records[i], columns, i),
          ),
      ],
    );
  }

  Widget _recordCard(
      Map<String, dynamic> record,
      List<String> columns,
      int index,
      ) {
    final titleKey = columns.isNotEmpty ? columns.first : null;

    final statusKey = columns.firstWhere(
          (key) => key.toLowerCase().endsWith('status'),
      orElse: () => '',
    );

    final detailKeys = columns
        .where((key) => key != titleKey && key != statusKey)
        .where((key) => record[key] != null)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titleKey == null
                      ? 'Record ${index + 1}'
                      : _formatCell(titleKey, record[titleKey]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
              if (statusKey.isNotEmpty && record[statusKey] != null) ...[
                const SizedBox(width: 8),
                _Badge(text: _formatCell(statusKey, record[statusKey])),
              ],
            ],
          ),
          if (detailKeys.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: _divider),
            const SizedBox(height: 10),
            for (final key in detailKeys)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        _labelFor(key),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _textLight,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        _formatCell(key, record[key]),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _emptyBox(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _divider),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _divider),
            ),
            child: Icon(icon, size: 26, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: _textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILDING BLOCKS
  // ==========================================================

  /// White section card with a titled header.
  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 17, color: _primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _divider),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }

  /// Read-only value tile.
  Widget _field(String label, String value, IconData icon) {
    return _FieldTile(label: label, value: value, icon: icon);
  }

  /// Responsive grid: as many columns as fit (up to [maxColumns]).
  Widget _grid(
      List<Widget> items, {
        int maxColumns = 3,
        double minItemWidth = 260,
      }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = math.min(
          maxColumns,
          math.max(1, (width / minItemWidth).floor()),
        );

        const gap = 14.0;

        final itemWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items) SizedBox(width: itemWidth, child: item),
          ],
        );
      },
    );
  }

  // ==========================================================
  // ERROR STATE
  // ==========================================================

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
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
                'Unable to load employee details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadEmployeeDetails,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// FIELD TILE (icon + label + value)
// =================================================================

class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;

  const _FieldTile({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final empty = value == 'Not available';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _textLight,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: empty ? _textLight : _textDark,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing! else const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// =================================================================
// MASKED FIELD (account number with show / hide)
// =================================================================

class _MaskedFieldTile extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MaskedFieldTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  State<_MaskedFieldTile> createState() => _MaskedFieldTileState();
}

class _MaskedFieldTileState extends State<_MaskedFieldTile> {
  bool _visible = false;

  bool get _canToggle =>
      widget.value != 'Not available' && widget.value.length > 4;

  String get _masked {
    final v = widget.value;

    if (!_canToggle) return v;

    return '${'•' * (v.length - 4)}${v.substring(v.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return _FieldTile(
      label: widget.label,
      value: _visible ? widget.value : _masked,
      icon: widget.icon,
      trailing: _canToggle
          ? IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: _visible ? 'Hide' : 'Show',
        onPressed: () => setState(() => _visible = !_visible),
        icon: Icon(
          _visible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 19,
          color: _textLight,
        ),
      )
          : null,
    );
  }
}

// =================================================================
// STATUS BADGE
// =================================================================

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final lower = text.trim().toLowerCase();

    Color background;
    Color foreground;

    if (const [
      'active',
      'approved',
      'present',
      'paid',
      'completed',
      'processed',
      'success',
    ].contains(lower)) {
      background = const Color(0xFFE9F8EF);
      foreground = const Color(0xFF18864B);
    } else if (const [
      'pending',
      'draft',
      'half day',
      'late',
      'processing',
      'on leave',
    ].contains(lower)) {
      background = const Color(0xFFFFF4E0);
      foreground = const Color(0xFFB7791F);
    } else if (const [
      'rejected',
      'absent',
      'inactive',
      'cancelled',
      'canceled',
      'archived',
      'failed',
    ].contains(lower)) {
      background = const Color(0xFFFDECEC);
      foreground = const Color(0xFFC62828);
    } else {
      background = const Color(0xFFF1F5F9);
      foreground = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
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
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}