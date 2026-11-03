import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage.dart'; // TODO: fix path if different
import '../../employees/models/admin_employee_access.dart';
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
///
/// PERMISSION: the canSee... flags decide which parts this role gets, and
/// [employeeAccess] decides what it may do inside the Employees card.
/// All default to "allowed", so a screen that does not pass them behaves as before.
class AdminOverviewScreen extends StatefulWidget {
  final VoidCallback onViewAllEmployees;
  final VoidCallback onViewAllLeaves;
  final VoidCallback onViewAllExpenses;

  /// Person icon -> open this employee's profile.
  final void Function(AdminEmployeeModel employee) onOpenProfile;

  /// Called after something changed (add / archive / approve ...), so the
  /// dashboard can refresh its notification badge.
  final VoidCallback? onDataChanged;

  /// PERMISSION: Employees card, Active + Archived stat cards.
  final bool canSeeEmployees;

  /// PERMISSION: Daily Check-In & Check-Out card.
  final bool canSeeAttendance;

  /// PERMISSION: Pending Leaves stat card + list.
  final bool canSeeLeaves;

  /// PERMISSION: Pending Expenses stat card + list.
  final bool canSeeExpenses;

  /// PERMISSION: what this role may do in the Employees card
  /// (add / edit / archive / see salary).
  final AdminEmployeeAccess employeeAccess;

  const AdminOverviewScreen({
    super.key,
    required this.onViewAllEmployees,
    required this.onViewAllLeaves,
    required this.onViewAllExpenses,
    required this.onOpenProfile,
    this.onDataChanged,
    this.canSeeEmployees = true,
    this.canSeeAttendance = true,
    this.canSeeLeaves = true,
    this.canSeeExpenses = true,
    this.employeeAccess = AdminEmployeeAccess.full,
  });

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final AdminEmployeeService _emp = AdminEmployeeService();
  final AdminOverviewService _ov = AdminOverviewService();
  final AdminEmployeeProfileService _profileService = AdminEmployeeProfileService();

  AdminEmployeeAccess get _access => widget.employeeAccess;

  bool _loading = true;
  String? _error;

  List<AdminEmployeeModel> _active = [];
  List<AdminEmployeeModel> _archived = [];
  List<AdminPendingLeave> _leaves = [];
  List<AdminPendingExpense> _expenses = [];
  List<String> _departments = AdminEmployeeService.fallbackDepartments;
  int? _maxEmployees;
  String _companyId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// PERMISSION: if the allowed parts change (role loaded / refreshed),
  /// load again so the newly allowed parts have their data.
  @override
  void didUpdateWidget(covariant AdminOverviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canSeeEmployees != widget.canSeeEmployees ||
        oldWidget.canSeeAttendance != widget.canSeeAttendance ||
        oldWidget.canSeeLeaves != widget.canSeeLeaves ||
        oldWidget.canSeeExpenses != widget.canSeeExpenses ||
        oldWidget.employeeAccess != widget.employeeAccess) {
      _load();
    }
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

      final seeEmployees = widget.canSeeEmployees;
      final seeLeaves = widget.canSeeLeaves;
      final seeExpenses = widget.canSeeExpenses;
      final seeSalary = seeEmployees && _access.canSeeSalary;

      // PERMISSION: only ask the server for what this role may see.
      // (The active list is always needed: names for leave / expense rows
      // and the check-in card.)
      final results = await Future.wait([
        _emp.getActiveEmployees(),
        seeEmployees
            ? _safe(_emp.getArchivedEmployees(), <AdminEmployeeModel>[])
            : Future.value(<AdminEmployeeModel>[]),
        seeLeaves
            ? _safe(_ov.getPendingLeaves(), <AdminPendingLeave>[])
            : Future.value(<AdminPendingLeave>[]),
        seeExpenses
            ? _safe(_ov.getPendingExpenses(), <AdminPendingExpense>[])
            : Future.value(<AdminPendingExpense>[]),
        seeEmployees ? _safe<int?>(_ov.getMaxEmployees(), null) : Future<int?>.value(null),
        // salary only for roles that may see it
        (!seeSalary || cid.isEmpty)
            ? Future.value(<String, double>{})
            : _emp.getSalaryMap(cid),
        (!seeEmployees || cid.isEmpty)
            ? Future.value(AdminEmployeeService.fallbackDepartments)
            : _emp.getDepartments(cid),
      ]);

