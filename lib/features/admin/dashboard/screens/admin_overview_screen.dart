import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage.dart'; // TODO: fix path if different
import '../../employees/models/admin_employee_model.dart';
import '../../employees/services/admin_csv_download.dart';
import '../../employees/services/admin_employee_csv_service.dart';
import '../../employees/services/admin_employee_profile_service.dart';
import '../../employees/services/admin_employee_service.dart';
import '../../employees/widgets/admin_access_dialog.dart';
import '../../employees/widgets/admin_add_employee_dialog.dart';
import '../../employees/widgets/admin_employee_card.dart';
import '../../employees/widgets/admin_employee_table.dart';
import '../../employees/widgets/admin_employee_theme.dart';
import '../../employees/widgets/admin_salary_dialog.dart';
import '../models/admin_overview_models.dart';
import '../services/admin_overview_service.dart';
import '../widgets/admin_daily_attendance_card.dart';
import '../widgets/admin_overview_pending_card.dart';
import '../widgets/admin_overview_stat_cards.dart';

/// Company Dashboard overview (matches the web):
/// 4 stat cards, Employees table, Pending Leaves + Pending Expenses.
class AdminOverviewScreen extends StatefulWidget {
  final VoidCallback onViewAllEmployees;
  final VoidCallback onViewAllLeaves;
  final VoidCallback onViewAllExpenses;

  /// Person icon -> open this employee's profile.
  final void Function(AdminEmployeeModel employee) onOpenProfile;

  /// Called after something changed (add / archive / approve ...), so the
  /// dashboard can refresh its notification badge.
  final VoidCallback? onDataChanged;

  const AdminOverviewScreen({
    super.key,
    required this.onViewAllEmployees,
    required this.onViewAllLeaves,
    required this.onViewAllExpenses,
    required this.onOpenProfile,
    this.onDataChanged,
  });

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final AdminEmployeeService _emp = AdminEmployeeService();
  final AdminOverviewService _ov = AdminOverviewService();
  final AdminEmployeeProfileService _profileService = AdminEmployeeProfileService();

  bool _loading = true;
  String? _error;

  List<AdminEmployeeModel> _active = [];
  List<AdminEmployeeModel> _archived = [];
  List<AdminPendingLeave> _leaves = [];
  List<AdminPendingExpense> _expenses = [];
  List<String> _departments = AdminEmployeeService.fallbackDepartments;
  int? _maxEmployees;
  String _companyId = '';

  /// phone layout (Android / iOS)
  bool get _compact => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ------------------------------------------------------------
  // data
  // ------------------------------------------------------------

