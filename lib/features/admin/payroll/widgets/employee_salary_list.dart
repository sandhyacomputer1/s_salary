import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/employee.dart';
import '../models/salary_structure_model.dart';
import 'payroll_format.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kMuted = Color(0xFF7A8494);
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kGreen = Color(0xFF16A34A);
const Color _kRed = Color(0xFFDC2626);

/// Below this width the table becomes a list of cards.
const double _kNarrow = 700;

class EmployeeSalaryList extends StatelessWidget {
  const EmployeeSalaryList({
    super.key,
    required this.employees,
    required this.structures,
    required this.loading,
    required this.error,
    required this.structuresError,
    required this.onRetry,
    required this.onSetSalary,
    required this.onEditAccess,
    required this.onViewProfile,
    required this.onDelete,
  });

  final List<Employee> employees;
  final Map<String, SalaryStructure> structures;
  final bool loading;
  final String? error;
  final String? structuresError;
  final VoidCallback onRetry;
  final ValueChanged<Employee> onSetSalary;
  final ValueChanged<Employee> onEditAccess;
  final ValueChanged<Employee> onViewProfile;
  final ValueChanged<Employee> onDelete;

  @override
  Widget build(BuildContext context) {
    final count = loading && employees.isEmpty ? '' : ' (${employees.length})';

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _kNarrow;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employees$count',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set each employee\'s base salary and allowances. A new salary applies the next time payroll is calculated.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ],
        );

