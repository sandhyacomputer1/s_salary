import 'package:flutter/material.dart';

import '../models/admin_employee_profile_models.dart';
import 'admin_employee_theme.dart';
import 'admin_profile_common.dart';

/// "Attendance & Work Hours Metrics": rate bar, hours bar, log breakdown.
class AdminProfileMetricsCard extends StatelessWidget {
  final AdminAttendanceSummary summary;

  /// Monthly target used for the work-hours bar (same as the web: 160 hrs).
  static const double targetHours = 160;

  const AdminProfileMetricsCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final rate = summary.attendanceRate;
    final hoursPct = (summary.totalHours * 100 / targetHours).clamp(0, 100);

    return AdminProfileCard(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminProfileSectionTitle('Attendance & Work Hours Metrics'),
          const SizedBox(height: 32),
          _bar(
            label: 'Monthly Attendance Rate',
            valueText: '${rate.round()}%',
            fraction: rate / 100,
            fill: const Color(0xFF22C55E),
          ),
          const SizedBox(height: 26),
          _bar(
            label: 'Total Work Hours Recorded',
            valueText:
            '${adminProfHours(summary.totalHours)} / ${targetHours.round()} hrs (${hoursPct.round()}%)',
            fraction: hoursPct / 100,
            fill: AdminEmpColors.primary,
          ),
          const SizedBox(height: 30),
          const AdminProfileSmallCaps('MONTHLY LOG BREAKDOWN'),
          const SizedBox(height: 14),
          _breakdown(),
        ],
      ),
    );
  }

  Widget _bar({
    required String label,
    required String valueText,
    required double fraction,
    required Color fill,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminEmpColors.text,
                ),
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AdminEmpColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 14,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(fill),
            ),
          ),
        ),
      ],
    );
  }

  Widget _breakdown() {
    final items = <(String, int, Color, Color, Color)>[
      ('PRESENT', summary.present, const Color(0xFF16A34A), const Color(0xFFF0FDF4), const Color(0xFFBBF7D0)),
      ('LATE ARRIVAL', summary.late, const Color(0xFFD97706), const Color(0xFFFFFBEB), const Color(0xFFFDE68A)),
      ('HALF DAY', summary.halfDay, const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFFBFDBFE)),
      ('ABSENT', summary.absent, const Color(0xFFDC2626), const Color(0xFFFEF2F2), const Color(0xFFFECACA)),
      ('ON LEAVE', summary.onLeave, const Color(0xFF7C3AED), const Color(0xFFF5F3FF), const Color(0xFFDDD6FE)),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 5 : (c.maxWidth >= 560 ? 3 : 2);
        const gap = 16.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final it in items)
              Container(
                width: w,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                decoration: BoxDecoration(
                  color: it.$4,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: it.$5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: it.$3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${it.$2} days',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AdminEmpColors.text,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}