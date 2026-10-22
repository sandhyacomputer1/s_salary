import 'package:flutter/material.dart';

/// Compact stat card (label + big number), like the web dashboard.
/// [highlighted] paints it orange (used for the first card).
class EmpDashSummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool highlighted;

  const EmpDashSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.highlighted = false,
  });

  static const Color _primary = Color(0xFFE96832);

  @override
  Widget build(BuildContext context) {
    final labelColor =
    highlighted ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF8A93A1);
    final valueColor = highlighted ? Colors.white : const Color(0xFF18212F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: highlighted ? null : Colors.white,
        gradient: highlighted
            ? const LinearGradient(
          colors: [Color(0xFFE96832), Color(0xFFD85A28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? _primary : const Color(0xFFE5E7EB),
        ),
        boxShadow: highlighted
            ? [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ]
            : const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: highlighted
                  ? Colors.white.withValues(alpha: 0.2)
                  : iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: highlighted ? Colors.white : iconColor,
            ),
          ),
        ],
      ),
    );
  }
}