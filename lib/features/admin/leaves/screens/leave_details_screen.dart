import 'package:flutter/material.dart';

import '../models/leave_model.dart';

class LeaveDetailsScreen extends StatefulWidget {
  final LeaveModel leave;

  // Each callback returns true when the action succeeded.
  final Future<bool> Function()? onApprove;
  final Future<bool> Function()? onReject;

  const LeaveDetailsScreen({
    super.key,
    required this.leave,
    this.onApprove,
    this.onReject,
  });

  @override
  State<LeaveDetailsScreen> createState() => _LeaveDetailsScreenState();
}

class _LeaveDetailsScreenState extends State<LeaveDetailsScreen> {
  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFEEE7);
  static const Color danger = Color(0xFFD64545);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color tableHeaderBg = Color(0xFFF7F8FA);

  bool _approving = false;
  bool _rejecting = false;

  bool get _busy => _approving || _rejecting;

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

  Future<void> _approve(BuildContext context) async {
    if (widget.onApprove == null || _busy) return;

    setState(() => _approving = true);

    final success = await widget.onApprove!();

    if (!mounted) return;

    setState(() => _approving = false);

    if (success) {
      Navigator.pop(context);
    }
  }

  Future<void> _reject(BuildContext context) async {
    if (widget.onReject == null || _busy) return;

    setState(() => _rejecting = true);

    final success = await widget.onReject!();

    if (!mounted) return;

    setState(() => _rejecting = false);

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leave = widget.leave;
    final isPending = leave.status.toLowerCase() == 'pending';
    final hasReason = leave.reason.trim().isNotEmpty;
    final style = _statusStyle(leave.status);
    final hasActions =
        isPending && (widget.onApprove != null || widget.onReject != null);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Leave Details',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact header strip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'leave-avatar-${leave.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: primaryLight,
                          child: Text(
                            _avatarInitial(leave),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.employeeDisplayLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            leave.leaveType.isEmpty
                                ? 'Leave'
                                : leave.leaveType,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: textMedium,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatDays(leave.totalDays)} day(s)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: style.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            leave.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: style.accent,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Leave Information table
              _TableCard(
                title: 'Leave Information',
                icon: Icons.event_note_outlined,
                rows: [
                  _TableRow('Leave Type', leave.leaveType),
                  _TableRow('Start Date', _formatDate(leave.startDate)),
                  _TableRow('End Date', _formatDate(leave.endDate)),
                  _TableRow('Total Days', _formatDays(leave.totalDays)),
                  _TableRow('Half Day', leave.isHalfDay ? 'Yes' : 'No'),
                  _TableRow('Paid', leave.isPaid ? 'Yes' : 'No'),
                  _TableRow('Status', leave.status),
                  _TableRow(
                    'Reason',
                    hasReason ? leave.reason : 'No reason provided',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Timeline table
              _TableCard(
                title: 'Timeline',
                icon: Icons.timeline_rounded,
                rows: [
                  _TableRow('Applied At', _formatDateTime(leave.appliedAt)),
                  _TableRow('Created At', _formatDateTime(leave.createdAt)),
                  if (leave.actionedAt != null)
                    _TableRow('Actioned At', _formatDateTime(leave.actionedAt)),
                  if (leave.approvedBy.trim().isNotEmpty)
                    _TableRow(
                      leave.isRejected ? 'Rejected By' : 'Approved By',
                      leave.approvedBy,
                    ),
                ],
              ),

              // Space for the bottom action bar
              if (hasActions)
                const SizedBox(height: 90)
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      // Footer action bar
      bottomNavigationBar: hasActions
          ? SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              if (widget.onReject != null)
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _reject(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: danger,
                        side: BorderSide(
                          color: danger.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: _rejecting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: danger,
                        ),
                      )
                          : const Text(
                        'Reject',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.onReject != null && widget.onApprove != null)
                const SizedBox(width: 12),
              if (widget.onApprove != null)
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _busy ? null : () => _approve(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: _approving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Approve',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  String _formatDays(double days) {
    return days.truncateToDouble() == days
        ? days.toStringAsFixed(0)
        : days.toStringAsFixed(1);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return '${_formatDate(date)} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

class _StatusStyle {
  final Color accent;
  final Color background;

  const _StatusStyle({required this.accent, required this.background});
}

class _TableRow {
  final String label;
  final String value;

  const _TableRow(this.label, this.value);
}

class _TableCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_TableRow> rows;
  final Widget? trailingAction;

  const _TableCard({
    required this.title,
    required this.icon,
    required this.rows,
    this.trailingAction,
  });

  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color border = Color(0xFFE1E5EA);
  static const Color tableHeaderBg = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: tableHeaderBg,
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ),
                if (trailingAction != null) trailingAction!,
              ],
            ),
          ),
          // Table rows
          for (int i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: border)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: tableHeaderBg,
                        border: Border(right: BorderSide(color: border)),
                      ),
                      child: Text(
                        rows[i].label,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textMedium,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          rows[i].value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}