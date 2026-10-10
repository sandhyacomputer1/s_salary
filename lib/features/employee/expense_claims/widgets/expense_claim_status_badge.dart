import 'package:flutter/material.dart';

import '../models/expense_claim_model.dart';

class ExpenseClaimStatusBadge extends StatelessWidget {
  final ExpenseClaimStatus status;

  /// Used only when status is unknown (shows the server's raw text).
  final String? rawStatus;

  const ExpenseClaimStatusBadge({
    super.key,
    required this.status,
    this.rawStatus,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);
    final label = (status == ExpenseClaimStatus.unknown &&
        rawStatus != null &&
        rawStatus!.isNotEmpty)
        ? rawStatus!
        : status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: style.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeStyle _styleFor(ExpenseClaimStatus s) {
    switch (s) {
      case ExpenseClaimStatus.pending: // amber
        return const _BadgeStyle(
          background: Color(0xFFFFF8E1),
          border: Color(0xFFFFE082),
          foreground: Color(0xFFB26A00),
          icon: Icons.schedule,
        );
      case ExpenseClaimStatus.approved: // green
        return const _BadgeStyle(
          background: Color(0xFFE8F5E9),
          border: Color(0xFFA5D6A7),
          foreground: Color(0xFF2E7D32),
          icon: Icons.check_circle_outline,
        );
      case ExpenseClaimStatus.rejected: // red
        return const _BadgeStyle(
          background: Color(0xFFFFEBEE),
          border: Color(0xFFEF9A9A),
          foreground: Color(0xFFC62828),
          icon: Icons.cancel_outlined,
        );
      case ExpenseClaimStatus.reimbursed: // blue
        return const _BadgeStyle(
          background: Color(0xFFE3F2FD),
          border: Color(0xFF90CAF9),
          foreground: Color(0xFF1565C0),
          icon: Icons.payments_outlined,
        );
      case ExpenseClaimStatus.cancelled: // grey
      case ExpenseClaimStatus.unknown:
        return const _BadgeStyle(
          background: Color(0xFFF5F5F5),
          border: Color(0xFFE0E0E0),
          foreground: Color(0xFF616161),
          icon: Icons.remove_circle_outline,
        );
    }
  }
}

class _BadgeStyle {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  const _BadgeStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });
}