// lib/features/admin/attendance_notifications/widgets/summary_cards.dart

import 'package:flutter/material.dart';
import '../utils/notification_theme.dart';

/// Layout:
///  - Web (>800 px)   : 4 cards in one row            (big cards)
///  - Tablet (700-800): 2 cards per row               (big cards)
///  - Phone  (<700 px): 2 cards per row = only 2 lines (compact, light cards)
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
        final compact = c.maxWidth < 700;
        final isWide = c.maxWidth > 800;

        final double gap = compact ? 10 : 16;

        // card width
        final double width;
        if (isWide) {
          width = (c.maxWidth - gap * 3) / 4; // 4 in a row
        } else {
          width = (c.maxWidth - gap) / 2; // 2 in a row
        }
        final cardWidth = width.floorToDouble();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _SummaryCard(
              label: 'TOTAL CHECK-INS TODAY',
              value: '$totalIns',
              width: cardWidth,
              compact: compact,
            ),
            _SummaryCard(
              label: 'TOTAL CHECK-OUTS TODAY',
              value: '$totalOuts',
              width: cardWidth,
              compact: compact,
              isFilled: true,
            ),
            _SummaryCard(
              label: 'LATE ARRIVALS TODAY',
              value: '$lateArrivals',
              width: cardWidth,
              compact: compact,
            ),
            _SummaryCard(
              label: 'CURRENTLY IN OFFICE',
              value: '$inOffice',
              width: cardWidth,
              compact: compact,
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
  final bool compact;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.width,
    required this.compact,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isFilled
        ? Colors.white.withValues(alpha: 0.9)
        : NotificationColors.textLight;
    final valueColor =
    isFilled ? Colors.white : NotificationColors.textDark;

    return Container(
      width: width,
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isFilled
            ? NotificationColors.primary
            : NotificationColors.surface,
        borderRadius: BorderRadius.circular(compact ? 10 : 10),
        border: Border.all(
          color: isFilled
              ? NotificationColors.primary
              : NotificationColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // On phones the label shrinks a little instead of wrapping, so
          // both cards in a row always have the same height.
          compact
              ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: NotificationText.summaryLabel.copyWith(
                fontSize: 9.5,
                letterSpacing: 0.3,
                color: labelColor,
              ),
            ),
          )
              : Text(
            label,
            style: NotificationText.summaryLabel.copyWith(
              color: labelColor,
            ),
          ),
          SizedBox(height: compact ? 6 : 12),
          Text(
            value,
            style: NotificationText.summaryValue.copyWith(
              fontSize: compact ? 22 : null,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}