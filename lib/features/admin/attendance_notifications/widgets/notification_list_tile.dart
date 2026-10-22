import 'package:flutter/material.dart';
import '../models/admin_attendance_model.dart';
import '../utils/notification_theme.dart';
import 'photo_dialog.dart';
import 'profile_navigation.dart';

class NotificationTable extends StatelessWidget {
  final List<AttendanceEvent> events;
  final void Function(AttendanceEvent) onViewProfile;

  const NotificationTable({
    super.key,
    required this.events,
    required this.onViewProfile,
  });

  static const _colFlex = [110, 260, 110, 160, 180, 200, 190];
  static const double _tableMinWidth = 1180;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth < _tableMinWidth ? _tableMinWidth : constraints.maxWidth)
            : _tableMinWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                for (int i = 0; i < events.length; i++)
                  _EventRow(
                    event: events[i],
                    alt: i.isOdd,
                    onViewProfile: () => onViewProfile(events[i]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    const headers = [
      'EVENT TYPE', 'EMPLOYEE', 'CODE', 'TIME & DATE',
      'LOCATION & GPS', 'DETAILS', 'ACTION / PHOTO',
    ];
    return Container(
      color: NotificationTableColors.headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (int i = 0; i < headers.length; i++)
            Expanded(
              flex: _colFlex[i],
              child: Text(
                headers[i],
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: NotificationColors.textLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final AttendanceEvent event;
  final bool alt;
  final VoidCallback onViewProfile;

  const _EventRow({
    required this.event,
    required this.alt,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final r = event.record;
    final isIn = event.kind == AttendanceEventKind.checkIn;

    return Container(
      color: alt ? NotificationTableColors.rowAlt : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: NotificationTable._colFlex[0], child: _EventBadge(isIn: isIn)),
          Expanded(flex: NotificationTable._colFlex[1], child: _EmployeeCell(name: r.employeeName, subtitle: r.department)),
          Expanded(flex: NotificationTable._colFlex[2], child: Text(r.employeeCode.isEmpty ? '—' : r.employeeCode, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          Expanded(flex: NotificationTable._colFlex[3], child: _TimeCell(event: event)),
          Expanded(flex: NotificationTable._colFlex[4], child: _LocationCell(record: r)),
          Expanded(flex: NotificationTable._colFlex[5], child: _DetailsCell(event: event)),
          Expanded(flex: NotificationTable._colFlex[6], child: _ActionCell(event: event, onViewProfile: onViewProfile)),
        ],
      ),
    );
  }
}

class NotificationEventCard extends StatelessWidget {
  final AttendanceEvent event;
  final VoidCallback onViewProfile;

  const NotificationEventCard({
    super.key,
    required this.event,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final r = event.record;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NotificationColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _EventBadge(isIn: event.kind == AttendanceEventKind.checkIn),
              const Spacer(),
              _TimeCell(event: event),
            ],
          ),
          const SizedBox(height: 10),
          _EmployeeCell(name: r.employeeName, subtitle: r.department),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(r.employeeCode.isEmpty ? '—' : r.employeeCode,
                  style: const TextStyle(fontSize: 12, color: NotificationColors.textLight)),
              const Spacer(),
              _LocationCell(record: r),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _DetailsCell(event: event),
              const Spacer(),
              _ActionCell(event: event, onViewProfile: onViewProfile),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventBadge extends StatelessWidget {
  final bool isIn;
  const _EventBadge({required this.isIn});

  @override
  Widget build(BuildContext context) {
    final color = isIn ? NotificationTableColors.checkIn : NotificationTableColors.checkOut;
    final bg    = isIn ? NotificationTableColors.checkInBg : NotificationTableColors.checkOutBg;
    final text  = isIn ? 'CHECK-IN' : 'CHECK-OUT';
    final icon  = isIn ? Icons.login_rounded : Icons.logout_rounded;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCell extends StatelessWidget {
  final String name;
  final String? subtitle;
  const _EmployeeCell({required this.name, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: const BoxDecoration(color: NotificationColors.primary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NotificationColors.textDark)),
              if (subtitle != null && subtitle!.trim().isNotEmpty)
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: NotificationColors.textLight)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeCell extends StatelessWidget {
  final AttendanceEvent event;
  const _TimeCell({required this.event});

  @override
  Widget build(BuildContext context) {
    final dt = event.timestamp;
    if (dt == null) return const Text('—', style: TextStyle(fontSize: 12, color: NotificationTableColors.dash));
    final timeStr = _fmtTime(dt);
    final dateStr = _fmtDate(dt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(timeStr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: NotificationColors.textDark)),
        Text(dateStr, style: const TextStyle(fontSize: 11, color: NotificationColors.textLight)),
      ],
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'pm' : 'am';
    return '$h:$m $ap';
  }

  static String _fmtDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '$d ${months[dt.month - 1]} ${dt.year}';
  }
}

class _LocationCell extends StatelessWidget {
  final AdminAttendanceModel record;
  const _LocationCell({required this.record});

  @override
  Widget build(BuildContext context) {
    if (record.distanceMeters == null && record.withinGeofence == null) {
      return const Text('—', style: TextStyle(fontSize: 12, color: NotificationTableColors.dash));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (record.distanceMeters != null)
          Text('${record.distanceMeters!.round()}m from office', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: NotificationColors.textDark)),
        if (record.withinGeofence != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: record.withinGeofence! ? NotificationTableColors.checkInBg : NotificationTableColors.lateBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 6, color: record.withinGeofence! ? NotificationTableColors.checkIn : NotificationTableColors.late),
              const SizedBox(width: 4),
              Text(record.withinGeofence! ? 'In Radius' : 'Out of Radius',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: record.withinGeofence! ? NotificationTableColors.checkIn : NotificationTableColors.late)),
            ]),
          ),
        ],
      ],
    );
  }
}

class _DetailsCell extends StatelessWidget {
  final AttendanceEvent event;
  const _DetailsCell({required this.event});

  @override
  Widget build(BuildContext context) {
    final r = event.record;

    if (event.kind == AttendanceEventKind.checkIn) {
      if (!r.isLate) {
        return const Text('On Time Arrival', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: NotificationTableColors.checkIn));
      }
      return Text('Late Arrival${r.lateByMinutes > 0 ? ' · ${r.lateByMinutes}m' : ''}',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: NotificationTableColors.late));
    }

    // Check-out details
    if (r.workedHours != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${r.workedHours!.toStringAsFixed(2)} hrs worked', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: NotificationColors.textDark)),
          if (r.status.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(r.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: NotificationColors.textMedium)),
          ] else if (r.workedHours! < 4) ...[
            const SizedBox(height: 2),
            const Text('half_day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: NotificationColors.textMedium)),
          ]
        ],
      );
    }
    return const Text('—', style: TextStyle(fontSize: 12, color: NotificationTableColors.dash));
  }
}

class _ActionCell extends StatelessWidget {
  final AttendanceEvent event;
  final VoidCallback onViewProfile;
  const _ActionCell({required this.event, required this.onViewProfile});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SmallBtn(
          label: 'View Photo',
          onTap: () => showAttendancePhotoDialog(context, event),
        ),
        const SizedBox(width: 6),
        _SmallBtn(label: 'View Profile', onTap: onViewProfile),
      ],
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SmallBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: NotificationColors.textDark,
          side: const BorderSide(color: NotificationColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}