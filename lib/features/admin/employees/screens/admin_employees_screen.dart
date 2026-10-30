import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage.dart'; // TODO: fix path if different
import '../models/admin_employee_model.dart';
import '../services/admin_csv_download.dart';
import '../services/admin_employee_csv_service.dart';
import '../services/admin_employee_service.dart';
import '../widgets/admin_access_dialog.dart';
import '../widgets/admin_add_employee_dialog.dart';
import '../widgets/admin_bulk_import_dialog.dart';
import '../widgets/admin_employee_card.dart';
import '../widgets/admin_employee_tab_bar.dart';
import '../widgets/admin_employee_table.dart';
import '../widgets/admin_employee_theme.dart';
import '../widgets/admin_salary_dialog.dart';

/// Employee Directory: Active / Archive tabs + Add Employee dialog.
/// Use `embedded: true` when it is shown inside the dashboard shell.
class AdminEmployeesScreen extends StatefulWidget {
  final bool embedded;
  const AdminEmployeesScreen({super.key, this.embedded = false});

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  final AdminEmployeeService _service = AdminEmployeeService();

  int _tab = 0; // 0 = Active, 1 = Archive
  bool _loading = true;
  String? _error;

  List<AdminEmployeeModel> _active = [];
  List<AdminEmployeeModel> _archived = [];
  List<String> _departments = AdminEmployeeService.fallbackDepartments;
  String _companyId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ------------------------------------------------------------
  // data
  // ------------------------------------------------------------

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      if (_companyId.isEmpty) {
        _companyId = (await SecureStorage.getCompanyId()) ?? '';
      }

      final results = await Future.wait([
        _service.getActiveEmployees(),
        _service.getArchivedEmployees(),
        if (_companyId.isNotEmpty) _service.getSalaryMap(_companyId),
        if (_companyId.isNotEmpty) _service.getDepartments(_companyId),
      ]);

      var active = results[0] as List<AdminEmployeeModel>;
      var archived = results[1] as List<AdminEmployeeModel>;

      if (_companyId.isNotEmpty) {
        final salary = results[2] as Map<String, double>;
        _departments = results[3] as List<String>;
        active = active.map((e) => e.copyWith(baseSalary: salary[e.id])).toList();
        archived = archived.map((e) => e.copyWith(baseSalary: salary[e.id])).toList();
      }

      if (!mounted) return;
      setState(() {
        _active = active;
        _archived = archived;
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

  Future<void> _openAdd() async {
    final created = await AdminAddEmployeeDialog.show(
      context,
      service: _service,
      departments: _departments,
    );
    if (created == true) {
      _toast('Employee added successfully');
      _load(silent: true);
    }
  }

  /// Next number for the AUTO CODE column (highest EMP-xxxx in use + 1).
  int _nextCodeNumber() {
    var max = 0;
    for (final e in [..._active, ..._archived]) {
      final m = RegExp(r'(\d+)\s*$').firstMatch(e.employeeCode);
      final n = m == null ? 0 : int.tryParse(m.group(1)!) ?? 0;
      if (n > max) max = n;
    }
    return max + 1;
  }

  Future<void> _openBulkImport() async {
    final imported = await AdminBulkImportDialog.show(
      context,
      service: _service,
      departments: _departments,
      nextCodeNumber: _nextCodeNumber(),
    );
    if (imported == true) _load(silent: true);
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

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool danger = true,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44),
              backgroundColor: danger ? AdminEmpColors.danger : AdminEmpColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _run(Future<void> Function() job, String successMsg) async {
    try {
      await job();
      if (!mounted) return;
      _toast(successMsg);
      _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _archive(AdminEmployeeModel e) async {
    final ok = await _confirm(
      title: 'Archive employee?',
      message: '${e.name} will be moved to the Archive tab. You can restore later.',
      action: 'Archive',
    );
    if (ok) _run(() => _service.archiveEmployee(e.id), 'Employee archived');
  }

  Future<void> _restore(AdminEmployeeModel e) async {
    final ok = await _confirm(
      title: 'Restore employee?',
      message: '${e.name} will become active again.',
      action: 'Restore',
      danger: false,
    );
    if (ok) _run(() => _service.restoreEmployee(e.id), 'Employee restored');
  }

  Future<void> _deleteForever(AdminEmployeeModel e) async {
    final ok = await _confirm(
      title: 'Delete permanently?',
      message: '${e.name} and all related data will be deleted. This cannot be undone.',
      action: 'Delete',
    );
    if (ok) _run(() => _service.deletePermanently(e.id), 'Employee deleted permanently');
  }

  Future<void> _openAccess(AdminEmployeeModel e) async {
    final saved = await AdminAccessDialog.show(context, service: _service, employee: e);
    if (saved == true) {
      if (!mounted) return;
      _toast('Access & credentials updated');
      _load(silent: true);
    }
  }

  Future<void> _openSalary(AdminEmployeeModel e) async {
    final saved = await AdminSalaryDialog.show(context, service: _service, employee: e);
    if (saved == true) {
      if (!mounted) return;
      _toast('Salary saved');
      _load(silent: true);
    }
  }

  // Next steps (not built yet).
  void _comingSoon(AdminEmployeeModel e) => _toast('Coming in the next step');

  // ------------------------------------------------------------
  // build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final body = Container(
      color: AdminEmpColors.bg,
      child: RefreshIndicator(
        color: AdminEmpColors.primary,
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            AdminEmployeeTabBar(
              selectedIndex: _tab,
              activeCount: _active.length,
              archiveCount: _archived.length,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),
            _panel(),
          ],
        ),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AdminEmpColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AdminEmpColors.text,
        elevation: 0,
        title: const Text('Employee Directory', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: body,
    );
  }

  Widget _panel() {
    final archived = _tab == 1;
    final list = archived ? _archived : _active;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminEmpColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _panelHeader(archived, list.length),
          ),
          _panelBody(archived, list),
        ],
      ),
    );
  }

  Widget _panelHeader(bool archived, int count) {
    final title = Text(
      archived ? 'Archived Employees ($count)' : 'Employees ($count)',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AdminEmpColors.text),
    );

    if (archived) return title;

    OutlinedButton outlined(String label, VoidCallback onTap) => OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44),
        foregroundColor: AdminEmpColors.text,
        side: const BorderSide(color: AdminEmpColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        outlined('Export CSV', _exportCsv),
        outlined('Bulk Import', _openBulkImport),
        ElevatedButton(
          onPressed: _openAdd,
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44),
            backgroundColor: AdminEmpColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('+ Add Employee', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
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

  Widget _panelBody(bool archived, List<AdminEmployeeModel> list) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: AdminEmpColors.primary)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AdminEmpColors.danger, size: 36),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AdminEmpColors.muted)),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: _load, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            archived ? 'No archived employees found.' : 'No employees found.',
            style: const TextStyle(color: AdminEmpColors.muted, fontSize: 15),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 980;

        if (wide) {
          return AdminEmployeeTable(
            employees: list,
            archived: archived,
            onAccess: _openAccess,
            onSalary: _openSalary,
            onProfile: _comingSoon,
            onArchive: _archive,
            onRestore: _restore,
            onDeleteForever: _deleteForever,
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              for (final e in list)
                AdminEmployeeCard(
                  employee: e,
                  archived: archived,
                  onAccess: () => _openAccess(e),
                  onSalary: () => _openSalary(e),
                  onProfile: () => _comingSoon(e),
                  onArchive: () => _archive(e),
                  onRestore: () => _restore(e),
                  onDeleteForever: () => _deleteForever(e),
                ),
            ],
          ),
        );
      },
    );
  }
}