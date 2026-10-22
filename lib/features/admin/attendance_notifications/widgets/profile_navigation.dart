import 'package:flutter/material.dart';
import '../models/admin_attendance_model.dart';

/// Tries to open the project's existing employee-profile route/dialog.
/// Replace the body of this function with your real navigation if it lives
/// elsewhere. Guarded so the table never crashes if profile is unavailable.
Future<void> openEmployeeProfile(
    BuildContext context,
    AdminAttendanceModel record,
    ) async {
  // TODO: wire to your existing employee profile screen / details dialog.
  // Example:
  // Navigator.of(context).pushNamed('/employees/${record.employeeId}');
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(record.employeeName),
      content: Text('Code: ${record.employeeCode}\nEmployee ID: ${record.employeeId}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}