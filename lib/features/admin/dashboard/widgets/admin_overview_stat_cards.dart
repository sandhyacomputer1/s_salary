import 'package:flutter/material.dart';

import '../../employees/widgets/admin_employee_theme.dart';

/// ACTIVE EMPLOYEES (orange, "5 / 10") | PENDING LEAVES | PENDING EXPENSES | ARCHIVED EMPLOYEES
class AdminOverviewStatCards extends StatelessWidget {
  final String activeValue;
  final int pendingLeaves;
  final int pendingExpenses;
  final int archived;

  const AdminOverviewStatCards({
    super.key,
    required this.activeValue,
    required this.pendingLeaves,
    required this.pendingExpenses,
    required this.archived,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final compact = c.maxWidth < 600;

        final cols = wide ? 4 : 2;
        final gap = wide ? 18.0 : (compact ? 10.0 : 12.0);
        final w = (c.maxWidth - gap * (cols - 1)) / cols;

        final cards = <Widget>[
          _card('ACTIVE EMPLOYEES', 'ACTIVE', activeValue, compact, highlighted: true),
          _card('PENDING LEAVES', 'PENDING LEAVES', '$pendingLeaves', compact),
          _card('PENDING EXPENSES', 'PENDING EXPENSES', '$pendingExpenses', compact),
          _card('ARCHIVED EMPLOYEES', 'ARCHIVED', '$archived', compact),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }

  Widget _card(
      String label,
      String shortLabel,
      String value,
      bool compact, {
        bool highlighted = false,
      }) {
    final fg = highlighted ? Colors.white : AdminEmpColors.text;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        color: highlighted ? null : Colors.white,
        gradient: highlighted
            ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE96832), Color(0xFFD9622D)],
        )
            : null,
        border: highlighted ? null : Border.all(color: const Color(0xFFEDEFF3)),
        boxShadow: [
          BoxShadow(
            color: highlighted ? const Color(0x33E96832) : const Color(0x0A000000),
            blurRadius: highlighted ? (compact ? 10 : 16) : (compact ? 6 : 10),
            offset: Offset(0, compact ? 3 : 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // building watermark (like the web)
          if (highlighted)
            Positioned(
              right: compact ? -4 : -6,
              bottom: compact ? -10 : -14,
              child: Icon(
                Icons.apartment_rounded,
                size: compact ? 62 : 104,
                color: Colors.white.withOpacity(0.16),
              ),
            ),
          Padding(
            padding: compact
                ? const EdgeInsets.fromLTRB(14, 12, 14, 12)
                : const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // FittedBox: a long label shrinks instead of showing "..."
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    compact ? shortLabel : label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: compact ? 10.5 : 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: compact ? 0.5 : 0.8,
                      color: highlighted ? Colors.white : AdminEmpColors.muted,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 24 : 34,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}