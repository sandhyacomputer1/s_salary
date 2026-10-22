// lib/features/admin/attendance_notifications/widgets/notification_list_tile.dart

import 'package:flutter/material.dart';
import '../models/admin_attendance_model.dart';
import '../utils/notification_theme.dart';

class NotificationListTile extends StatelessWidget {
  final AdminAttendanceModel record;
  final bool showCheckIn;
  final bool showCheckOut;

  const NotificationListTile({
    super.key,
    required this.record,
    required this.showCheckIn,
    required this.showCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final initials = record.employeeName.isNotEmpty
        ? record.employeeName.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NotificationColors.border)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NotificationColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: NotificationColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: NotificationColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(record.employeeName, style: NotificationText.empName),
                    if (record.isLate) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: NotificationColors.warningBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Late by ${record.lateByMinutes}m',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: NotificationColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (record.employeeCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(record.employeeCode, style: NotificationText.emptySubtitle),
                ],
              ],
            ),
          ),

          // Events
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showCheckIn && record.hasCheckedIn)
                _EventLine(
                  label: 'Checked In',
                  time: _formatTime(record.checkInTime!),
                  color: NotificationColors.success,
                  icon: Icons.login_rounded,
                ),
              if (showCheckOut && record.hasCheckedOut)
                _EventLine(
                  label: 'Checked Out',
                  time: _formatTime(record.checkOutTime!),
                  color: NotificationColors.primary,
                  icon: Icons.logout_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return isoString;
    }
  }
}

class _EventLine extends StatelessWidget {
  final String label;
  final String time;
  final Color color;
  final IconData icon;

  const _EventLine({
    required this.label,
    required this.time,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label • $time',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}