import 'package:flutter/material.dart';

import '../../../admin/dashboard/widgets/admin_brand_logo.dart';

/// Top of the sidebar: the "S" bolt logo + "Sandhya Salary"
/// (same design as the web and the admin sidebar).
///
/// Put it where the old logo box + "Sandhya Salary / Employee Portal" is.
/// The extra "Employee Portal" line is not shown (the web does not have it).
class EmpSidebarBrand extends StatelessWidget {
  /// true = icon only (collapsed sidebar)
  final bool collapsed;

  /// Optional collapse / expand button shown at the right.
  final Widget? trailing;

  const EmpSidebarBrand({super.key, this.collapsed = false, this.trailing});

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
        child: Column(
          children: [
            const AdminBrandLogo(size: 42),
            if (trailing != null) ...[const SizedBox(height: 12), trailing!],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 16),
      child: Row(
        children: [
          const AdminBrandLogo(size: 42),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sandhya Salary',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}