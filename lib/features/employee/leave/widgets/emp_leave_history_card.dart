import 'package:flutter/material.dart';

import '../models/emp_leave_balance_model.dart';
import '../models/emp_leave_model.dart';

class EmpLeaveHistoryCard extends StatelessWidget {
  final EmpLeaveModel leave;

  const EmpLeaveHistoryCard({super.key, required this.leave});

  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color success = Color(0xFF159957);
  static const Color successLight = Color(0xFFE7F7EF);
  static const Color danger = Color(0xFFD64545);
  static const Color dangerLight = Color(0xFFFFE8E8);
  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFEEE7);

  ({Color fg, Color bg}) _statusColors(String status) {
    switch (status) {
      case 'approved':
        return (fg: success, bg: successLight);
      case 'rejected':
        return (fg: danger, bg: dangerLight);
      case 'pending':
        return (fg: primary, bg: primaryLight);
      default:
        return (fg: textLight, bg: const Color(0xFFF1F2F4));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusColors(leave.status);
    final statusText =
    leave.status.isEmpty ? 'UNKNOWN' : leave.status.replaceAll('_', ' ').toUpperCase();

    final period = EmpLeaveFormat.samePeriodDay(leave.startDate, leave.endDate)
        ? EmpLeaveFormat.period(leave.startDate)
        : '${EmpLeaveFormat.period(leave.startDate)} → ${EmpLeaveFormat.period(leave.endDate)}';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        EmpLeaveTypeHelper.displayName(leave.leaveType),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                    ),
                    _Pill(
                      text: leave.isPaid
                          ? 'Paid Leave (0 Salary Cut)'
                          : 'Unpaid Leave (Salary Cut)',
                      fg: leave.isPaid ? success : danger,
                      bg: leave.isPaid ? successLight : dangerLight,
                      outlined: true,
                    ),
                    Text(
                      '${EmpLeaveTypeHelper.formatDays(leave.totalDays)} Day(s)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: textMedium,
                      ),
                    ),
                    if (leave.isHalfDay)
                      const _Pill(
                        text: 'Half Day',
                        fg: Color(0xFF2563EB),
                        bg: Color(0xFFE9F0FF),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Pill(
                text: statusText,
                fg: status.fg,
                bg: status.bg,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: border),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;

              final periodField = _Field(
                label: 'APPLIED PERIOD',
                child: Text(
                  period,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              );

              final appliedField = _Field(
                label: 'APPLIED ON',
                child: Text(
                  EmpLeaveFormat.appliedOn(leave.appliedOn),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              );

              final reasonField = _Field(
                label: 'REASON',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEF0F3)),
                  ),
                  child: Text(
                    leave.reason.trim().isEmpty ? '—' : leave.reason,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              );

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    periodField,
                    const SizedBox(height: 14),
                    appliedField,
                    const SizedBox(height: 14),
                    reasonField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: periodField),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: appliedField),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: reasonField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

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
            color: EmpLeaveHistoryCard.textMedium,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  final bool outlined;
  final bool bold;

  const _Pill({
    required this.text,
    required this.fg,
    required this.bg,
    this.outlined = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(bold ? 20 : 8),
        border: outlined
            ? Border.all(color: fg.withValues(alpha: 0.45))
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: bold ? 12 : 11.5,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: bold ? 0.3 : 0,
        ),
      ),
    );
  }
}