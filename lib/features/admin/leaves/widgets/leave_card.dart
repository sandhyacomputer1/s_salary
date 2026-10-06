import 'package:flutter/material.dart';

import '../models/leave_model.dart';

class LeaveCard extends StatefulWidget {
  final LeaveModel leave;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final int index;

  const LeaveCard({
    super.key,
    required this.leave,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.index = 0,
  });

  @override
  State<LeaveCard> createState() => _LeaveCardState();
}

class _LeaveCardState extends State<LeaveCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _pressed = false;

  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFEEE7);
  static const Color danger = Color(0xFFD64545);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color tableHeaderBg = Color(0xFFF7F8FA);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: 30 * widget.index.clamp(0, 12));

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _StatusStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const _StatusStyle(
          accent: Color(0xFF159957),
          background: Color(0xFFE7F7EF),
        );
      case 'rejected':
        return const _StatusStyle(
          accent: danger,
          background: Color(0xFFFFE8E8),
        );
      case 'cancelled':
        return const _StatusStyle(
          accent: textLight,
          background: Color(0xFFF1F2F4),
        );
      default:
        return const _StatusStyle(
          accent: primary,
          background: primaryLight,
        );
    }
  }

  String _avatarInitial(LeaveModel leave) {
    final name = leave.employeeName;

    if (name != '—' && name.trim().isNotEmpty) {
      return name.trim().characters.first.toUpperCase();
    }

    final code = leave.employeeCode;

    if (code == '—' || code.trim().isEmpty) {
      return '?';
    }

    return code.replaceAll('EMP-', '').characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final leave = widget.leave;
    final isPending = leave.status.toLowerCase() == 'pending';
    final style = _statusStyle(leave.status);
    final hasReason = leave.reason.trim().isNotEmpty;
    final hasActions =
        isPending && (widget.onApprove != null || widget.onReject != null);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title bar — employee + leave type + status chip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: const BoxDecoration(
                      color: tableHeaderBg,
                      border: Border(bottom: BorderSide(color: border)),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'leave-avatar-${leave.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: primaryLight,
                              child: Text(
                                _avatarInitial(leave),
                                style: const TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leave.employeeDisplayLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      leave.leaveType.isEmpty
                                          ? 'Leave'
                                          : leave.leaveType,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: textMedium,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (leave.isHalfDay) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE9F0FF),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Text(
                                        'Half Day',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: style.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            leave.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: style.accent,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mixed grid: 2 columns x 2 rows
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _GridCell(
                            label: 'Start Date',
                            value: _formatDate(leave.startDate),
                          ),
                        ),
                        const VerticalDivider(width: 1, color: border),
                        Expanded(
                          child: _GridCell(
                            label: 'End Date',
                            value: _formatDate(leave.endDate),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: border),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _GridCell(
                            label: 'Total Days',
                            value: _formatDays(leave.totalDays),
                            bold: true,
                          ),
                        ),
                        const VerticalDivider(width: 1, color: border),
                        Expanded(
                          child: _GridCell(
                            label: 'Paid',
                            value: leave.isPaid ? 'Yes' : 'No',
                            valueColor:
                            leave.isPaid ? textDark : textLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reason — full-width row (only if present)
                  if (hasReason) ...[
                    const Divider(height: 1, color: border),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 78,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              color: tableHeaderBg,
                              border: Border(right: BorderSide(color: border)),
                            ),
                            child: const Text(
                              'Reason',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textMedium,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                leave.reason,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Reject / Approve actions (pending only)
                  if (hasActions)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          if (widget.onReject != null)
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: widget.onReject,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: danger,
                                    side: BorderSide(
                                      color: danger.withValues(alpha: 0.5),
                                    ),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Reject',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (widget.onReject != null &&
                              widget.onApprove != null)
                            const SizedBox(width: 8),
                          if (widget.onApprove != null)
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: widget.onApprove,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Approve',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDays(double days) {
    return days.truncateToDouble() == days
        ? days.toStringAsFixed(0)
        : days.toStringAsFixed(1);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _StatusStyle {
  final Color accent;
  final Color background;

  const _StatusStyle({required this.accent, required this.background});
}

class _GridCell extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _GridCell({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textMedium,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? textDark,
            ),
          ),
        ],
      ),
    );
  }
}