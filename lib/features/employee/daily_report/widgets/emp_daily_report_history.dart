import 'package:flutter/material.dart';

import '../models/emp_daily_report_model.dart';

/// One entry of the "Daily EOD Work Report History" list.
class EmpDailyReportHistoryCard extends StatelessWidget {
  final EmpDailyReportModel report;

  const EmpDailyReportHistoryCard({super.key, required this.report});

  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);

  @override
  Widget build(BuildContext context) {
    final submittedAt = report.submittedAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                child: Text(
                  EmpDailyReportFormat.keyToDisplay(report.dateKey),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ),
              if (submittedAt != null)
                Text(
                  'Last submitted ${EmpDailyReportFormat.dateTime(submittedAt)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textLight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: border),
          const SizedBox(height: 14),
          _Section(label: 'COMPLETED WORK', text: report.completedWork),
          if (report.ongoingWork.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _Section(label: 'ONGOING WORK', text: report.ongoingWork),
          ],
          if (report.planForTomorrow.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _Section(label: 'TOMORROW\'S PLAN', text: report.planForTomorrow),
          ],
          if (report.blockers.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _Section(label: 'BLOCKERS', text: report.blockers),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final String text;

  const _Section({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: EmpDailyReportHistoryCard.textMedium,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEEF0F3)),
          ),
          child: Text(
            text.trim().isEmpty ? '—' : text,
            style: const TextStyle(
              fontSize: 13.5,
              color: EmpDailyReportHistoryCard.textDark,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}