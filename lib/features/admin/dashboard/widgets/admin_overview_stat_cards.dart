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
    final cards = <Widget>[
      _card('ACTIVE EMPLOYEES', activeValue, highlighted: true),
      _card('PENDING LEAVES', '$pendingLeaves'),
      _card('PENDING EXPENSES', '$pendingExpenses'),
      _card('ARCHIVED EMPLOYEES', '$archived'),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 4 : 2;
        final gap = c.maxWidth >= 900 ? 18.0 : 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }

  Widget _card(String label, String value, {bool highlighted = false}) {
    final fg = highlighted ? Colors.white : AdminEmpColors.text;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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
            blurRadius: highlighted ? 16 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // building watermark (like the web)
          if (highlighted)
            Positioned(
              right: -6,
              bottom: -14,
              child: Icon(
                Icons.apartment_rounded,
                size: 104,
                color: Colors.white.withOpacity(0.16),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: highlighted ? Colors.white : AdminEmpColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 34,
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