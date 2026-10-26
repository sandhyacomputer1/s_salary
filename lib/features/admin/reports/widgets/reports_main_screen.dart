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
  static const double _mobileBreakpoint = 700;

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final dailyCount = ref.watch(dailyReportsProvider).valueOrNull?.length ?? 0;
    final mobile = MediaQuery.sizeOf(context).width < _mobileBreakpoint;

    // Phone: two equal tabs that both fit on the screen.
    // Web: the same tabs as before (sized by their text).
    final matrixTab = _TabBtn(
      label: mobile ? 'Attendance Matrix' : 'Monthly Attendance Matrix',
      selected: _tab == 0,
      expand: mobile,
      onTap: () => setState(() => _tab = 0),
    );

    final dailyTab = _TabBtn(
      label: mobile
          ? 'Daily Reports ($dailyCount)'
          : 'Employee Daily Work Reports ($dailyCount)',
      selected: _tab == 1,
      expand: mobile,
      onTap: () => setState(() => _tab = 1),
    );

    return Container(
      color: NotificationColors.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(mobile ? 14 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NotificationColors.border),
              ),
              child: mobile
                  ? Row(
                children: [
                  Expanded(child: matrixTab),
                  const SizedBox(width: 4),
                  Expanded(child: dailyTab),
                ],
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  matrixTab,
                  const SizedBox(width: 4),
                  dailyTab,
                ],
              ),
            ),
            SizedBox(height: mobile ? 14 : 20),
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
  final bool expand;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : NotificationColors.textMedium,
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: expand ? 8 : 16,
          vertical: expand ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: selected ? NotificationColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        // On phones the text shrinks a little instead of being cut off.
        child: expand
            ? FittedBox(fit: BoxFit.scaleDown, child: text)
            : text,
      ),
    );
  }
}