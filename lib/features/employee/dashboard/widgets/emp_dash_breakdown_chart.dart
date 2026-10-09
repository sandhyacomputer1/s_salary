import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/emp_dash_attendance_model.dart';

class EmpDashBreakdownChart extends StatelessWidget {
  final EmpDashAttendanceSummary summary;

  const EmpDashBreakdownChart({super.key, required this.summary});

  static const Color present = Color(0xFF159957);
  static const Color late = Color(0xFFD99000);
  static const Color halfDay = Color(0xFF2563EB);
  static const Color absent = Color(0xFFD64545);
  static const Color border = Color(0xFFE1E5EA);
  static const Color textDark = Color(0xFF18212F);
  static const Color textLight = Color(0xFF8A93A1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Performance Breakdown',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 20),
          if (summary.isEmpty)
            _buildEmptyState()
          else
            _buildChart(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: textLight),
            const SizedBox(height: 10),
            const Text(
              'No attendance data for this month yet',
              style: TextStyle(fontSize: 13, color: textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final segments = <_Segment>[
      _Segment('Present', summary.presentDays, present),
      _Segment('Late', summary.lateArrivals, late),
      _Segment('Half Day', summary.halfDays, halfDay),
      _Segment('Absent', summary.absences, absent),
    ].where((s) => s.value > 0).toList();

    final total = segments.fold<int>(0, (sum, s) => sum + s.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            painter: _DonutPainter(segments: segments, total: total),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const Text(
                    'days',
                    style: TextStyle(fontSize: 11, color: textLight),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: segments.map((s) {
              final pct = total > 0 ? (s.value / total * 100) : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ),
                    Text(
                      '${s.value} (${pct.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Segment {
  final String label;
  final int value;
  final Color color;

  const _Segment(this.label, this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;
  final int total;

  _DonutPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 18.0;

    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.total != total;
  }
}