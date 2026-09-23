import 'package:flutter/material.dart';

import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import 'edit_employee_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // STYLE
  // ==========================================================

  static const double _mobileBreakpoint = 700;

  static const Color _primary = Color(0xFFE96832);
  static const Color _primaryLight = Color(0xFFFFF1EB);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _textMedium = Color(0xFF4B5563);
  static const Color _textLight = Color(0xFF8A93A1);
  static const Color _border = Color(0xFFD9DEE5);
  static const Color _divider = Color(0xFFE9ECF0);
  static const Color _pageBackground = Color(0xFFF7F8FA);
  static const Color _danger = Color(0xFFC62828);

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  // ==========================================================
  // SERVICES / CONTROLLERS
  // ==========================================================

  final EmployeeService _employeeService = EmployeeService();

  late final TabController _tabController;

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;
  bool _isDeleting = false;

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

    _tabController = TabController(length: 8, vsync: this);

    _loadEmployeeDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD
  // ==========================================================

  Future<void> _loadEmployeeDetails() async {
    if (mounted) {
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

      _employeeData =
      employee is Map ? Map<String, dynamic>.from(employee) : {};

      _userData = user is Map ? Map<String, dynamic>.from(user) : {};

      _companyData = company is Map ? Map<String, dynamic>.from(company) : {};

      final personal = _employeeData['personalDetails'];

      _personalDetails =
      personal is Map ? Map<String, dynamic>.from(personal) : {};

      _attendance = response['attendance'] is List
          ? List<dynamic>.from(response['attendance'])
          : [];

      _leaves = response['leaves'] is List
          ? List<dynamic>.from(response['leaves'])
          : [];

      _expenses = response['expenses'] is List
          ? List<dynamic>.from(response['expenses'])
          : [];

      _salaryStructures = response['salaryStructures'] is List
          ? List<dynamic>.from(response['salaryStructures'])
          : [];

      _payrolls = response['payrolls'] is List
          ? List<dynamic>.from(response['payrolls'])
          : [];

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================================
  // EDIT
  // ==========================================================

  Future<void> _openEditScreen() async {
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
      await _loadEmployeeDetails();
    }
  }

  // ==========================================================
  // ARCHIVE
  // ==========================================================

  Future<void> _archiveEmployee() async {
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

      Navigator.pop(context, true);
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

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildPageHeader(mobile),
            _buildProfileStrip(mobile),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else if (_errorMessage != null)
              Expanded(child: _buildErrorState())
            else ...[
                _buildTabBar(),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(mobile),
                        _buildEmploymentTab(mobile),
                        _buildPersonalTab(mobile),
                        _buildBankTab(mobile),
                        _buildAttendanceTab(mobile),
                        _buildLeavesTab(mobile),
                        _buildExpensesTab(mobile),
                        _buildPayrollTab(mobile),
                      ],
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PAGE HEADER
  // ==========================================================

  Widget _buildPageHeader(bool mobile) {
    final busy = _isLoading || _isDeleting;

    return Container(
      width: double.infinity,
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: mobile ? 6 : 16),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: _isDeleting
                  ? null
                  : () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 21,
                color: _textDark,
              ),
            ),
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
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employee Details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'View profile, records and payroll information.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (mobile) ...[
              IconButton(
                tooltip: 'Edit Employee',
                onPressed: busy ? null : _openEditScreen,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 21,
                  color: _textDark,
                ),
              ),
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
                  side: BorderSide(color: _danger.withOpacity(0.4)),
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
              const SizedBox(width: 10),
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
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PROFILE STRIP
  // ==========================================================

  Widget _buildProfileStrip(bool mobile) {
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

    final subtitle = [designation, department]
        .where((value) => value != 'Not available')
        .join('  •  ');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        mobile ? 14 : 24,
        mobile ? 14 : 18,
        mobile ? 14 : 24,
        mobile ? 12 : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: mobile ? 52 : 60,
            height: mobile ? 52 : 60,
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: TextStyle(
                  fontSize: mobile ? 19 : 22,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ),
          SizedBox(width: mobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: mobile ? 19 : 23,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: mobile ? 13 : 14.5,
                      color: _textMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (code != 'Not available')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _pageBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _divider),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _textMedium,
                          ),
                        ),
                      ),
                    _Badge(text: _formatValue(status)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB BAR
  // ==========================================================

  Widget _tab(String label, {int? count}) {
    return Tab(
      height: 46,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _pageBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _divider),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _textMedium,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _divider),
          bottom: BorderSide(color: _border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: _primary,
        unselectedLabelColor: _textMedium,
        indicatorColor: _primary,
        indicatorWeight: 2.5,
        labelPadding: const EdgeInsets.symmetric(horizontal: 18),
        labelStyle: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          _tab('Overview'),
          _tab('Employment'),
          _tab('Personal'),
          _tab('Bank Details'),
          _tab('Attendance', count: _attendance.length),
          _tab('Leaves', count: _leaves.length),
          _tab('Expenses', count: _expenses.length),
          _tab(
            'Payroll',
            count: _payrolls.length + _salaryStructures.length,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB WRAPPER (each tab scrolls + pull to refresh)
  // ==========================================================

  Widget _tabScroll(bool mobile, List<Widget> children) {
    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadEmployeeDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          mobile ? 14 : 24,
          20,
          mobile ? 14 : 24,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // ==========================================================
  // OVERVIEW TAB
  // ==========================================================

  Widget _buildOverviewTab(bool mobile) {
    return _tabScroll(mobile, [
      _section(
        title: 'Summary',
        child: _grid([
          _statTile(
            'Attendance Records',
            _attendance.length,
            Icons.access_time_outlined,
            4,
          ),
          _statTile(
            'Leave Records',
            _leaves.length,
            Icons.event_busy_outlined,
            5,
          ),
          _statTile(
            'Expense Records',
            _expenses.length,
            Icons.receipt_long_outlined,
            6,
          ),
          _statTile(
            'Salary Structures',
            _salaryStructures.length,
            Icons.payments_outlined,
            7,
          ),
          _statTile(
            'Payroll Records',
            _payrolls.length,
            Icons.account_balance_wallet_outlined,
            7,
          ),
        ]),
      ),
      _section(
        title: 'Key Details',
        last: true,
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
    ]);
  }

  Widget _statTile(String label, int value, IconData icon, int tabIndex) {
    return InkWell(
      onTap: () => _tabController.animateTo(tabIndex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: _primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
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
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFB6BDC8),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPLOYMENT TAB
  // ==========================================================

  Widget _buildEmploymentTab(bool mobile) {
    return _tabScroll(mobile, [
      _section(
        title: 'Employment Information',
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
      _section(
        title: 'Company',
        last: true,
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
    ]);
  }

  // ==========================================================
  // PERSONAL TAB
  // ==========================================================

  Widget _buildPersonalTab(bool mobile) {
    return _tabScroll(mobile, [
      _section(
        title: 'Contact Information',
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
      _section(
        title: 'Personal Information',
        last: true,
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
    ]);
  }

  // ==========================================================
  // BANK TAB
  // ==========================================================

  Widget _buildBankTab(bool mobile) {
    return _tabScroll(mobile, [
      _section(
        title: 'Bank Details',
        last: true,
        child: _grid([
          _field(
            'Account Number',
            _bankValue('accountNumber'),
            Icons.account_balance,
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
      ),
    ]);
  }

  // ==========================================================
  // RECORD TABS
  // ==========================================================

  Widget _buildAttendanceTab(bool mobile) {
    return _tabScroll(mobile, [
      _section(
        title: 'Attendance Records (${_attendance.length})',
        last: true,
        child: _recordsView(
          _attendance,
          emptyText: 'No attendance records found.',
          emptyIcon: Icons.access_time_outlined,
        ),
      ),
    ]);
  }

  Widget _buildLeavesTab(bool mobile) {
    return _tabScroll(mobile, [
      _section(
        title: 'Leave Records (${_leaves.length})',
        last: true,
        child: _recordsView(
          _leaves,
          emptyText: 'No leave records found.',
          emptyIcon: Icons.event_busy_outlined,
        ),
      ),
    ]);
  }

  Widget _buildExpensesTab(bool mobile) {
    return _tabScroll(mobile, [
      _section(
        title: 'Expense Records (${_expenses.length})',
        last: true,
        child: _recordsView(
          _expenses,
          emptyText: 'No expense records found.',
          emptyIcon: Icons.receipt_long_outlined,
        ),
      ),
    ]);
  }

  Widget _buildPayrollTab(bool mobile) {
    return _tabScroll(mobile, [
      _section(
        title: 'Salary Structures (${_salaryStructures.length})',
        child: _recordsView(
          _salaryStructures,
          emptyText: 'No salary structures found.',
          emptyIcon: Icons.payments_outlined,
        ),
      ),
      _section(
        title: 'Payroll Records (${_payrolls.length})',
        last: true,
        child: _recordsView(
          _payrolls,
          emptyText: 'No payroll records found.',
          emptyIcon: Icons.account_balance_wallet_outlined,
        ),
      ),
    ]);
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

        if (width < 700) {
          return _recordCards(records);
        }

        final maxColumns = width >= 1100 ? 7 : (width >= 900 ? 6 : 5);

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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ------------------------------------------------
          // HEADER ROW
          // ------------------------------------------------

          Container(
            color: const Color(0xFFFAFBFC),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            child: Row(
              children: columns.map((key) {
                return Expanded(
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
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1, color: _divider),

          // ------------------------------------------------
          // DATA ROWS
          // ------------------------------------------------

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: records.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: _divider,
            ),
            itemBuilder: (context, index) {
              final record = records[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: columns.map((key) {
                    final text = _formatCell(key, record[key]);

                    final isStatus = key.toLowerCase().endsWith('status');

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: isStatus && text != '—'
                            ? Align(
                          alignment: Alignment.centerLeft,
                          child: _Badge(text: text),
                        )
                            : Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: columns.first == key
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: columns.first == key
                                ? _textDark
                                : _textMedium,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- CARDS (PHONE) ----------------

  Widget _recordCards(List<Map<String, dynamic>> records) {
    final columns = _pickColumns(records, 8);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = records[index];

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
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
                ...detailKeys.map((key) {
                  return Padding(
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
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _emptyBox(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(8),
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
  // FORM-STYLE BUILDING BLOCKS
  // ==========================================================

  /// Read-only field: label above, value in a light bordered box.
  Widget _field(String label, String value, IconData icon) {
    final empty = value == 'Not available';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: _pageBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 17, color: _textLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: empty ? _textLight : _textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Responsive grid: 4 / 3 / 2 / 1 columns depending on width.
  Widget _grid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;
        if (width >= 1300) {
          columns = 4;
        } else if (width >= 900) {
          columns = 3;
        } else if (width >= 560) {
          columns = 2;
        } else {
          columns = 1;
        }

        const double gap = 20;

        final itemWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: item,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 16),
          child,
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
              _errorMessage!,
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
    );
  }

  // ==========================================================
  // INITIALS
  // ==========================================================

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