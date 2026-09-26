import 'package:flutter/material.dart';

import '../../../../data/models/employee.dart';
import '../models/department_model.dart';

// ============================================================================
// MOVE EMPLOYEES DIALOG
//
// Returns:
//
// {
//   'targetDepartment': 'Engineering',
//   'employeeIds': [
//     'employeeId1',
//     'employeeId2',
//   ]
// }
//
// The actual API update is handled by DepartmentScreen using:
//
// EmployeeService.updateEmployee(
//   employeeId: employeeId,
//   data: {
//     'department': targetDepartment,
//   },
// )
//
// ============================================================================

Future<Map<String, dynamic>?> showMoveEmployeesDialog(
    BuildContext context, {
      required List<DepartmentModel> departments,
      required List<Employee> employees,
      required String initialTargetDepartment,
    }) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return MoveEmployeesDialog(
        departments: departments,
        employees: employees,
        initialTargetDepartment:
        initialTargetDepartment,
      );
    },
  );
}

// ============================================================================
// DIALOG
// ============================================================================

class MoveEmployeesDialog
    extends StatefulWidget {
  final List<DepartmentModel> departments;

  final List<Employee> employees;

  final String initialTargetDepartment;

  const MoveEmployeesDialog({
    super.key,
    required this.departments,
    required this.employees,
    required this.initialTargetDepartment,
  });

  @override
  State<MoveEmployeesDialog> createState() =>
      _MoveEmployeesDialogState();
}

// ============================================================================
// STATE
// ============================================================================

