import 'package:flutter/material.dart';

import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import '../../employees/screens/employee_details_screen.dart';

import '../models/department_model.dart';
import '../services/department_service.dart';

import '../widgets/create_department_dialog.dart';
import '../widgets/department_card.dart';
import '../widgets/edit_department_dialog.dart';
import '../widgets/move_employees_dialog.dart';

// ============================================================================
// DEPARTMENT MANAGEMENT SCREEN
//
// Department API:
//   GET /departments
//
// Employee API:
//   GET /employees?status=active
//
// IMPORTANT:
// Employees are NOT loaded from:
//
//   /departments/:id/employees
//
// Instead, employees come from the existing Employee API.
//
// Example:
//
// Employee:
//   department: "Accounts"
//
// Department:
//   name: "Accounts"
//
// Therefore the employee is displayed inside Accounts.
// ============================================================================

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  // ==========================================================================
  // COLORS
  // ==========================================================================

  static const double _mobileBreakpoint = 700;
  static const double _tabletBreakpoint = 1050;

  static const Color _primary = Color(0xFFE96832);
  static const Color _primaryLight = Color(0xFFFFF1EB);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _textMedium = Color(0xFF4B5563);
  static const Color _textLight = Color(0xFF8A93A1);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);

  bool get _isMobile =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  // ==========================================================================
  // SERVICES
  // ==========================================================================

  final DepartmentService _departmentService = DepartmentService();
  final EmployeeService _employeeService = EmployeeService();

  // ==========================================================================
  // STATE
  // ==========================================================================

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  String? _errorMessage;

  List<DepartmentModel> _departments = [];

  /// Employees come directly from Employee API.
  List<Employee> _employees = [];

  /// Department IDs whose staff list is currently visible.
  final Set<String> _expandedDepartmentIds = {};

  final TextEditingController _searchController =
  TextEditingController();

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    _loadAll();
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
  // LOAD DEPARTMENTS + EMPLOYEES
  // ==========================================================================

  Future<void> _loadAll() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _departmentService.getDepartments(),
        _employeeService.getEmployees(
          status: 'active',
        ),
      ]);

      if (!mounted) return;

      final departments =
      results[0] as List<DepartmentModel>;

      final employees =
      results[1] as List<Employee>;

      debugPrint('========================================');
      debugPrint('DEPARTMENT API');
      debugPrint('Departments: ${departments.length}');
      debugPrint('========================================');

      debugPrint('EMPLOYEE API');
      debugPrint('Employees: ${employees.length}');

      for (final employee in employees) {
        debugPrint(
          '${employee.name} | '
              '${employee.employeeCode} | '
              'Department: ${employee.department}',
        );
      }

      debugPrint('========================================');

      setState(() {
        _departments = departments;
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  // ==========================================================================
  // RELOAD DEPARTMENTS
  // ==========================================================================

  Future<void> _reloadDepartments() async {
    final departments =
    await _departmentService.getDepartments();

    if (!mounted) return;

    setState(() {
      _departments = departments;
    });
  }

  // ==========================================================================
  // RELOAD EMPLOYEES
  // ==========================================================================

  Future<void> _reloadEmployees() async {
    final employees =
    await _employeeService.getEmployees(
      status: 'active',
    );

    if (!mounted) return;

    setState(() {
      _employees = employees;
    });
  }

  // ==========================================================================
  // FILTERED DEPARTMENTS
  // ==========================================================================

  List<DepartmentModel> get _filteredDepartments {
    final query =
    _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _departments;
    }

    return _departments.where((department) {
      return department.name
          .toLowerCase()
          .contains(query) ||
          department.code
              .toLowerCase()
              .contains(query) ||
          department.description
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  // ==========================================================================
  // GET STAFF FOR DEPARTMENT
  //
  // THIS IS THE IMPORTANT PART.
  //
  // Employee API:
  //
  // {
  //   "employee": {
  //     "department": "Accounts"
  //   }
  // }
  //
  // Department API:
  //
  // {
  //   "name": "Accounts"
  // }
  //
  // We compare these two values.
  // ==========================================================================

  List<Employee> _staffFor(
      DepartmentModel department,
      ) {
    final departmentName =
    department.name.trim().toLowerCase();

    final Map<String, Employee> uniqueEmployees = {};

    for (final employee in _employees) {
      final employeeDepartment =
      employee.department.trim().toLowerCase();

      if (employeeDepartment == departmentName) {
        uniqueEmployees[employee.id] = employee;
      }
    }

    return uniqueEmployees.values.toList();
  }

  // ==========================================================================
  // ERROR HANDLER
  // ==========================================================================

  String _friendlyError(Object error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '');

    if (message.contains('401')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (message.contains('403')) {
      return "Access denied. You don't have permission.";
    }

    if (message.contains('404')) {
      return 'Unable to load department or employee data.';
    }

    if (message.contains('422')) {
      return message;
    }

    if (message.contains('500')) {
      return 'Server error. Please try again.';
    }

    return message;
  }

  // ==========================================================================
  // CREATE DEPARTMENT
  // ==========================================================================

  Future<void> _openCreateDialog() async {
    final data =
    await showCreateDepartmentDialog(context);

    if (data == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _departmentService.createDepartment(data);

      await _reloadDepartments();

      if (!mounted) return;

      _showMessage(
        'Department created successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to create department: '
            '${_friendlyError(e)}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ==========================================================================
  // EDIT DEPARTMENT
  // ==========================================================================

  Future<void> _openEditDialog(
      DepartmentModel department,
      ) async {
    final data =
    await showEditDepartmentDialog(
      context,
      department,
    );

    if (data == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _departmentService.updateDepartment(
        department.id,
        data,
      );

      await _reloadDepartments();

      if (!mounted) return;

      _showMessage(
        'Department updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to update department: '
            '${_friendlyError(e)}',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ==========================================================================
  // DELETE DEPARTMENT
  // ==========================================================================

  Future<void> _confirmDelete(
      DepartmentModel department,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Delete Department?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          content: Text(
            'Are you sure you want to delete '
                'the ${department.name} department?',
            style: const TextStyle(
              fontSize: 13.5,
              color: _textMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: _textMedium,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _departmentService.deleteDepartment(
        department.id,
      );

      await _reloadDepartments();

      if (!mounted) return;

      _expandedDepartmentIds.remove(
        department.id,
      );

      _showMessage(
        'Department deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _friendlyError(e),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ==========================================================================
  // VIEW / HIDE STAFF
  //
  // NO API CALL HERE.
  //
  // Employees were already loaded from Employee API in _loadAll().
  // ==========================================================================

  void _toggleStaff(
      String departmentId,
      ) {
    setState(() {
      if (_expandedDepartmentIds.contains(
        departmentId,
      )) {
        _expandedDepartmentIds.remove(
          departmentId,
        );
      } else {
        _expandedDepartmentIds.add(
          departmentId,
        );
      }
    });
  }

  // ==========================================================================
  // MOVE EMPLOYEES
  // ==========================================================================

  Future<void> _openMoveDialog(
      DepartmentModel currentDepartment,
      ) async {
    if (_departments.isEmpty) return;

    final result =
    await showMoveEmployeesDialog(
      context,
      departments: _departments,
      employees: _employees,
      initialTargetDepartment:
      currentDepartment.name,
    );

    if (result == null) return;

    final targetDepartment =
    result['targetDepartment']?.toString();

    final employeeIdsRaw =
    result['employeeIds'];

    if (targetDepartment == null ||
        targetDepartment.trim().isEmpty) {
      _showMessage(
        'Please select a target department.',
        error: true,
      );
      return;
    }

    if (employeeIdsRaw is! List) {
      _showMessage(
        'Invalid employee selection.',
        error: true,
      );
      return;
    }

    final employeeIds =
    employeeIdsRaw
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty)
        .toList();

    if (employeeIds.isEmpty) {
      _showMessage(
        'Please select at least one employee.',
        error: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    int successCount = 0;
    String? firstErrorMessage;

    for (final employeeId in employeeIds) {
      try {
        await _employeeService.updateEmployee(
          employeeId: employeeId,
          data: {
            'department': targetDepartment,
          },
        );

        successCount++;
      } catch (e) {
        debugPrint(
          'MOVE EMPLOYEE FAILED: '
              '$employeeId -> $e',
        );

        firstErrorMessage ??=
            _friendlyError(e);
      }
    }

    try {
      await Future.wait([
        _reloadDepartments(),
        _reloadEmployees(),
      ]);
    } catch (e) {
      debugPrint(
        'RELOAD AFTER MOVE ERROR: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _expandedDepartmentIds.clear();
    });

    if (successCount == employeeIds.length) {
      _showMessage(
        'Moved $successCount employee'
            '${successCount == 1 ? '' : 's'} '
            'to $targetDepartment.',
      );
    } else if (successCount == 0) {
      _showMessage(
        'Failed to move employees: '
            '${firstErrorMessage ?? 'Unknown error'}',
        error: true,
      );
    } else {
      _showMessage(
        'Moved $successCount of '
            '${employeeIds.length} employees.',
        error: true,
      );
    }
  }

  // ==========================================================================
  // VIEW EMPLOYEE
  // ==========================================================================

  Future<void> _viewEmployee(
      Employee employee,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmployeeDetailsScreen(
              employee: employee,
            ),
      ),
    );

    // Refresh because employee department/status
    // may have changed inside details.
    await _reloadEmployees();
    await _reloadDepartments();
  }

  // ==========================================================================
  // MESSAGE
  // ==========================================================================

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor: error
            ? const Color(0xFFC62828)
            : const Color(0xFF323A46),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(mobile),

            Expanded(
              child: _isLoading
                  ? const Center(
                child:
                CircularProgressIndicator(
                  color: _primary,
                ),
              )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                color: _primary,
                onRefresh: _loadAll,
                child:
                SingleChildScrollView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding:
                  EdgeInsets.fromLTRB(
                    mobile ? 14 : 24,
                    mobile ? 16 : 22,
                    mobile ? 14 : 24,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(
                        mobile,
                      ),
                      SizedBox(
                        height:
                        mobile ? 18 : 24,
                      ),
                      _buildDepartmentsGrid(
                        mobile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TOP BAR
  // ==========================================================================

  Widget _buildTopBar(bool mobile) {
    final busy =
        _isSaving || _isDeleting;

    return Container(
      width: double.infinity,
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom:
          BorderSide(color: _border),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? 6 : 16,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: busy
                  ? null
                  : () =>
                  Navigator.maybePop(
                    context,
                  ),
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 21,
                color: _textDark,
              ),
            ),

            const SizedBox(width: 2),

            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_tree_outlined,
                color: _primary,
                size: 19,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Text(
                'Departments',
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ),

            if (busy)
              const Padding(
                padding:
                EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // PAGE HEADER
  // ==========================================================================

  Widget _buildPageHeader(bool mobile) {
    final titleBlock = Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          'Company Departments',
          style: TextStyle(
            fontSize: mobile ? 20 : 25,
            fontWeight:
            FontWeight.w700,
            color: _textDark,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Organize organizational structure '
              'and assign employees to departments.',
          style: TextStyle(
            fontSize: 13,
            color: _textLight,
          ),
        ),
      ],
    );

    final searchField = SizedBox(
      width: mobile ? double.infinity : 260,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          isDense: true,
          hintText:
          'Search departments...',
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: _textLight,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 19,
          ),
          suffixIcon:
          _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
            ),
            onPressed: () =>
                _searchController
                    .clear(),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(8),
            borderSide:
            const BorderSide(
              color: Color(0xFFD9DEE5),
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(8),
            borderSide:
            const BorderSide(
              color: Color(0xFFD9DEE5),
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(8),
            borderSide:
            const BorderSide(
              color: _primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );

    final createButton =
    FilledButton.icon(
      onPressed:
      _isSaving ? null : _openCreateDialog,
      icon: const Icon(
        Icons.add_rounded,
        size: 18,
      ),
      label:
      const Text('Create Department'),
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(8),
        ),
      ),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 14),
          searchField,
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: createButton,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: titleBlock,
        ),
        const SizedBox(width: 16),
        searchField,
        const SizedBox(width: 10),
        createButton,
      ],
    );
  }

  // ==========================================================================
  // DEPARTMENT GRID
  // ==========================================================================

  Widget _buildDepartmentsGrid(
      bool mobile,
      ) {
    final departments =
        _filteredDepartments;

    if (departments.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth;

        int columns;

        if (width >=
            _tabletBreakpoint) {
          columns = 3;
        } else if (width >=
            _mobileBreakpoint) {
          columns = 2;
        } else {
          columns = 1;
        }

        const gap = 16.0;

        final cardWidth =
            (width -
                gap * (columns - 1)) /
                columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
          departments.map((department) {
            final staff =
            _staffFor(department);

            return SizedBox(
              width: cardWidth,
              child: DepartmentCard(
                department: department,

                isExpanded:
                _expandedDepartmentIds
                    .contains(
                  department.id,
                ),

                employees: staff,

                onViewStaff: () =>
                    _toggleStaff(
                      department.id,
                    ),

                onMove: () =>
                    _openMoveDialog(
                      department,
                    ),

                onEdit: () =>
                    _openEditDialog(
                      department,
                    ),

                onDelete: () =>
                    _confirmDelete(
                      department,
                    ),

                onViewEmployee:
                _viewEmployee,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ==========================================================================
  // EMPTY STATE
  // ==========================================================================

  Widget _buildEmptyState() {
    final hasQuery =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border:
        Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color:
              const Color(0xFFF1F5F9),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Icon(
              hasQuery
                  ? Icons.search_off_rounded
                  : Icons
                  .account_tree_outlined,
              size: 28,
              color:
              const Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            hasQuery
                ? 'No departments found'
                : 'No departments yet',
            style:
            const TextStyle(
              fontSize: 14.5,
              fontWeight:
              FontWeight.w700,
              color: _textDark,
            ),
          ),

          if (!hasQuery) ...[
            const SizedBox(height: 6),

            const Text(
              'Create your first department '
                  'to get started.',
              style: TextStyle(
                fontSize: 12.5,
                color: _textLight,
              ),
            ),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed:
              _openCreateDialog,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text(
                'Create Department',
              ),
              style:
              FilledButton.styleFrom(
                backgroundColor:
                _primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // ERROR STATE
  // ==========================================================================

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 500,
        ),
        margin:
        const EdgeInsets.all(24),
        padding:
        const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          border:
          Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.red,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load data',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w700,
                color: _textDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 13,
                color: _textMedium,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _loadAll,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
              const Text('Try Again'),
              style:
              FilledButton.styleFrom(
                backgroundColor:
                _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}