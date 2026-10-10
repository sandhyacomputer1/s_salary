// lib/features/employee/profile/widgets/profile_grid.dart

import 'package:flutter/material.dart';

import '../utils/profile_colors.dart';

class ProfileGrid extends StatelessWidget {
  final List<ProfileGridItem> items;

  /// Approximate per-cell width on desktop; the grid wraps responsively.
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
        // Cells per row: at least 2, at most 7 depending on width.
        final maxPerRow = width < 400
            ? 2
            : width < 700
            ? 3
            : width < 1000
            ? 4
            : 7;
        final spacing = 12.0;
        final itemWidth =
            (width - spacing * (maxPerRow - 1)) / maxPerRow;

        return Wrap(
          spacing: spacing,
          runSpacing: 18,
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
  final bool valueIsAccent;   // orange value (EMPLOYEE CODE ID, emergency phone)

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
    return Column(
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
    );
  }
}