import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import '../models/payroll_reports_model.dart';
import '../models/payroll_request.dart';
import '../models/payroll_slip_model.dart';
import '../models/salary_structure_model.dart';
import '../services/payroll_service.dart';
import '../widgets/employee_access_dialog.dart';
import '../widgets/employee_salary_list.dart';
import '../widgets/payroll_batch_table.dart';
import '../widgets/payroll_csv.dart';
import '../widgets/payroll_format.dart';
import '../widgets/payroll_reports_tabs.dart';
import '../widgets/payslip_dialog.dart';
import '../widgets/set_salary_dialog.dart';

class PayrollScreen extends StatefulWidget {
  /// True when shown inside the admin dashboard (the sidebar stays visible).
  final bool embedded;

  const PayrollScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen>
    with SingleTickerProviderStateMixin {
  // Palette copied from AdminDashboardScreen.
  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);
  static const Color _danger = Color(0xFFDC2626);
  static const double _mobileBreakpoint = 700;

  final PayrollService _service = PayrollService();
  final EmployeeService _employeeService = EmployeeService();

  late final TabController _tab;

  late int _month;
  late int _year;

  /// Changes with the month / year so late responses are ignored.
  int _period = 0;

  // Monthly payroll batch
  List<PayrollSlip>? _slips;
  bool _slipsLoading = false;
  String? _slipsError;

  // PT report
  PtReport? _pt;
  bool _ptLoading = false;
  String? _ptError;

  // PF report
  PfReport? _pf;
  bool _pfLoading = false;
  String? _pfError;

  // Employees + salary structures
  List<Employee> _employees = const [];
  Map<String, SalaryStructure> _structures = const {};
  bool _employeesLoading = false;
  String? _employeesError;
  String? _structuresError;

  /// Generate / e-mail / refund in progress (blocks duplicates).
  bool _busy = false;

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  /// The payroll rows with employee names filled in.
  List<PayrollSlip>? get _displaySlips {
    final slips = _slips;
    if (slips == null || _employees.isEmpty) return slips;

    final byId = {for (final e in _employees) e.id: e};
    final byCode = {
      for (final e in _employees)
        if (e.employeeCode.isNotEmpty) e.employeeCode: e,
    };

    return slips.map((s) {
      final e = byId[s.employeeId] ?? byCode[s.employeeCode];
      if (e == null) return s;

      return s.withIdentity(
        name: s.employeeName.isEmpty ? e.name : null,
        code: s.employeeCode.isEmpty ? e.employeeCode : null,
        department: s.department.isEmpty ? e.department : null,
      );
    }).toList();
  }

  Future<void> _openSlip(PayrollSlip slip) async {
    var full = slip;

    if (full.designation.isEmpty ||
        full.department.isEmpty ||
        full.employeeName.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        full = await _withEmployeeDetails(full);
      } catch (_) {}

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;
    await PayslipDialog.show(context, full);
  }

  Future<PayrollSlip> _withEmployeeDetails(PayrollSlip slip) async {
    if (slip.employeeId.isEmpty) return slip;

    final details = await _employeeService.getEmployeeById(slip.employeeId);

    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

    String text(dynamic v) {
      if (v is Map) return (v['name'] ?? '').toString().trim();
      return v?.toString().trim() ?? '';
    }

    String pick(List<dynamic> values) {
      for (final v in values) {
        final t = text(v);
        if (t.isNotEmpty) return t;
      }
      return '';
    }

    final employee = asMap(details['employee']);
    final user = asMap(details['user']);

    return slip.withIdentity(
      name: slip.employeeName.isEmpty
          ? pick([user['name'], employee['name'], details['name']])
          : null,
      department: slip.department.isEmpty
          ? pick([employee['department'], details['department']])
          : null,
      designation: slip.designation.isEmpty
          ? pick([employee['designation'], details['designation']])
          : null,
    );
  }

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _month = now.month;
    _year = now.year;

    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(_onTabChanged);

    _loadSlips();
    _loadEmployees();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ==========================================================
  // GENERAL HELPERS
  // ==========================================================

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  String? _messageFor(Object error, String fallback) {
    if (error is PayrollException) {
      if (error.isAuthError) {
        _goToLogin();
        return null;
      }
      return error.message;
    }

    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      final message = text.substring('Exception: '.length).trim();

      if (message.startsWith('Session expired') ||
          message.startsWith('Authentication required')) {
        _goToLogin();
        return null;
      }
      return message;
    }