  Future<T> _safe<T>(Future<T> f, T fallback) async {
    try {
      return await f;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      if (_companyId.isEmpty) {
        try {
          _companyId = (await SecureStorage.getCompanyId()) ?? '';
        } catch (_) {}
      }
      final cid = _companyId;

      final results = await Future.wait([
        _emp.getActiveEmployees(),
        _safe(_emp.getArchivedEmployees(), <AdminEmployeeModel>[]),
        _safe(_ov.getPendingLeaves(), <AdminPendingLeave>[]),
        _safe(_ov.getPendingExpenses(), <AdminPendingExpense>[]),
        _safe<int?>(_ov.getMaxEmployees(), null),
        cid.isEmpty ? Future.value(<String, double>{}) : _emp.getSalaryMap(cid),
        cid.isEmpty
            ? Future.value(AdminEmployeeService.fallbackDepartments)
            : _emp.getDepartments(cid),
      ]);

      var active = results[0] as List<AdminEmployeeModel>;
      final salary = results[5] as Map<String, double>;
      active = active.map((e) => e.copyWith(baseSalary: salary[e.id])).toList()
        ..sort((a, b) => b.employeeCode.compareTo(a.employeeCode)); // newest first

      if (!mounted) return;
      setState(() {
        _active = active;
        _archived = results[1] as List<AdminEmployeeModel>;
        _leaves = results[2] as List<AdminPendingLeave>;
        _expenses = results[3] as List<AdminPendingExpense>;
        _maxEmployees = results[4] as int?;
        _departments = results[6] as List<String>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _changed() {
    _load(silent: true);
    widget.onDataChanged?.call();
  }

  /// Employee name for a leave / expense when the API did not populate it.
  String _nameFor(String employeeId, String given) {
    if (given.trim().isNotEmpty) return given;
    for (final e in _active) {
      if (e.id == employeeId || e.userId == employeeId) return e.name;
    }
    return 'Employee';
  }

  // ------------------------------------------------------------
  // actions
  // ------------------------------------------------------------

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AdminEmpColors.danger : AdminEmpColors.text,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addEmployee() async {
    final created = await AdminAddEmployeeDialog.show(
      context,
      service: _emp,
      departments: _departments,
    );
    if (created == true) {
      if (!mounted) return;
      _toast('Employee added successfully');
      _changed();
    }
  }

  Future<void> _exportCsv() async {
    if (_active.isEmpty) {
      _toast('No employees to export', error: true);
      return;
    }
    try {
      final csv = AdminEmployeeCsvService.build(_active);
      final downloaded = await adminSaveCsv(AdminEmployeeCsvService.fileName(), csv);
      if (!mounted) return;
      _toast(downloaded
          ? 'Employee directory exported'
          : 'CSV copied to clipboard (paste it into Excel / Sheets)');
    } catch (e) {
      if (!mounted) return;
      _toast('Export failed: $e', error: true);
    }
  }

  Future<void> _openAccess(AdminEmployeeModel e) async {
    final saved = await AdminAccessDialog.show(context, service: _emp, employee: e);
    if (saved == true) {
      if (!mounted) return;
      _toast('Access & credentials updated');
      _changed();
    }
  }

  Future<void> _openSalary(AdminEmployeeModel e) async {
    final saved = await AdminSalaryDialog.show(context, service: _emp, employee: e);
    if (saved == true) {
      if (!mounted) return;
      _toast('Salary saved');
      _changed();
    }
  }

  Future<void> _archive(AdminEmployeeModel e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Archive employee?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('${e.name} will be moved to the Archive tab. You can restore later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: AdminEmpColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _emp.archiveEmployee(e.id);
      if (!mounted) return;
      _toast('Employee archived');
      _changed();
    } catch (err) {
      if (!mounted) return;
      _toast(err.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  /// Runs an approve / reject call, then reloads everything.
  Future<void> _decide(Future<void> Function() call, String message) async {
    await call();
    if (!mounted) return;
    _toast(message);
    _changed();
  }

  // ------------------------------------------------------------
  // build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AdminEmpColors.primary));
    }
    if (_error != null) return _errorState();

    final width = MediaQuery.of(context).size.width;
    final wide = width >= 800;
    final compact = width < 600;
    final pad = wide ? 28.0 : (compact ? 12.0 : 14.0);
    final gap = compact ? 14.0 : 24.0;

    return Container(
      color: AdminEmpColors.bg,
      child: RefreshIndicator(
        color: AdminEmpColors.primary,
        onRefresh: () => _load(silent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, compact ? 14 : 22, pad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminOverviewStatCards(
                activeValue: _maxEmployees == null
                    ? '${_active.length}'
                    : '${_active.length} / $_maxEmployees',
                pendingLeaves: _leaves.length,
                pendingExpenses: _expenses.length,
                archived: _archived.length,
              ),
              SizedBox(height: gap),
              // daily check-in / check-out list (change the day to change the list)
              AdminDailyAttendanceCard(
                employees: _active,
                companyId: _companyId,
                service: _ov,
              ),
              SizedBox(height: gap),
              _employeesCard(),
              SizedBox(height: gap),
              _pendingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminEmpColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: AdminEmpColors.danger),
            const SizedBox(height: 14),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminEmpColors.muted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 46),
                backgroundColor: AdminEmpColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // employees card
  // ------------------------------------------------------------

  Widget _employeesCard() {
    final compact = _compact;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: const Color(0xFFEDEFF3)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFB),
                border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
              ),
              child: _employeesHeader(),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: _employeesHeader(),
            ),
          if (_active.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No active employees. Add your first employee to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AdminEmpColors.muted, fontSize: 15),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth >= 980) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AdminEmployeeTable(
                        employees: _active,
                        archived: false,
                        onAccess: _openAccess,
                        onSalary: _openSalary,
                        onProfile: widget.onOpenProfile,
                        onArchive: _archive,
                        onRestore: (_) {},
                        onDeleteForever: (_) {},
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: compact
                      ? const EdgeInsets.fromLTRB(10, 12, 10, 4)
                      : const EdgeInsets.fromLTRB(14, 0, 14, 6),
                  child: Column(
                    children: [
                      for (final e in _active)
                        AdminEmployeeCard(
                          employee: e,
                          archived: false,
                          onAccess: () => _openAccess(e),
                          onSalary: () => _openSalary(e),
                          onProfile: () => widget.onOpenProfile(e),
                          onArchive: () => _archive(e),
                          onRestore: () {},
                          onDeleteForever: () {},
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _employeesHeader() {
    final compact = _compact;
    final h = compact ? 38.0 : 46.0;
    final fs = compact ? 13.0 : 14.0;

    final titleText = Text(
      'Employees (${_active.length})',
      style: TextStyle(
        fontSize: compact ? 16 : 20,
        fontWeight: FontWeight.w700,
        color: AdminEmpColors.text,
      ),
    );

    final Widget title = compact
        ? Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AdminEmpColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.people_alt_outlined, size: 19, color: AdminEmpColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(child: titleText),
      ],
    )
        : titleText;

    OutlinedButton outlined(String label, VoidCallback onTap) => OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, h),
        foregroundColor: AdminEmpColors.text,
        side: const BorderSide(color: AdminEmpColors.border),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: fs),
        ),
      ),
    );

    ElevatedButton addBtn() => ElevatedButton(
      onPressed: _addEmployee,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(0, h),
        backgroundColor: AdminEmpColors.primary,
        foregroundColor: Colors.white,
        elevation: compact ? 0 : 2,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '+ Add Employee',
          maxLines: 1,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: fs),
        ),
      ),
    );

    // PHONE: title, then ONE row with 3 buttons
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(flex: 10, child: outlined('Export CSV', _exportCsv)),
              const SizedBox(width: 8),
              Expanded(flex: 12, child: addBtn()),
              const SizedBox(width: 8),
              Expanded(flex: 9, child: outlined('View All', widget.onViewAllEmployees)),
            ],
          ),
        ],
      );
    }

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        outlined('Export CSV', _exportCsv),
        addBtn(),
        outlined('View All', widget.onViewAllEmployees),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), actions],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [title, actions],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // pending leaves + expenses
  // ------------------------------------------------------------

  Widget _pendingSection() {
    const maxRows = 5;

    final leaveRows = _leaves.take(maxRows).map((l) {
      final start = adminEmpFormatDate(l.startDate);
      final sameDay = l.endDate == null ||
          (l.startDate != null &&
              l.endDate!.toUtc().difference(l.startDate!.toUtc()).inDays == 0);
      final range = sameDay ? start : '$start → ${adminEmpFormatDate(l.endDate)}';

      return AdminPendingRowData(
        title: _nameFor(l.employeeId, l.employeeName),
        subtitle: '${l.leaveType.isEmpty ? 'Leave' : l.leaveType} · $range',
        onApprove: () => _decide(() => _profileService.approveLeave(l.id), 'Leave approved'),
        onReject: () => _decide(() => _profileService.rejectLeave(l.id), 'Leave rejected'),
      );
    }).toList();

    final expenseRows = _expenses.take(maxRows).map((x) {
      final category = x.category.isEmpty
          ? 'Expense'
          : x.category[0].toUpperCase() + x.category.substring(1);

      return AdminPendingRowData(
        title: _nameFor(x.employeeId, x.employeeName),
        subtitle: '$category · ${adminEmpRupees(x.amount)}',
        onApprove: () => _decide(() => _profileService.approveExpense(x.id), 'Expense approved'),
        onReject: () => _decide(() => _profileService.rejectExpense(x.id), 'Expense rejected'),
      );
    }).toList();

    final leaves = AdminOverviewPendingCard(
      title: 'Pending Leaves',
      count: _leaves.length,
      emptyText: 'No pending leave requests',
      onViewAll: widget.onViewAllLeaves,
      rows: leaveRows,
    );

    final expenses = AdminOverviewPendingCard(
      title: 'Pending Expenses',
      count: _expenses.length,
      emptyText: 'No pending expenses',
      onViewAll: widget.onViewAllExpenses,
      rows: expenseRows,
    );

    final vGap = _compact ? 14.0 : 20.0;

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
          return Column(children: [leaves, SizedBox(height: vGap), expenses]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leaves),
            const SizedBox(width: 24),
            Expanded(child: expenses),
          ],
        );
      },
    );
  }
}