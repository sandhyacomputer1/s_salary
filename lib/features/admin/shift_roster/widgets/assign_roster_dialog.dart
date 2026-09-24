import 'package:flutter/material.dart';

import '../../../../data/models/employee.dart';
import '../models/shift_model.dart';

// =================================================================
// ASSIGN ROSTER DIALOG
//
// Collects input only — it does NOT call any service. Returns:
//   {
//     'shiftId': String,
//     'startDate': DateTime,
//     'endDate': DateTime,
//     'employeeIds': List<String>,
//   }
// via Navigator.pop(), or null if cancelled. The screen is
// responsible for calling ShiftRosterService.assignRoster() once
// per selected employee.
// =================================================================

Future<Map<String, dynamic>?> showAssignRosterDialog(
    BuildContext context, {
      required List<ShiftModel> shifts,
      required List<Employee> employees,
    }) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AssignRosterDialog(
      shifts: shifts,
      employees: employees,
    ),
  );
}

class AssignRosterDialog extends StatefulWidget {
  final List<ShiftModel> shifts;
  final List<Employee> employees;

  const AssignRosterDialog({
    super.key,
    required this.shifts,
    required this.employees,
  });

  @override
  State<AssignRosterDialog> createState() => _AssignRosterDialogState();
}

class _AssignRosterDialogState extends State<AssignRosterDialog> {
  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFF1EB);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFD9DEE5);
  static const Color divider = Color(0xFFE9ECF0);
  static const Color errorColor = Color(0xFFD32F2F);

  final _searchController = TextEditingController();

  String? _selectedShiftId;
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedEmployeeIds = {};

  String? _validationError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Employee> get _filteredEmployees {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return widget.employees;

    return widget.employees.where((employee) {
      return employee.name.toLowerCase().contains(query) ||
          employee.employeeCode.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query);
    }).toList();
  }

  bool get _allFilteredSelected {
    final filtered = _filteredEmployees;
    if (filtered.isEmpty) return false;
    return filtered.every((employee) => _selectedEmployeeIds.contains(employee.id));
  }

  void _toggleSelectAll() {
    setState(() {
      if (_allFilteredSelected) {
        for (final employee in _filteredEmployees) {
          _selectedEmployeeIds.remove(employee.id);
        }
      } else {
        for (final employee in _filteredEmployees) {
          _selectedEmployeeIds.add(employee.id);
        }
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  String _dateText(DateTime? date) {
    if (date == null) return 'Select date';

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  void _submit() {
    setState(() {
      _validationError = null;
    });

    if (_selectedShiftId == null) {
      setState(() => _validationError = 'Please select a shift.');
      return;
    }

    if (_startDate == null) {
      setState(() => _validationError = 'Please select a start date.');
      return;
    }

    if (_endDate == null) {
      setState(() => _validationError = 'Please select an end date.');
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _validationError = 'End date cannot be before start date.');
      return;
    }

    if (_selectedEmployeeIds.isEmpty) {
      setState(() => _validationError = 'Please select at least one employee.');
      return;
    }

    Navigator.pop(context, {
      'shiftId': _selectedShiftId,
      'startDate': _startDate,
      'endDate': _endDate,
      'employeeIds': _selectedEmployeeIds.toList(),
    });
  }

  InputDecoration _decoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: textLight),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Assign Shift Roster Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Select Shift'),
                      DropdownButtonFormField<String>(
                        value: widget.shifts.any((s) => s.id == _selectedShiftId)
                            ? _selectedShiftId
                            : null,
                        isExpanded: true,
                        decoration: _decoration('Select a shift'),
                        items: widget.shifts.map((shift) {
                          return DropdownMenuItem<String>(
                            value: shift.id,
                            child: Text(
                              '${shift.name} (${shift.code})  ·  '
                                  '${shift.startTime}–${shift.endTime}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedShiftId = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Start Date'),
                                InkWell(
                                  onTap: () => _pickDate(isStart: true),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InputDecorator(
                                    decoration: _decoration(
                                      'dd-mm-yyyy',
                                      prefixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 17,
                                      ),
                                    ),
                                    child: Text(
                                      _dateText(_startDate),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: _startDate == null
                                            ? textLight
                                            : textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('End Date'),
                                InkWell(
                                  onTap: () => _pickDate(isStart: false),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InputDecorator(
                                    decoration: _decoration(
                                      'dd-mm-yyyy',
                                      prefixIcon: const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 17,
                                      ),
                                    ),
                                    child: Text(
                                      _dateText(_endDate),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: _endDate == null
                                            ? textLight
                                            : textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select Employees (${_selectedEmployeeIds.length} selected)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.employees.isEmpty
                                ? null
                                : _toggleSelectAll,
                            child: Text(
                              _allFilteredSelected
                                  ? 'Deselect All'
                                  : 'Select All Employees',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoration(
                          'Search employee or code...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 19),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        child: _filteredEmployees.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No employees found.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textLight,
                            ),
                          ),
                        )
                            : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _filteredEmployees.length,
                          separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: divider),
                          itemBuilder: (context, index) {
                            final employee = _filteredEmployees[index];
                            final selected =
                            _selectedEmployeeIds.contains(employee.id);

                            return CheckboxListTile(
                              value: selected,
                              dense: true,
                              activeColor: primary,
                              controlAffinity:
                              ListTileControlAffinity.leading,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedEmployeeIds.add(employee.id);
                                  } else {
                                    _selectedEmployeeIds.remove(employee.id);
                                  }
                                });
                              },
                              title: Text(
                                employee.name.trim().isEmpty
                                    ? 'Unnamed Employee'
                                    : employee.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                              subtitle: Text(
                                '(${employee.employeeCode})',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: textLight,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_validationError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _validationError!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: errorColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: textMedium),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Assign Roster Schedule'),
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