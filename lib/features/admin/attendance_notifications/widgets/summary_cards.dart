// lib/features/admin/attendance_notifications/widgets/summary_cards.dart

import 'package:flutter/material.dart';
import '../utils/notification_theme.dart';

class NotificationSummaryCards extends StatelessWidget {
  final int totalIns;
  final int totalOuts;
  final int lateArrivals;
  final int inOffice;

  const NotificationSummaryCards({
    super.key,
    required this.totalIns,
    required this.totalOuts,
    required this.lateArrivals,
    required this.inOffice,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth > 800;
        final isMed = c.maxWidth > 500;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _SummaryCard(
              label: 'TOTAL CHECK-INS TODAY',
              value: '$totalIns',
              width: isWide ? (c.maxWidth - 48) / 4 : (isMed ? (c.maxWidth - 16) / 2 : c.maxWidth),
            ),
            _SummaryCard(
              label: 'TOTAL CHECK-OUTS TODAY',
              value: '$totalOuts',
              width: isWide ? (c.maxWidth - 48) / 4 : (isMed ? (c.maxWidth - 16) / 2 : c.maxWidth),
              isFilled: true,
            ),
            _SummaryCard(
              label: 'LATE ARRIVALS TODAY',
              value: '$lateArrivals',
              width: isWide ? (c.maxWidth - 48) / 4 : (isMed ? (c.maxWidth - 16) / 2 : c.maxWidth),
            ),
            _SummaryCard(
              label: 'CURRENTLY IN OFFICE',
              value: '$inOffice',
              width: isWide ? (c.maxWidth - 48) / 4 : (isMed ? (c.maxWidth - 16) / 2 : c.maxWidth),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final double width;
  final bool isFilled;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.width,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isFilled ? NotificationColors.primary : NotificationColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFilled ? NotificationColors.primary : NotificationColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: NotificationText.summaryLabel.copyWith(
              color: isFilled ? Colors.white.withValues(alpha: 0.9) : NotificationColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: NotificationText.summaryValue.copyWith(
              color: isFilled ? Colors.white : NotificationColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}