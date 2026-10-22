import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/emp_dash_attendance_model.dart';

class EmpDashBreakdownChart extends StatelessWidget {
  final EmpDashAttendanceSummary summary;

  /// Days marked as leave this month (not part of [summary]).
  final int onLeaveDays;

  const EmpDashBreakdownChart({
    super.key,
    required this.summary,
    this.onLeaveDays = 0,
  });

  static const Color present = Color(0xFF159957);
  static const Color late = Color(0xFFD99000);
  static const Color halfDay = Color(0xFF2563EB);
  static const Color absent = Color(0xFFD64545);
  static const Color onLeave = Color(0xFF8B5CF6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF18212F);
  static const Color textLight = Color(0xFF8A93A1);

  @override
  Widget build(BuildContext context) {
    final empty = summary.isEmpty && onLeaveDays == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
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
          if (empty) _buildEmptyState() else _buildChart(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 40, color: textLight),
            SizedBox(height: 10),
            Text(
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
      _Segment('On Leave', onLeaveDays, onLeave),
      _Segment('Late', summary.lateArrivals, late),
      _Segment('Half Day', summary.halfDays, halfDay),
      _Segment('Absent', summary.absences, absent),
    ].where((s) => s.value > 0).toList();

    final total = segments.fold<int>(0, (sum, s) => sum + s.value);

    final donut = SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _DonutPainter(segments: segments, total: total),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const Text(
                'DAYS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final legend = Wrap(
      spacing: 40,
      runSpacing: 16,
      children: [
        for (final s in segments)
          _LegendItem(
            segment: s,
            percent: total > 0 ? (s.value / total * 100).round() : 0,
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              donut,
              const SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: legend),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            donut,
            const SizedBox(width: 36),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _Segment {
  final String label;
  final int value;
  final Color color;

  const _Segment(this.label, this.value, this.color);
}

class _LegendItem extends StatelessWidget {
  final _Segment segment;
  final int percent;

  const _LegendItem({required this.segment, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: segment.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${segment.label} (${segment.value})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: EmpDashBreakdownChart.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$percent% of month',
              style: const TextStyle(
                fontSize: 11.5,
                color: EmpDashBreakdownChart.textLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
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
    const strokeWidth = 20.0;

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