    return fallback;
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? _danger : null,
        ),
      );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _primary),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result == true;
  }

  String get _periodLabel => '${PayrollFormat.monthName(_month)} $_year';

  // ==========================================================
  // LOADERS
  // ==========================================================

  Future<void> _loadSlips() async {
    final period = _period;

    setState(() {
      _slipsLoading = true;
      _slipsError = null;
    });

    try {
      final data = await _service.fetchPayroll(_month, _year);
      if (!mounted || period != _period) return;

      setState(() {
        _slips = data;
        _slipsLoading = false;
      });
    } catch (e) {
      if (!mounted || period != _period) return;

      final message = _messageFor(e, 'Could not load payroll.');
      if (message == null) return;

      setState(() {
        _slipsLoading = false;
        _slipsError = message;
      });
    }
  }

  Future<void> _loadPt() async {
    final period = _period;

    setState(() {
      _ptLoading = true;
      _ptError = null;
    });

    try {
      final data = await _service.fetchPtReport(_month, _year);
      if (!mounted || period != _period) return;

      setState(() {
        _pt = data;
        _ptLoading = false;
      });
    } catch (e) {
      if (!mounted || period != _period) return;

      final message = _messageFor(e, 'Could not load the PT report.');
      if (message == null) return;

      setState(() {
        _ptLoading = false;
        _ptError = message;
      });
    }
  }

  Future<void> _loadPf() async {
    final period = _period;

    setState(() {
      _pfLoading = true;
      _pfError = null;
    });

    try {
      final data = await _service.fetchPfReport(_month, _year);
      if (!mounted || period != _period) return;

      setState(() {
        _pf = data;
        _pfLoading = false;
      });
    } catch (e) {
      if (!mounted || period != _period) return;

      final message = _messageFor(e, 'Could not load the PF report.');
      if (message == null) return;

      setState(() {
        _pfLoading = false;
        _pfError = message;
      });
    }
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _employeesLoading = true;
      _employeesError = null;
    });

    try {
      final employees = await _employeeService.getEmployees(status: 'active');
      if (!mounted) return;

      setState(() {
        _employees = employees;
        _employeesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final message = _messageFor(e, 'Could not load employees.');
      if (message == null) return;

      setState(() {
        _employeesLoading = false;
        _employeesError = message;
      });
      return;
    }

    await _loadStructures();
  }

  Future<void> _loadStructures() async {
    try {
      final list = await _service.fetchStructures();
      if (!mounted) return;

      setState(() {
        _structures = {for (final s in list) s.employeeId: s};
        _structuresError = null;
      });
    } catch (e) {
      if (!mounted) return;

      final message = _messageFor(e, 'Could not load salaries.');
      if (message == null) return;

      setState(() => _structuresError = message);
    }
  }

  void _onTabChanged() {
    if (_tab.indexIsChanging) return;

    if (_tab.index == 1 && _pt == null && !_ptLoading) _loadPt();
    if (_tab.index == 2 && _pf == null && !_pfLoading) _loadPf();

    if (mounted) setState(() {});
  }

  void _reloadActiveReport() {
    if (_tab.index == 1) _loadPt();
    if (_tab.index == 2) _loadPf();
  }

  // ==========================================================
  // PERIOD
  // ==========================================================

  void _setPeriod({int? month, int? year}) {
    if (_busy) return;

    setState(() {
      _month = month ?? _month;
      _year = year ?? _year;
      _period++;

      _slips = null;
      _pt = null;
      _pf = null;
      _slipsError = null;
      _ptError = null;
      _pfError = null;
    });

    _loadSlips();
    _reloadActiveReport();
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Future<void> _generate() async {
    if (_busy) return;

    final ok = await _confirm(
      title: 'Calculate & generate payroll?',
      message:
      'This calculates payroll for $_periodLabel for all employees. '
          'Payslips that are already marked paid are skipped and will not '
          'change.',
      confirmLabel: 'Generate',
    );

    if (!ok || !mounted) return;

    setState(() => _busy = true);

    try {
      final result = await _service.generate(_month, _year);
      if (!mounted) return;

      _pt = null;
      _pf = null;

      await _loadSlips();
      _reloadActiveReport();

      if (!mounted) return;

      _toast(
        result.isEmpty
            ? 'Payroll calculated for $_periodLabel.'
            : 'Payroll generated for $_periodLabel (${result.length} payslips).',
      );
    } catch (e) {
      if (!mounted) return;

      final message = _messageFor(e, 'Could not generate payroll.');
      if (message != null) _toast(message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailAll() async {
    if (_busy) return;

    final ok = await _confirm(
      title: 'Email all payslips?',
      message:
      'This sends the $_periodLabel payslips to every employee by '
          'email.',
      confirmLabel: 'Send emails',
    );

    if (!ok || !mounted) return;

    setState(() => _busy = true);

    try {
      await _service.sendEmails(
        SendPayslipEmailsRequest(month: _month, year: _year),
      );
      if (!mounted) return;

      await _loadSlips();
      if (!mounted) return;

      _toast('Payslip emails requested for $_periodLabel.');
    } catch (e) {
      if (!mounted) return;

      final message = _messageFor(e, 'Could not send payslip emails.');
      if (message != null) _toast(message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() async {
    final slips = _displaySlips;
    if (slips == null || slips.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: PayrollCsv.build(slips)));
    if (!mounted) return;

    _toast('CSV for $_periodLabel copied to the clipboard.');
  }

  Future<void> _refundPf(PfBalance balance) async {
    if (_busy) return;

    final ok = await _confirm(
      title: 'Refund full PF?',
      message:
      'Record a PF refund of ${PayrollFormat.rupees(balance.pending)} '
          'for ${balance.name}'
          '${balance.code.isEmpty ? '' : ' (${balance.code})'}? The full '
          'pending balance will be refunded.',
      confirmLabel: 'Refund',
    );

    if (!ok || !mounted) return;

    setState(() => _busy = true);

    try {
      await _service.refundPf(PfRefundRequest(employeeId: balance.employeeId));
      if (!mounted) return;

      await _loadPf();
      if (!mounted) return;

      _toast('PF refund recorded for ${balance.name}.');
    } catch (e) {
      if (!mounted) return;

      final message = _messageFor(e, 'Could not record the PF refund.');
      if (message != null) _toast(message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setSalary(Employee employee) async {
    final saved = await SetSalaryDialog.show(
      context,
      employeeId: employee.id,
      employeeName: employee.name,
      current: _structures[employee.id],
    );

    if (saved != true || !mounted) return;

    await _loadStructures();
    if (!mounted) return;

    _toast(
      'Salary saved for ${employee.name}. Calculate payroll again to apply '
          'it to $_periodLabel.',
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile;

    // Core body content
    final bodyContent = SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 14 : 22,
          mobile ? 16 : 22,
          mobile ? 14 : 22,
          35,
        ),
        children: [
          Text(
            'Company Admin  /  Payroll & Salary Slips',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          _header(mobile),
          const SizedBox(height: 16),

          // 1. The Tab Card (Monthly Batch, PT, PF)
          _tabsCard(mobile),

          // 2. The Employee Table (ALWAYS VISIBLE NOW)
          const SizedBox(height: 16),
          EmployeeSalaryList(
            employees: _employees,
            structures: _structures,
            loading: _employeesLoading,
            error: _employeesError,
            structuresError: _structuresError,
            onRetry: _loadEmployees,
            onSetSalary: _setSalary,
            onEditAccess: (e) {
              EmployeeAccessDialog.show(
                context,
                employeeName: e.name,
                email: e.email,
                workMode: e.workMode,
                portalAccess: true,
              );
            },
            onViewProfile: (e) {
              _toast('Profile view for ${e.name}');
            },
            onDelete: (e) async {
              final ok = await _confirm(
                title: 'Delete Employee?',
                message: 'Are you sure you want to delete ${e.name}?',
                confirmLabel: 'Delete',
              );
              if (ok) {
                _toast('Deleting ${e.name}...');
              }
            },
          ),
        ],
      ),
    );

    // Embedded: return only the body so the dashboard shell stays visible
    if (widget.embedded) {
      return Container(
        color: _pageBg,
        child: bodyContent,
      );
    }

    // Standalone: full screen with its own Scaffold and AppBar
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Payroll & Salary',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: bodyContent,
    );
  }
  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _header(bool mobile) {
    final now = DateTime.now();
    final years = <int>{
      for (var y = now.year - 3; y <= now.year + 1; y++) y,
      _year,
    }.toList()..sort();

    final title = Text(
      'Payroll & Salary Engine',
      style: TextStyle(
        fontSize: mobile ? 17 : 19,
        fontWeight: FontWeight.w700,
        color: _textDark,
      ),
    );

    final month = _dropdown(
      value: _month,
      items: {for (var m = 1; m <= 12; m++) m: PayrollFormat.monthName(m)},
      onChanged: (v) => _setPeriod(month: v),
      width: 150,
    );

    final year = _dropdown(
      value: _year,
      items: {for (final y in years) y: '$y'},
      onChanged: (v) => _setPeriod(year: v),
      width: 110,
    );

    final slips = _slips;
    final hasSlips = slips != null && slips.isNotEmpty;

    ButtonStyle outlined() => OutlinedButton.styleFrom(
      foregroundColor: _textDark,
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
    );

    final export = OutlinedButton(
      onPressed: hasSlips ? _exportCsv : null,
      style: outlined(),
      child: const Text('Export CSV'),
    );

    final email = OutlinedButton(
      onPressed: (hasSlips && !_busy) ? _emailAll : null,
      style: outlined(),
      child: const Text('Email All Payslips'),
    );

    final generate = FilledButton(
      onPressed: _busy ? null : _generate,
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
      ),
      child: _busy
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : const Text('Calculate & Generate Payroll'),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          title,
          month,
          year,
          if (!mobile) const SizedBox(width: 20),
          export,
          email,
          generate,
        ],
      ),
    );
  }

  Widget _dropdown({
    required int value,
    required Map<int, String> items,
    required ValueChanged<int> onChanged,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9DEE7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9DEE7)),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            isExpanded: true,
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            style: const TextStyle(fontSize: 14, color: _textDark),
            onChanged: _busy
                ? null
                : (v) {
              if (v != null) onChanged(v);
            },
            items: [
              for (final entry in items.entries)
                DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TABS
  // ==========================================================

  Widget _tabsCard(bool mobile) {
    final count = _slips == null ? '' : ' (${_slips!.length})';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _primary,
            unselectedLabelColor: _textDark,
            indicatorColor: _primary,
            dividerColor: const Color(0xFFEDEFF3),
            labelStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'Monthly Payroll Batch$count'),
              const Tab(text: 'PT Compliance Report'),
              const Tab(text: 'PF (5%) Accumulation & Refund History'),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(mobile ? 12 : 20),
            child: _tabContent(),
          ),
        ],
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab.index) {
      case 1:
        return PayrollPtTab(
          report: _pt,
          loading: _ptLoading,
          error: _ptError,
          month: _month,
          year: _year,
          onRetry: _loadPt,
        );
      case 2:
        return PayrollPfTab(
          report: _pf,
          loading: _pfLoading,
          error: _pfError,
          busy: _busy,
          onRetry: _loadPf,
          onRefund: _refundPf,
          employees: _employees, // <-- ADD THIS LINE
        );
      default:
        return _batchTab();
    }
  }
  Widget _batchTab() {
    final slips = _displaySlips;
    if (slips == null && _slipsError != null && !_slipsLoading) {
      return _message(
        text: _slipsError!,
        icon: Icons.error_outline_rounded,
        action: FilledButton.icon(
          onPressed: _loadSlips,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
          style: FilledButton.styleFrom(backgroundColor: _primary),
        ),
      );
    }

    if (slips == null) {
      return PayrollBatchTable(
        slips: const [],
        isLoading: true,
        onViewSlip: (_) {},
      );
    }

    if (slips.isEmpty && !_slipsLoading) {
      return _message(
        text:
        'No payroll has been generated for $_periodLabel yet. Press '
            '"Calculate & Generate Payroll" to create it.',
        icon: Icons.payments_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_slipsError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF5DDA3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$_slipsError Showing the last loaded data.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _slipsLoading ? null : _loadSlips,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        PayrollBatchTable(
          slips: slips,
          isLoading: _slipsLoading,
          onViewSlip: _openSlip,
        ),
      ],
    );
  }

  Widget _message({
    required String text,
    required IconData icon,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
          ),
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }
}