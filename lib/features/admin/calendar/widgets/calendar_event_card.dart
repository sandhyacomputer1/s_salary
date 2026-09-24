import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

class CalendarEventTypeStyle {
  final Color color;
  final Color background;
  final IconData icon;

  const CalendarEventTypeStyle({
    required this.color,
    required this.background,
    required this.icon,
  });

  static CalendarEventTypeStyle of(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.attendance:
        return const CalendarEventTypeStyle(
          color: Color(0xFF18864B),
          background: Color(0xFFE9F8EF),
          icon: Icons.check_circle_outline_rounded,
        );

      case CalendarEventType.leave:
        return const CalendarEventTypeStyle(
          color: Color(0xFFB7791F),
          background: Color(0xFFFFF4E0),
          icon: Icons.event_busy_outlined,
        );

      case CalendarEventType.holiday:
        return const CalendarEventTypeStyle(
          color: Color(0xFFC62828),
          background: Color(0xFFFDECEC),
          icon: Icons.celebration_outlined,
        );

      case CalendarEventType.shift:
        return const CalendarEventTypeStyle(
          color: Color(0xFF2878FF),
          background: Color(0xFFEAF1FF),
          icon: Icons.schedule_outlined,
        );
    }
  }
}

class CalendarEventCard extends StatelessWidget {
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE5E7EB);

  final CalendarEvent event;
  final VoidCallback? onTap;

  const CalendarEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  String? get _timeRange {
    if (event.startTime == null &&
        event.endTime == null) {
      return null;
    }

    if (event.startTime != null &&
        event.endTime != null) {
      return '${event.startTime} - ${event.endTime}';
    }

    return event.startTime ?? event.endTime;
  }

  @override
  Widget build(BuildContext context) {
    final style =
    CalendarEventTypeStyle.of(event.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: border,
          ),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =====================================================
            // ICON
            // =====================================================

            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius:
                BorderRadius.circular(9),
              ),
              child: Icon(
                style.icon,
                size: 18,
                color: style.color,
              ),
            ),

            const SizedBox(width: 12),

            // =====================================================
            // CONTENT
            // =====================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // TITLE + STATUS
                  // =================================================

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title.isEmpty
                              ? event.type.label
                              : event.title,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 13.5,
                            fontWeight:
                            FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                      ),

                      if (event.status != null &&
                          event.status!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(width: 8),

                        Flexible(
                          child: _statusChip(
                            event.status!,
                            style.color,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // =================================================
                  // EMPLOYEE NAME
                  // =================================================

                  if (event.employeeName != null &&
                      event.employeeName!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 4),

                    Text(
                      event.employeeName!,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: textMedium,
                      ),
                    ),
                  ],

                  // =================================================
                  // TIME
                  // =================================================

                  if (_timeRange != null) ...[
                    const SizedBox(height: 4),

                    Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: textLight,
                        ),

                        const SizedBox(width: 4),

                        Flexible(
                          child: Text(
                            _timeRange!,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 12,
                              color: textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // =================================================
                  // DESCRIPTION
                  // =================================================

                  if (event.description != null &&
                      event.description!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      event.description!,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // STATUS CHIP
  // ===============================================================

  Widget _statusChip(
      String status,
      Color color,
      ) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 100,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow:
        TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight:
          FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}