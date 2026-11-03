import 'package:flutter/material.dart';

import '../../employees/widgets/admin_employee_theme.dart';

/// ACTIVE EMPLOYEES (orange, "5 / 10") | PENDING LEAVES | PENDING EXPENSES | ARCHIVED EMPLOYEES
/// 4 in a row on web, 2 x 2 on phones (smaller text, nothing is cut).
///
/// PERMISSION: each card can be hidden with its show... flag. Cards keep the
/// same size whether 1 or 4 are shown.
class AdminOverviewStatCards extends StatelessWidget {
  final String activeValue;
  final int pendingLeaves;
  final int pendingExpenses;
  final int archived;

  final bool showActive;
  final bool showLeaves;
  final bool showExpenses;
  final bool showArchived;

  const AdminOverviewStatCards({
    super.key,
    required this.activeValue,
    required this.pendingLeaves,
    required this.pendingExpenses,
    required this.archived,
    this.showActive = true,
    this.showLeaves = true,
    this.showExpenses = true,
    this.showArchived = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final cols = wide ? 4 : 2;
        final gap = wide ? 18.0 : 12.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;

        final cards = <Widget>[
          if (showActive) _card('ACTIVE EMPLOYEES', activeValue, wide, highlighted: true),
          if (showLeaves) _card('PENDING LEAVES', '$pendingLeaves', wide),
          if (showExpenses) _card('PENDING EXPENSES', '$pendingExpenses', wide),
          if (showArchived) _card('ARCHIVED EMPLOYEES', '$archived', wide),
        ];

        if (cards.isEmpty) return const SizedBox.shrink();

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final card in cards) SizedBox(width: w, child: card)],
        );
      },
    );
  }

  Widget _card(String label, String value, bool wide, {bool highlighted = false}) {
    final fg = highlighted ? Colors.white : AdminEmpColors.text;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(wide ? 14 : 12),
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
            blurRadius: highlighted ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // building watermark (smaller + lighter on phones so it never covers the number)
          if (highlighted)
            Positioned(
              right: wide ? -6 : -10,
              bottom: wide ? -14 : -12,
              child: Icon(
                Icons.apartment_rounded,
                size: wide ? 104 : 58,
                color: Colors.white.withOpacity(wide ? 0.16 : 0.12),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 14, wide ? 20 : 14, wide ? 24 : 12, wide ? 20 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FittedBox: a long label shrinks instead of showing "EMPLOY…"
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: wide ? 12 : 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: wide ? 0.8 : 0.5,
                      color: highlighted ? Colors.white : AdminEmpColors.muted,
                    ),
                  ),
                ),
                SizedBox(height: wide ? 10 : 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: wide ? 34 : 27,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: fg,
                    ),
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