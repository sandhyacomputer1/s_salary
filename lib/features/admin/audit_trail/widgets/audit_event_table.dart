import 'package:flutter/material.dart';

import '../models/audit_log_model.dart';
import 'audit_format.dart';

const Color _kTextDark = Color(0xFF18212F);
const Color _kMuted = Color(0xFF7A8494);
const Color _kPrimary = Color(0xFFE96832);

/// Audit events table: TIMESTAMP, USER / EMAIL, ACTION, STATUS, IP ADDRESS.
///
/// - Scrolls horizontally when the screen is narrower than [_minWidth].
/// - First load (no rows yet): skeleton rows.
/// - Later loads: the previous rows stay visible, dimmed, with a thin
///   progress bar, so the layout never jumps.
class AuditEventTable extends StatelessWidget {
  const AuditEventTable({
    super.key,
    required this.logs,
    required this.isLoading,
  });

  final List<AuditLog> logs;
  final bool isLoading;

  static const double _minWidth = 780;

  // Column weights: timestamp, user, action, status, ip.
  static const List<int> _flex = [3, 4, 3, 2, 3];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
        constraints.maxWidth < _minWidth ? _minWidth : constraints.maxWidth;

        final refreshing = isLoading && logs.isNotEmpty;

        return Stack(
          children: [
            Opacity(
              opacity: refreshing ? 0.5 : 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      _header(),
                      if (logs.isEmpty)
                        for (var i = 0; i < 8; i++) _skeletonRow()
                      else
                        for (var i = 0; i < logs.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: Color(0xFFEDEFF3)),
                          _AuditRow(log: logs[i], flex: _flex),
                        ],
                    ],
                  ),
                ),
              ),
            ),
            if (refreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: _kPrimary,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _header() {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: Color(0xFF7B8493),
    );

    Widget cell(String text, int flex) =>
        Expanded(flex: flex, child: Text(text, style: style));

    return Container(
      color: const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          cell('TIMESTAMP', _flex[0]),
          cell('USER / EMAIL', _flex[1]),
          cell('ACTION', _flex[2]),
          cell('STATUS', _flex[3]),
          cell('IP ADDRESS', _flex[4]),
        ],
      ),
    );
  }

  Widget _skeletonRow() {
    Widget block(double width) => Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          Expanded(flex: _flex[0], child: Align(
            alignment: Alignment.centerLeft,
            child: block(150),
          )),
          Expanded(flex: _flex[1], child: Align(
            alignment: Alignment.centerLeft,
            child: block(170),
          )),
          Expanded(flex: _flex[2], child: Align(
            alignment: Alignment.centerLeft,
            child: block(70),
          )),
          Expanded(flex: _flex[3], child: Align(
            alignment: Alignment.centerLeft,
            child: block(70),
          )),
          Expanded(flex: _flex[4], child: Align(
            alignment: Alignment.centerLeft,
            child: block(110),
          )),
        ],
      ),
    );
  }
}

// =================================================================
// ROW (highlights on hover)
// =================================================================

class _AuditRow extends StatefulWidget {
  const _AuditRow({required this.log, required this.flex});

  final AuditLog log;
  final List<int> flex;

  @override
  State<_AuditRow> createState() => _AuditRowState();
}

class _AuditRowState extends State<_AuditRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final flex = widget.flex;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Container(
        color: _hover ? const Color(0xFFFFF8F3) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: flex[0],
              child: Text(
                AuditFormat.timestamp(log.timestamp),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Expanded(
              flex: flex[1],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AuditFormat.text(log.email),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                    ),
                  ),
                  if (log.roleLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      log.roleLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: flex[2],
              child: Text(
                AuditFormat.text(log.action),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
            ),
            Expanded(
              flex: flex[3],
              child: Align(
                alignment: Alignment.centerLeft,
                child: AuditStatusBadge(status: log.status),
              ),
            ),
            Expanded(
              flex: flex[4],
              child: Text(
                AuditFormat.text(log.ipAddress),
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// STATUS BADGE (text + colour, so it never relies on colour alone)
// =================================================================

class AuditStatusBadge extends StatelessWidget {
  const AuditStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final text = status.trim();

    if (text.isEmpty) {
      return const Text(AuditFormat.empty, style: TextStyle(color: _kMuted));
    }

    final color = AuditFormat.statusColor(text);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AuditFormat.statusBackground(text),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}