      var active = results[0] as List<AdminEmployeeModel>;
      final salary = results[5] as Map<String, double>;
      if (seeSalary) {
        active = active.map((e) => e.copyWith(baseSalary: salary[e.id])).toList();
      }
      active.sort((a, b) => b.employeeCode.compareTo(a.employeeCode)); // newest first

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
    if (!_access.canCreate) return; // PERMISSION
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
    if (!_access.canEdit) return; // PERMISSION
    final saved = await AdminAccessDialog.show(context, service: _emp, employee: e);
    if (saved == true) {
      if (!mounted) return;
      _toast('Access & credentials updated');
      _changed();
    }
  }

  Future<void> _openSalary(AdminEmployeeModel e) async {
    if (!_access.canManageSalary) return; // PERMISSION
    final saved = await AdminSalaryDialog.show(context, service: _emp, employee: e);
    if (saved == true) {
      if (!mounted) return;
      _toast('Salary saved');
      _changed();
    }
  }

  Future<void> _archive(AdminEmployeeModel e) async {
    if (!_access.canDelete) return; // PERMISSION
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

    final wide = MediaQuery.of(context).size.width >= 800;
    final pad = wide ? 28.0 : 14.0;

    // PERMISSION: only the parts this role may see are added (24 px apart).
    final parts = <Widget>[];
    void add(Widget w) {
      if (parts.isNotEmpty) parts.add(const SizedBox(height: 24));
      parts.add(w);
    }

    if (widget.canSeeEmployees || widget.canSeeLeaves || widget.canSeeExpenses) {
      add(AdminOverviewStatCards(
        activeValue: _maxEmployees == null
            ? '${_active.length}'
            : '${_active.length} / $_maxEmployees',
        pendingLeaves: _leaves.length,
        pendingExpenses: _expenses.length,
        archived: _archived.length,
        showActive: widget.canSeeEmployees,
        showArchived: widget.canSeeEmployees,
        showLeaves: widget.canSeeLeaves,
        showExpenses: widget.canSeeExpenses,
      ));
    }

    if (widget.canSeeAttendance) {
      // daily check-in / check-out list (change the day to change the list)
      add(AdminDailyAttendanceCard(
        employees: _active,
        companyId: _companyId,
        service: _ov,
      ));
    }

    if (widget.canSeeEmployees) add(_employeesCard());

    if (widget.canSeeLeaves || widget.canSeeExpenses) add(_pendingSection());

    if (parts.isEmpty) add(_nothingToShow());

    return Container(
      color: AdminEmpColors.bg,
      child: RefreshIndicator(
        color: AdminEmpColors.primary,
        onRefresh: () => _load(silent: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 22, pad, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: parts,
          ),
        ),
      ),
    );
  }

  /// PERMISSION: shown only when a role has the dashboard but none of its parts.
  Widget _nothingToShow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: const Center(
        child: Text(
          'Welcome. Use the menu on the left to open your screens.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AdminEmpColors.muted, fontSize: 15),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF3)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 700;
              return Padding(
                // phone: same side padding (14) as the employee rows below
                padding: EdgeInsets.fromLTRB(narrow ? 14 : 24, narrow ? 18 : 22, narrow ? 14 : 24, narrow ? 14 : 18),
                child: _employeesHeader(narrow),
              );
            },
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
                        access: _access,
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
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                  child: Column(
                    children: [
                      for (final e in _active.take(5))
                        AdminEmployeeCard(
                          employee: e,
                          archived: false,
                          access: _access,
                          onAccess: () => _openAccess(e),
                          onSalary: () => _openSalary(e),
                          onProfile: () => widget.onOpenProfile(e),
                          onArchive: () => _archive(e),
                          onRestore: () {},
                          onDeleteForever: () {},
                        ),
                      if (_active.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 8),
                          child: TextButton(
                            onPressed: widget.onViewAllEmployees,
                            child: Text(
                              'View all employees (${_active.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AdminEmpColors.primary,
                              ),
                            ),
                          ),
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

  Widget _employeesHeader(bool narrow) {
    final title = Text(
      'Employees (${_active.length})',
      style: TextStyle(
        fontSize: narrow ? 19 : 20,
        fontWeight: FontWeight.w700,
        color: AdminEmpColors.text,
      ),
    );

    // ---------- phone ----------
    //  Employees (5)                      [ View All ]
    //  [   Export CSV   ]  [ + Add Employee ]
    // PERMISSION: "+ Add Employee" needs create rights.
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: title),
              OutlinedButton(
                onPressed: widget.onViewAllEmployees,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  foregroundColor: AdminEmpColors.text,
                  side: const BorderSide(color: AdminEmpColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View All', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _exportCsv,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: AdminEmpColors.text,
                    side: const BorderSide(color: AdminEmpColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Export CSV', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
              ),
              if (_access.canCreate) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addEmployee,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: AdminEmpColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('+ Add Employee', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // ---------- web / tablet ----------
    OutlinedButton outlined(String label, VoidCallback onTap) => OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        foregroundColor: AdminEmpColors.text,
        side: const BorderSide(color: AdminEmpColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        title,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            outlined('Export CSV', _exportCsv),
            if (_access.canCreate)
              ElevatedButton(
                onPressed: _addEmployee,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  backgroundColor: AdminEmpColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('+ Add Employee', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            outlined('View All', widget.onViewAllEmployees),
          ],
        ),
      ],
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

    // PERMISSION: a role that may see only one of the two gets one full-width card
    if (widget.canSeeLeaves && !widget.canSeeExpenses) return leaves;
    if (widget.canSeeExpenses && !widget.canSeeLeaves) return expenses;

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
          return Column(children: [leaves, const SizedBox(height: 20), expenses]);
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