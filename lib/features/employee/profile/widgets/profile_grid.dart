// lib/features/employee/profile/widgets/profile_grid.dart

import 'package:flutter/material.dart';

import '../utils/profile_colors.dart';

class ProfileGrid extends StatelessWidget {
  final List<ProfileGridItem> items;

  /// Kept for compatibility. The grid now decides the number of
  /// columns from the available width.
  final double cellWidth;

  const ProfileGrid({
    super.key,
    required this.items,
    this.cellWidth = 170,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Phone: 1 column. Tablet: 2-3. Web: 4.
        final perRow = width < 460
            ? 1
            : width < 760
            ? 2
            : width < 1100
            ? 3
            : 4;

        const spacing = 12.0;
        final itemWidth = (width - spacing * (perRow - 1)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final it in items)
              SizedBox(
                width: it.fullWidth ? width : itemWidth,
                child: _Cell(item: it),
              ),
          ],
        );
      },
    );
  }
}

class ProfileGridItem {
  final String label;
  final String value;
  final bool fullWidth;
  final bool valueIsAccent; // orange value (EMPLOYEE CODE ID, emergency phone)

  const ProfileGridItem(
      this.label,
      this.value, {
        this.fullWidth = false,
        this.valueIsAccent = false,
      });
}

class _Cell extends StatelessWidget {
  final ProfileGridItem item;
  const _Cell({required this.item});

  @override
  Widget build(BuildContext context) {
    final value = item.value.trim().isEmpty ? '—' : item.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ProfileColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label.toUpperCase(), style: ProfileColors.labelStyle),
          const SizedBox(height: 6),
          Text(
            value,
            style: ProfileColors.valueStyle.copyWith(
              color: item.valueIsAccent
                  ? ProfileColors.primary
                  : ProfileColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}