import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import '../services/admin_employee_profile_service.dart';
import 'admin_attendance_calendar.dart';
import 'admin_employee_form_helpers.dart';
import 'admin_employee_theme.dart';

/// Manually mark attendance for one or many dates.
/// Returns `true` when saved.
class AdminMarkAttendanceDialog extends StatefulWidget {
  final AdminEmployeeProfileService service;
  final AdminEmployeeModel employee;

  /// yyyy-MM-dd keys.
  final List<String> dateKeys;

  const AdminMarkAttendanceDialog({
    super.key,
    required this.service,
    required this.employee,
    required this.dateKeys,
  });

  static Future<bool?> show(
      BuildContext context, {
        required AdminEmployeeProfileService service,
        required AdminEmployeeModel employee,
        required List<String> dateKeys,
      }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminMarkAttendanceDialog(
        service: service,
        employee: employee,
        dateKeys: dateKeys,
      ),
    );
  }

  @override
  State<AdminMarkAttendanceDialog> createState() => _AdminMarkAttendanceDialogState();
}

class _AdminMarkAttendanceDialogState extends State<AdminMarkAttendanceDialog> {
  static const List<String> _statuses = ['present', 'late', 'half_day', 'absent', 'on_leave'];

  final TextEditingController _notes = TextEditingController();
  String _status = 'present';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  String get _datesLabel {
    final keys = widget.dateKeys;
    if (keys.length == 1) return _pretty(keys.first);
    return '${keys.length} dates selected';
  }

  String _pretty(String key) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final y = int.tryParse(key.substring(0, 4)) ?? 0;
    final m = int.tryParse(key.substring(5, 7)) ?? 1;
    final d = int.tryParse(key.substring(8, 10)) ?? 1;
    return '$d ${months[m - 1]} $y';
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.markAttendance(
        employeeId: widget.employee.id,
        dates: widget.dateKeys,
        status: _status,
        notes: _notes.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            adminEmpDialogTitle(
              'Mark Attendance',
              _saving ? null : () => Navigator.of(context).pop(false),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 4, 26, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.employee.name}  •  $_datesLabel',
                      style: const TextStyle(fontSize: 13.5, color: AdminEmpColors.muted),
                    ),
                    const SizedBox(height: 20),
                    adminEmpLabel('Status'),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [for (final s in _statuses) _statusChip(s)],
                    ),
                    const SizedBox(height: 20),
                    adminEmpLabel('Notes (optional)'),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14.5, color: AdminEmpColors.text),
                      decoration: adminEmpInput('e.g. Regularised by HR'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 12, 26, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) adminEmpErrorBox(_error!),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                        style: adminEmpOutlineButton(),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: adminEmpPrimaryButton(),
                        child: _saving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String kind) {
    final st = adminAttendanceStyle(kind);
    final selected = _status == kind;

    return InkWell(
      onTap: () => setState(() => _status = kind),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? st.bg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? st.fg : AdminEmpColors.border, width: selected ? 1.6 : 1),
        ),
        child: Text(
          st.label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? st.fg : AdminEmpColors.text,
          ),
        ),
      ),
    );
  }
}