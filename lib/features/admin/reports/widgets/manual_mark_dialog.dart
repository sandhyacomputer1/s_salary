// lib/features/admin/reports/widgets/manual_mark_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance_notifications/utils/notification_theme.dart';
import '../../../../data/services/employee_service.dart';
import '../../../../data/models/employee.dart';
import '../repositories/report_repository.dart';

class ManualMarkDialog extends ConsumerStatefulWidget {
  final String? initialEmployeeId;
  final DateTime? initialDate;

  const ManualMarkDialog({
    super.key,
    this.initialEmployeeId,
    this.initialDate,
  });

  @override
  ConsumerState<ManualMarkDialog> createState() => _ManualMarkDialogState();
}

class _ManualMarkDialogState extends ConsumerState<ManualMarkDialog> {
  String? _employeeId;
  late DateTime _date;
  String _status = 'P';
  final _note = TextEditingController();
  bool _saving = false;

  Employee? _selectedEmployee;

  List<Employee>? _employees;
  bool _loadingEmployees = true;
  String? _employeesError;

  static const _statuses = [
    ('P', 'Present (On Time)', '0 Late Mark', Color(0xFF18864B)), // Green
    ('L', 'Late Check-In', 'Counts toward late rule', Color(0xFFE8A317)), // Orange
    ('A', 'Absent', 'Daily salary cut', Color(0xFFC62828)), // Red
    ('LV', 'On Leave', 'Approved Leave', Color(0xFF7A5AF8)), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _employeeId = widget.initialEmployeeId;
    _date = widget.initialDate ?? DateTime.now();
    _loadEmployees();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await EmployeeService().getEmployees(status: 'active');
      if (!mounted) return;
      setState(() {
        _employees = list;
        if (_employeeId != null) {
          _selectedEmployee = list.firstWhere(
                (e) => e.id == _employeeId,
            orElse: () => list.isNotEmpty ? list.first : throw Exception('No employees'),
          );
          // Ensure the dropdown actually selects it
          _employeeId = _selectedEmployee?.id;
        }
        _loadingEmployees = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _employeesError = e.toString();
        _loadingEmployees = false;
      });
    }
  }

  Future<void> _save() async {
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select an employee')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(reportServiceProvider).markManualAttendance(
        employeeId: _employeeId!,
        dateIso: '${_date.year}-'
            '${_date.month.toString().padLeft(2, '0')}-'
            '${_date.day.toString().padLeft(2, '0')}',
        status: _status,
        note: _note.text,
      );
      if (!mounted) return;
      ref.invalidate(monthlyMatrixProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingEmployees) {
      return const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator()));
    }
    if (_employeesError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Could not load employees.\n$_employeesError',
              textAlign: TextAlign.center, style: NotificationText.emptySubtitle),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _loadingEmployees = true;
                _employeesError = null;
              });
              _loadEmployees();
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    final employees = _employees ?? const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Title & Close Button
        Row(children: [
          Expanded(
            child: Text(
              'Mark Manual Attendance — ${_fmtDate(_date)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF18212F)),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF8A93A1)),
              onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 16),

        // Employee Dropdown Selection
        DropdownButtonFormField<String>(
          value: _employeeId,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          decoration: InputDecoration(
            labelText: 'Employee',
            labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A93A1)),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          items: employees
              .map((e) => DropdownMenuItem(
            value: e.id,
            child: Text('${e.name} (${e.employeeCode})', style: const TextStyle(fontSize: 14)),
          ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _employeeId = v;
              _selectedEmployee = employees.firstWhere((e) => e.id == v);
            });
          },
        ),
        const SizedBox(height: 20),

        // Employee Info Card
        if (_selectedEmployee != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedEmployee!.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF18212F))),
                      const SizedBox(height: 4),
                      Text('Code: ${_selectedEmployee!.employeeCode}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A93A1))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('TARGET DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF8A93A1))),
                    const SizedBox(height: 4),
                    Text(_fmtDate(_date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE96832))),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Status Options Label
        const Text('Select Attendance Status:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF18212F))),
        const SizedBox(height: 12),

        // Status Options Grid (2x2)
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _statuses.map((s) {
                final isSel = _status == s.$1;
                return InkWell(
                  onTap: () => setState(() => _status = s.$1),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: itemWidth,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSel ? s.$4 : const Color(0xFFE5E7EB),
                        width: isSel ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(Icons.circle, size: 10, color: s.$4),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.$2, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF18212F))),
                              const SizedBox(height: 4),
                              Text(s.$3, style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A1))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),

        // Note Field
        const Text('Admin Note / Reason (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF18212F))),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          decoration: InputDecoration(
            hintText: 'e.g. Marked present as per approval by HR',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A93A1)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 28),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF18212F),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE96832),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Attendance Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }
}