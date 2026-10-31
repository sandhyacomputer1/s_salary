import 'package:flutter/material.dart';

import '../models/admin_employee_profile_models.dart';
import 'admin_employee_theme.dart';
import 'admin_profile_common.dart';

/// PRESENT DAYS (orange) | LATE DAYS | HALF DAYS | TOTAL WORK HOURS
class AdminProfileStatCards extends StatelessWidget {
  final AdminAttendanceSummary summary;
  const AdminProfileStatCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _card('PRESENT DAYS', '${summary.present}', highlighted: true),
      _card('LATE DAYS', '${summary.late}'),
      _card('HALF DAYS', '${summary.halfDay}'),
      _card('TOTAL WORK HOURS', '${adminProfHours(summary.totalHours)} hrs'),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 4 : 2;
        const gap = 18.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }

  Widget _card(String label, String value, {bool highlighted = false}) {
    final fg = highlighted ? Colors.white : AdminEmpColors.text;
    final labelColor = highlighted ? Colors.white : AdminEmpColors.muted;

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: highlighted ? null : Colors.white,
        gradient: highlighted
            ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE96832), Color(0xFFD9622D)],
        )
            : null,
        border: highlighted ? null : Border.all(color: const Color(0xFFEDEFF3)),
        boxShadow: [
          BoxShadow(
            color: highlighted ? const Color(0x33E96832) : const Color(0x0A000000),
            blurRadius: highlighted ? 16 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: fg, height: 1.1),
          ),
        ],
      ),
    );
  }
}