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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
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
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: employees.isEmpty ? null : () => _exportCsv(context),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kTextDark,
                    side: const BorderSide(color: _kBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
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

          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    if (loading && employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    if (error != null && employees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Text(error!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Table needs horizontal scroll on narrow screens
        if (constraints.maxWidth < 1000) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: 1100, child: _table()),
          );
        }
        return _table();
      },
    );
  }

  Widget _table() {
    return Column(
      children: [
        // Table Header
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

        // Rows
        for (var i = 0; i < employees.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFEDEFF3)),
          _row(employees[i]),
        ],
      ],
    );
  }

  Widget _row(Employee e) {
    final structure = structures[e.id];
    final salary = structure == null ? 'Not set' : PayrollFormat.rupees(structure.baseSalary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Employee Name + Email
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name.isEmpty ? 'Unnamed' : e.name,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _kTextDark),
                ),
                if (e.email.isNotEmpty)
                  Text(
                    e.email,
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
              ],
            ),
          ),
          // Code
          Expanded(
            flex: 2,
            child: Text(e.employeeCode, style: const TextStyle(fontSize: 13, color: _kTextDark)),
          ),
          // Department
          Expanded(
            flex: 2,
            child: Text(e.department, style: const TextStyle(fontSize: 13, color: _kTextDark)),
          ),
          // Work Mode Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  e.workMode == 'field' ? 'Field Employee' : 'In-House',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            ),
          ),
          // Joining Date
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(e.dateOfJoining),
              style: const TextStyle(fontSize: 13, color: _kTextDark),
            ),
          ),
          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: e.status.toLowerCase() == 'active' ? const Color(0xFFE7F7EF) : const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: e.status.toLowerCase() == 'active' ? _kGreen : _kRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      e.status.toLowerCase() == 'active' ? 'active' : 'inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: e.status.toLowerCase() == 'active' ? const Color(0xFF15803D) : _kRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Salary
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
          // Actions
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
                _actionBtn(Icons.delete_outline_rounded, () => onDelete(e), 'Delete', isDanger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap, String tooltip, {bool isDanger = false}) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDanger ? _kRed : _kTextDark,
          side: BorderSide(color: isDanger ? const Color(0xFFF5C2C2) : _kBorder),
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _exportCsv(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('Employee,Email,Code,Department,Work Mode,Joining Date,Status,Monthly Salary');

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
        escape(e.dateOfJoining != null ? e.dateOfJoining!.toIso8601String().split('T').first : ''),
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