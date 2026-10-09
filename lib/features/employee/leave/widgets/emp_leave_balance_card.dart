import 'package:flutter/material.dart';

import '../models/emp_leave_balance_model.dart';

class EmpLeaveBalanceCard extends StatelessWidget {
  final EmpLeaveBalanceModel balance;

  const EmpLeaveBalanceCard({super.key, required this.balance});

  static const Color primary = Color(0xFFE96832);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);

  Color get _numberColor {
    switch (balance.leaveType.toLowerCase()) {
      case 'casual':
        return const Color(0xFFE0552D);
      case 'sick':
        return const Color(0xFFD64545);
      case 'earned':
        return const Color(0xFF159957);
      case 'unpaid':
        return const Color(0xFFD99000);
      default:
        return primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            balance.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textMedium,
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: EmpLeaveTypeHelper.formatDays(balance.remaining),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _numberColor,
                  ),
                ),
                TextSpan(
                  text: ' / ${EmpLeaveTypeHelper.formatDays(balance.allotted)} Days',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textLight,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${EmpLeaveTypeHelper.formatDays(balance.used)} Day(s) Used',
            style: const TextStyle(fontSize: 12.5, color: textLight),
          ),
        ],
      ),
    );
  }
}