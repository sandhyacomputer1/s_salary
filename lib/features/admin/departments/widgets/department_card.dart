import 'package:flutter/material.dart';

import '../../../../data/models/employee.dart';
import '../models/department_model.dart';

// ============================================================================
// DEPARTMENT COLORS
// ============================================================================

const Color departmentPrimary = Color(0xFFE96832);
const Color departmentTextDark = Color(0xFF18212F);
const Color departmentTextMedium = Color(0xFF4B5563);
const Color departmentTextLight = Color(0xFF64748B);
const Color departmentBorder = Color(0xFFE2E8F0);

// ============================================================================
// DEPARTMENT CARD
//
// Uses the same Employee model used by EmployeeService.
//
// Employee API -> Employee
// ============================================================================

class DepartmentCard extends StatelessWidget {
  final DepartmentModel department;

  final bool isExpanded;

  final List<Employee> employees;

  // Callbacks
  final VoidCallback onViewStaff;
  final VoidCallback onMove;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  final ValueChanged<Employee>? onViewEmployee;

  const DepartmentCard({
    super.key,
    required this.department,
    required this.isExpanded,
    required this.employees,
    required this.onViewStaff,
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
    this.onViewEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: departmentBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================================================
            // HEADER
            // ================================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    department.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: departmentTextDark,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${department.employeeCount} Staff',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0784C6),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ================================================================
            // CODE
            // ================================================================

            Text(
              'Code: ${department.code}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: departmentTextDark,
              ),
            ),

            const SizedBox(height: 16),

            // ================================================================
            // DESCRIPTION
            // ================================================================

            Text(
              department.description.isEmpty
                  ? 'No description available'
                  : department.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: departmentTextLight,
              ),
            ),

            const SizedBox(height: 18),

            const Divider(
              height: 1,
              color: departmentBorder,
            ),

            const SizedBox(height: 12),

            // ================================================================
            // ACTION BUTTONS
            // ================================================================

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: isExpanded ? 'Hide Staff' : 'View Staff',
                    icon: isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.people_outline_rounded,
                    onPressed: onViewStaff,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _ActionButton(
                    label: 'Move',
                    icon: Icons.drive_file_move_outline,
                    onPressed: onMove,
                  ),
                ),

                const SizedBox(width: 8),

                _SmallActionButton(
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                ),

                const SizedBox(width: 8),

                _SmallActionButton(
                  icon: Icons.delete_outline_rounded,
                  onPressed: onDelete,
                  danger: true,
                ),
              ],
            ),

            // ================================================================
            // EMPLOYEE LIST
            // ================================================================

            if (isExpanded) ...[
              const SizedBox(height: 14),

              const Divider(
                height: 1,
                color: departmentBorder,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Assigned Employees',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: departmentTextDark,
                      ),
                    ),
                  ),

                  Text(
                    '${employees.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: departmentPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (employees.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'No employees assigned to this department.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: departmentTextLight,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ...employees.map(
                      (employee) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EmployeePreview(
                      employee: employee,
                      onView: onViewEmployee == null
                          ? null
                          : () => onViewEmployee!(employee),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ACTION BUTTON
// ============================================================================

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 17,
      ),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: departmentTextDark,
        side: const BorderSide(
          color: departmentBorder,
        ),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
      ),
    );
  }
}

// ============================================================================
// SMALL ACTION BUTTON
// ============================================================================

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  const _SmallActionButton({
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor:
          danger ? Colors.red : departmentTextDark,
          side: BorderSide(
            color: danger
                ? Colors.red.shade200
                : departmentBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
        ),
      ),
    );
  }
}

// ============================================================================
// EMPLOYEE PREVIEW
// ============================================================================

class _EmployeePreview extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onView;

  const _EmployeePreview({
    required this.employee,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final employeeName = employee.name.trim().isEmpty
        ? 'Unnamed Employee'
        : employee.name.trim();

    final firstLetter = employeeName.isEmpty
        ? '?'
        : employeeName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          // ================================================================
          // AVATAR
          // ================================================================

          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFFEEE7),
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: departmentPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ================================================================
          // EMPLOYEE INFO
          // ================================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: departmentTextDark,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  employee.employeeCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: departmentTextLight,
                  ),
                ),
              ],
            ),
          ),

          // ================================================================
          // VIEW BUTTON
          // ================================================================

          if (onView != null)
            OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(58, 34),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                side: const BorderSide(
                  color: departmentBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}