        final exportBtn = OutlinedButton.icon(
          onPressed: employees.isEmpty ? null : () => _exportCsv(context),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export CSV'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kTextDark,
            side: const BorderSide(color: _kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    narrow ? 14 : 20, 20, narrow ? 14 : 20, 16),
                child: narrow
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    exportBtn,
                  ],
                )
                    : Row(
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 12),
                    exportBtn,
                  ],
                ),
              ),
              const Divider(height: 1, color: _kBorder),
              if (structuresError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFFFF8E6),
                  child: Text(
                    'Salaries could not be loaded: $structuresError',
                    style: const TextStyle(color: Color(0xFF92400E)),
                  ),
                ),
              _body(narrow, constraints),
            ],
          ),
        );
      },
    );
  }

  Widget _body(bool narrow, BoxConstraints constraints) {
    if (loading && employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (error != null && employees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('No active employees found.')),
      );
    }

    // Mobile: stacked cards
    if (narrow) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [for (final e in employees) _card(e)],
        ),
      );
    }

    // Tablet / small desktop: horizontal scroll
    if (constraints.maxWidth < 1000) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 1100, child: _table()),
      );
    }
    return _table();
  }

  // ---------------------------------------------------------------
  // MOBILE CARD
  // ---------------------------------------------------------------

  Widget _card(Employee e) {
    final structure = structures[e.id];
    final salary =
    structure == null ? 'Not set' : PayrollFormat.rupees(structure.baseSalary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name.isEmpty ? 'Unnamed' : e.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                    if (e.email.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          e.email,
                          style: const TextStyle(fontSize: 12, color: _kMuted),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(e),
            ],
          ),
          const SizedBox(height: 12),

          // Info grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _info('CODE', e.employeeCode.isEmpty ? '—' : e.employeeCode)),
              Expanded(child: _info('DEPARTMENT', e.department.isEmpty ? '—' : e.department)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _info('JOINING', _formatDate(e.dateOfJoining))),
              Expanded(
                child: _info(
                  'WORK MODE',
                  e.workMode == 'field' ? 'Field Employee' : 'In-House',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _info(
            'SALARY',
            salary,
            bold: true,
            color: structure == null ? _kMuted : _kPrimary,
            size: 15,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              Expanded(
                child: _mobileAction(
                  Icons.lock_outline_rounded,
                  'Access',
                      () => onEditAccess(e),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _mobileAction(
                  Icons.currency_rupee_rounded,
                  'Salary',
                      () => onSetSalary(e),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _mobileAction(
                  Icons.person_outline_rounded,
                  'Profile',
                      () => onViewProfile(e),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: _mobileAction(
                  Icons.delete_outline_rounded,
                  null,
                      () => onDelete(e),
                  isDanger: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(
      String label,
      String value, {
        bool bold = false,
        Color color = _kTextDark,
        double size = 13,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _mobileAction(
      IconData icon,
      String? label,
      VoidCallback onTap, {
        bool isDanger = false,
      }) {
    final fg = isDanger ? _kRed : _kTextDark;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        side: BorderSide(color: isDanger ? const Color(0xFFF5C2C2) : _kBorder),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: label == null
          ? Icon(icon, size: 17)
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(Employee e) {
    final active = e.status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F7EF) : const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? _kGreen : _kRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'active' : 'inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF15803D) : _kRed,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // DESKTOP TABLE
  // ---------------------------------------------------------------

  Widget _table() {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8F9FB),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: const Row(
            children: [
              Expanded(flex: 3, child: _HeaderText('EMPLOYEE')),
              Expanded(flex: 2, child: _HeaderText('CODE')),
              Expanded(flex: 2, child: _HeaderText('DEPARTMENT')),
              Expanded(flex: 2, child: _HeaderText('WORK MODE')),
              Expanded(flex: 2, child: _HeaderText('JOINING')),
              Expanded(flex: 2, child: _HeaderText('STATUS')),
              Expanded(flex: 2, child: _HeaderText('SALARY')),
              SizedBox(width: 180, child: _HeaderText('ACTIONS')),
            ],
          ),
        ),
        const Divider(height: 1, color: _kBorder),
        for (var i = 0; i < employees.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFEDEFF3)),
          _row(employees[i]),
        ],
      ],
    );
  }

  Widget _row(Employee e) {
    final structure = structures[e.id];
    final salary =
    structure == null ? 'Not set' : PayrollFormat.rupees(structure.baseSalary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name.isEmpty ? 'Unnamed' : e.name,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark),
                ),
                if (e.email.isNotEmpty)
                  Text(
                    e.email,
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(e.employeeCode,
                style: const TextStyle(fontSize: 13, color: _kTextDark)),
          ),
          Expanded(
            flex: 2,
            child: Text(e.department,
                style: const TextStyle(fontSize: 13, color: _kTextDark)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  e.workMode == 'field' ? 'Field Employee' : 'In-House',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(e.dateOfJoining),
              style: const TextStyle(fontSize: 13, color: _kTextDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(e),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              salary,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: structure == null ? _kMuted : _kTextDark,
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionBtn(Icons.lock_outline_rounded, () => onEditAccess(e), 'Access'),
                const SizedBox(width: 6),
                _actionBtn(Icons.currency_rupee_rounded, () => onSetSalary(e), 'Set Salary'),
                const SizedBox(width: 6),
                _actionBtn(Icons.person_outline_rounded, () => onViewProfile(e), 'Profile'),
                const SizedBox(width: 6),
                _actionBtn(Icons.delete_outline_rounded, () => onDelete(e), 'Delete',
                    isDanger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap, String tooltip,
      {bool isDanger = false}) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDanger ? _kRed : _kTextDark,
          side: BorderSide(
              color: isDanger ? const Color(0xFFF5C2C2) : _kBorder),
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _exportCsv(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Employee,Email,Code,Department,Work Mode,Joining Date,Status,Monthly Salary');

    for (final e in employees) {
      final structure = structures[e.id];
      final salary = structure?.baseSalary.toString() ?? '';

      String escape(String val) => '"${val.replaceAll('"', '""')}"';

      buffer.writeln([
        escape(e.name),
        escape(e.email),
        escape(e.employeeCode),
        escape(e.department),
        escape(e.workMode),
        escape(e.dateOfJoining != null
            ? e.dateOfJoining!.toIso8601String().split('T').first
            : ''),
        escape(e.status),
        escape(salary),
      ].join(','));
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee CSV copied to clipboard.')),
      );
    }
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7B8493),
        letterSpacing: 0.5,
      ),
    );
  }
}