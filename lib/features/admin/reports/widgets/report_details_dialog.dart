// lib/features/admin/reports/widgets/report_details_dialog.dart

import 'package:flutter/material.dart';
import '../../attendance_notifications/utils/notification_theme.dart';
import '../models/report_models.dart';

class ReportDetailsDialog extends StatelessWidget {
  final DailyWorkReport report;
  const ReportDetailsDialog({super.key, required this.report});

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: Text('Daily Work Report Details - ${report.employeeName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: NotificationColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: NotificationColors.border)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(report.employeeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${report.employeeCode} · ${report.department}', style: NotificationText.emptySubtitle.copyWith(fontSize: 11.5)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('REPORT DATE', style: NotificationText.emptySubtitle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(_fmt(report.date), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: NotificationColors.primary)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
                _Field(label: 'Completed Work / Work Done Today', value: report.completedWork),
                const SizedBox(height: 12),
                _Field(label: 'Ongoing Tasks', value: report.ongoingTasks),
                const SizedBox(height: 12),
                _Field(label: 'Plan for Tomorrow', value: report.planForTomorrow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label; final String value;
  const _Field({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: NotificationColors.border), borderRadius: BorderRadius.circular(6)),
        child: Text(value.isEmpty ? '—' : value, style: NotificationText.emptySubtitle.copyWith(fontSize: 12.5)),
      ),
    ]);
  }
}