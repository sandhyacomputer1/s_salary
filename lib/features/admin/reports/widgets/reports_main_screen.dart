// lib/features/admin/reports/widgets/reports_main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance_notifications/utils/notification_theme.dart';
import '../repositories/report_repository.dart';
import 'daily_reports_tab.dart';
import 'monthly_matrix_tab.dart';

class ReportsMainScreen extends ConsumerStatefulWidget {
  const ReportsMainScreen({super.key});
  @override
  ConsumerState<ReportsMainScreen> createState() => _ReportsMainScreenState();
}

class _ReportsMainScreenState extends ConsumerState<ReportsMainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final dailyCount = ref.watch(dailyReportsProvider).valueOrNull?.length ?? 0;

    return Container(
      color: NotificationColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: NotificationColors.border)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TabBtn(label: 'Monthly Attendance Matrix', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                  const SizedBox(width: 4),
                  _TabBtn(label: 'Employee Daily Work Reports ($dailyCount)', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_tab == 0) const MonthlyMatrixTab() else const DailyReportsTab(),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: selected ? NotificationColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : NotificationColors.textMedium)),
      ),
    );
  }
}