class _MoveEmployeesDialogState
    extends State<MoveEmployeesDialog> {
  static const Color primary =
  Color(0xFFE96832);

  static const Color textDark =
  Color(0xFF18212F);

  static const Color textMedium =
  Color(0xFF4B5563);

  static const Color textLight =
  Color(0xFF8A93A1);

  static const Color border =
  Color(0xFFD9DEE5);

  static const Color divider =
  Color(0xFFE9ECF0);

  static const Color errorColor =
  Color(0xFFD32F2F);

  final TextEditingController
  _searchController =
  TextEditingController();

  late String _targetDepartment;

  final Set<String>
  _selectedEmployeeIds = {};

  String? _validationError;

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _targetDepartment =
        widget.initialTargetDepartment;
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // FILTER
  // ==========================================================================

  List<Employee> get _filteredEmployees {
    final query =
    _searchController.text
        .trim()
        .toLowerCase();

    if (query.isEmpty) {
      return widget.employees;
    }

    return widget.employees.where(
          (employee) {
        return employee.name
            .toLowerCase()
            .contains(query) ||
            employee.employeeCode
                .toLowerCase()
                .contains(query) ||
            employee.email
                .toLowerCase()
                .contains(query) ||
            employee.department
                .toLowerCase()
                .contains(query);
      },
    ).toList();
  }

  // ==========================================================================
  // CHECK TARGET
  // ==========================================================================

  bool _isAlreadyInTarget(
      Employee employee,
      ) {
    return employee.department
        .trim()
        .toLowerCase() ==
        _targetDepartment
            .trim()
            .toLowerCase();
  }

  // ==========================================================================
  // SUBMIT
  // ==========================================================================

  void _submit() {
    setState(() {
      _validationError = null;
    });

    if (_targetDepartment
        .trim()
        .isEmpty) {
      setState(() {
        _validationError =
        'Please select a target department.';
      });
      return;
    }

    if (_selectedEmployeeIds.isEmpty) {
      setState(() {
        _validationError =
        'Select at least one employee to move.';
      });
      return;
    }

    Navigator.pop(
      context,
      {
        'targetDepartment':
        _targetDepartment,
        'employeeIds':
        _selectedEmployeeIds.toList(),
      },
    );
  }

  // ==========================================================================
  // INPUT DECORATION
  // ==========================================================================

  InputDecoration _decoration(
      String hint, {
        Widget? prefixIcon,
      }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle:
      const TextStyle(
        fontSize: 13.5,
        color: textLight,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(8),
        borderSide:
        const BorderSide(
          color: border,
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(8),
        borderSide:
        const BorderSide(
          color: border,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(8),
        borderSide:
        const BorderSide(
          color: primary,
          width: 1.4,
        ),
      ),
    );
  }

  // ==========================================================================
  // LABEL
  // ==========================================================================

  Widget _label(
      String text, {
        bool required = false,
      }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 6,
      ),
      child: RichText(
        text: TextSpan(
          text: text,
          style:
          const TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.w600,
            color: textDark,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style:
                TextStyle(
                  color: errorColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Dialog(
      backgroundColor: Colors.white,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: ConstrainedBox(
        constraints:
        const BoxConstraints(
          maxWidth: 620,
          maxHeight: 680,
        ),
        child: Padding(
          padding:
          const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Move Employees to Department',
                style:
                TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w700,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child:
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      // ======================================================
                      // TARGET DEPARTMENT
                      // ======================================================

                      _label(
                        'Target Department',
                        required: true,
                      ),

                      DropdownButtonFormField<
                          String>(
                        value: widget.departments
                            .any(
                              (department) =>
                          department.name ==
                              _targetDepartment,
                        )
                            ? _targetDepartment
                            : null,
                        isExpanded: true,
                        decoration:
                        _decoration(
                          'Select a department',
                        ),
                        items: widget
                            .departments
                            .map(
                              (department) {
                            return DropdownMenuItem<
                                String>(
                              value:
                              department
                                  .name,
                              child: Text(
                                '${department.name} '
                                    '(${department.code})',
                                overflow:
                                TextOverflow
                                    .ellipsis,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setState(() {
                            _targetDepartment =
                                value;

                            // Remove employees
                            // that became invalid
                            // because target changed.
                            _selectedEmployeeIds
                                .removeWhere(
                                  (id) {
                                final employee =
                                    widget
                                        .employees
                                        .where(
                                          (e) =>
                                      e.id ==
                                          id,
                                    )
                                        .firstOrNull;

                                if (employee ==
                                    null) {
                                  return true;
                                }

                                return _isAlreadyInTarget(
                                  employee,
                                );
                              },
                            );
                          });
                        },
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ======================================================
                      // EMPLOYEE TITLE
                      // ======================================================

                      Text(
                        'Select Employees '
                            '(${_selectedEmployeeIds.length} selected)',
                        style:
                        const TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w700,
                          color: textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ======================================================
                      // SEARCH
                      // ======================================================

                      TextField(
                        controller:
                        _searchController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration:
                        _decoration(
                          'Search employee...',
                          prefixIcon:
                          const Icon(
                            Icons
                                .search_rounded,
                            size: 19,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ======================================================
                      // EMPLOYEE LIST
                      // ======================================================

                      Container(
                        constraints:
                        const BoxConstraints(
                          maxHeight: 300,
                        ),
                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius
                              .circular(8),
                          border:
                          Border.all(
                            color: border,
                          ),
                        ),
                        child:
                        _filteredEmployees
                            .isEmpty
                            ? const Padding(
                          padding:
                          EdgeInsets.all(
                            20,
                          ),
                          child:
                          Text(
                            'No employees found.',
                            style:
                            TextStyle(
                              fontSize:
                              13,
                              color:
                              textLight,
                            ),
                          ),
                        )
                            : ListView
                            .separated(
                          shrinkWrap:
                          true,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical:
                            4,
                          ),
                          itemCount:
                          _filteredEmployees
                              .length,
                          separatorBuilder:
                              (_, __) =>
                          const Divider(
                            height:
                            1,
                            color:
                            divider,
                          ),
                          itemBuilder:
                              (
                              context,
                              index,
                              ) {
                            final employee =
                            _filteredEmployees[
                            index];

                            final alreadyThere =
                            _isAlreadyInTarget(
                              employee,
                            );

                            final selected =
                            _selectedEmployeeIds
                                .contains(
                              employee.id,
                            );

                            return InkWell(
                              onTap:
                              alreadyThere
                                  ? null
                                  : () {
                                setState(
                                      () {
                                    if (selected) {
                                      _selectedEmployeeIds
                                          .remove(
                                        employee.id,
                                      );
                                    } else {
                                      _selectedEmployeeIds
                                          .add(
                                        employee.id,
                                      );
                                    }
                                  },
                                );
                              },
                              child:
                              Padding(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  6,
                                  vertical:
                                  8,
                                ),
                                child:
                                Row(
                                  children: [
                                    Checkbox(
                                      value:
                                      selected,
                                      activeColor:
                                      primary,
                                      onChanged:
                                      alreadyThere
                                          ? null
                                          : (value) {
                                        setState(
                                              () {
                                            if (value ==
                                                true) {
                                              _selectedEmployeeIds
                                                  .add(
                                                employee.id,
                                              );
                                            } else {
                                              _selectedEmployeeIds
                                                  .remove(
                                                employee.id,
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),

                                    Expanded(
                                      child:
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            employee.name.trim().isEmpty
                                                ? 'Unnamed Employee'
                                                : employee.name,
                                            maxLines:
                                            1,
                                            overflow:
                                            TextOverflow.ellipsis,
                                            style:
                                            TextStyle(
                                              fontSize:
                                              13,
                                              fontWeight:
                                              FontWeight.w600,
                                              color:
                                              alreadyThere
                                                  ? textLight
                                                  : textDark,
                                            ),
                                          ),

                                          const SizedBox(
                                            height:
                                            3,
                                          ),

                                          Text(
                                            '${employee.employeeCode} • '
                                                '${employee.department.isEmpty ? 'No Department' : employee.department}',
                                            maxLines:
                                            1,
                                            overflow:
                                            TextOverflow.ellipsis,
                                            style:
                                            const TextStyle(
                                              fontSize:
                                              11.5,
                                              color:
                                              textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (alreadyThere)
                                      const Text(
                                        'Current',
                                        style:
                                        TextStyle(
                                          fontSize:
                                          11,
                                          fontWeight:
                                          FontWeight.w700,
                                          color:
                                          primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      if (_validationError !=
                          null) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          _validationError!,
                          style:
                          const TextStyle(
                            fontSize: 12.5,
                            color:
                            errorColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==============================================================
              // BUTTONS
              // ==============================================================

              Row(
                mainAxisAlignment:
                MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(
                          context,
                        ),
                    style:
                    TextButton.styleFrom(
                      foregroundColor:
                      textMedium,
                    ),
                    child:
                    const Text(
                      'Cancel',
                    ),
                  ),

                  const SizedBox(width: 8),

                  FilledButton(
                    onPressed: _submit,
                    style:
                    FilledButton.styleFrom(
                      backgroundColor:
                      primary,
                      foregroundColor:
                      Colors.white,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          8,
                        ),
                      ),
                    ),
                    child: Text(
                      'Move '
                          '${_selectedEmployeeIds.length} '
                          'Employee'
                          '${_selectedEmployeeIds.length == 1 ? '' : 's'}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}