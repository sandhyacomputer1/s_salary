import 'package:flutter/material.dart';

import '../models/roster_schedule_model.dart';

// =================================================================
// ROSTER TABLE
//
// Horizontally scrollable table (DataTable) so it never overflows
// on smaller / desktop-but-narrow windows, per the spec.
// =================================================================

class RosterTable extends StatelessWidget {
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color danger = Color(0xFFC62828);

  final List<RosterScheduleModel> schedules;
  final void Function(RosterScheduleModel schedule)? onDelete;

  const RosterTable({
    super.key,
    required this.schedules,
    this.onDelete,
  });

  String _dateText(DateTime? date) {
    if (date == null) return '—';

    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _display(String? value) {
    if (value == null || value.trim().isEmpty) return '—';
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth < 980 ? 980 : constraints.maxWidth,
            ),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 46,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 76,
              horizontalMargin: 12,
              columnSpacing: 22,
              dividerThickness: 0.6,
              headingTextStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7B8493),
                letterSpacing: 0.4,
              ),
              columns: const [
                DataColumn(label: Text('EMPLOYEE')),
                DataColumn(label: Text('DEPARTMENT')),
                DataColumn(label: Text('ASSIGNED SHIFT')),
                DataColumn(label: Text('SCHEDULE WINDOW')),
                DataColumn(label: Text('TIMINGS & GRACE')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('')),
              ],
              rows: schedules.map((schedule) {
                final isActive =
                    (schedule.status ?? 'active').toLowerCase() == 'active';

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 210,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _display(schedule.employeeName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                _display(schedule.employeeCode),
                                _display(schedule.employeeEmail),
                              ].join('  •  '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _display(schedule.departmentName),
                        style: const TextStyle(fontSize: 13, color: textMedium),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_display(schedule.shiftName)} (${_display(schedule.shiftCode)})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_dateText(schedule.startDate)} to ${_dateText(schedule.endDate)}',
                        style: const TextStyle(fontSize: 13, color: textMedium),
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_display(schedule.startTime)} – ${_display(schedule.endTime)}',
                            style: const TextStyle(fontSize: 13, color: textMedium),
                          ),
                          if (schedule.graceMinutes != null)
                            Text(
                              '${schedule.graceMinutes}m grace',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: textLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DataCell(_StatusBadge(isActive: isActive, status: schedule.status)),
                    DataCell(
                      onDelete == null
                          ? const SizedBox.shrink()
                          : IconButton(
                        tooltip: 'Remove schedule',
                        onPressed: () => onDelete!(schedule),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: danger,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final String? status;

  const _StatusBadge({required this.isActive, required this.status});

  @override
  Widget build(BuildContext context) {
    final label = (status == null || status!.trim().isEmpty)
        ? (isActive ? 'Active Schedule' : 'Inactive')
        : status!;

    final background =
    isActive ? const Color(0xFFE9F8EF) : const Color(0xFFFDECEC);
    final foreground =
    isActive ? const Color(0xFF18864B) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}