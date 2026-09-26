import 'package:flutter/material.dart';

import '../models/department_employee_model.dart';

class DepartmentEmployeeItem extends StatelessWidget {
  final DepartmentEmployeeModel employee;
  final bool selected;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onView;

  const DepartmentEmployeeItem({
    super.key,
    required this.employee,
    this.selected = false,
    this.onChanged,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          if (onChanged != null)
            Checkbox(
              value: selected,
              onChanged: onChanged,
              activeColor: const Color(0xFFE96832),
            ),

          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFFFEEE7),
            child: Text(
              employee.name.isEmpty
                  ? '?'
                  : employee.name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFE96832),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18212F),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  employee.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Text(
            employee.employeeCode,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),

          if (onView != null) ...[
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(58, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View'),
            ),
          ],
        ],
      ),
    );
  }
}