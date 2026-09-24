import 'package:flutter/material.dart';

import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import '../models/roster_schedule_model.dart';
import '../models/shift_model.dart';
import '../services/shift_roster_service.dart';
import '../widgets/assign_roster_dialog.dart';
import '../widgets/create_shift_dialog.dart';
import '../widgets/edit_shift_dialog.dart';
import '../widgets/roster_table.dart';
import '../widgets/shift_card.dart';

// =================================================================
// SHIFT ROSTER & PLANNER SCREEN
//
// Screen -> Service -> ApiClient -> Backend. This file never calls
// ApiClient directly — all network calls go through
// ShiftRosterService / EmployeeService.
// =================================================================

class ShiftRosterScreen extends StatefulWidget {
  const ShiftRosterScreen({super.key});

  @override
  State<ShiftRosterScreen> createState() => _ShiftRosterScreenState();
}

class _ShiftRosterScreenState extends State<ShiftRosterScreen> {
  // ==========================================================
  // STYLE
  // ==========================================================

  static const double _mobileBreakpoint = 700;

  static const Color _primary = Color(0xFFE96832);
  static const Color _primaryLight = Color(0xFFFFF1EB);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _textMedium = Color(0xFF4B5563);
  static const Color _textLight = Color(0xFF8A93A1);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _divider = Color(0xFFE9ECF0);
  static const Color _pageBg = Color(0xFFF7F8FA);

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  static const List<Color> _shiftPalette = [
    Color(0xFFE96832),
    Color(0xFF2878FF),
    Color(0xFF7A5AF8),
    Color(0xFF18864B),
    Color(0xFFE8A317),
    Color(0xFF0F766E),
  ];

  // ==========================================================
  // SERVICES
  // ==========================================================

  final ShiftRosterService _shiftRosterService = ShiftRosterService();
  final EmployeeService _employeeService = EmployeeService();

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  List<ShiftModel> _shifts = [];
  List<RosterScheduleModel> _rosterSchedules = [];
  List<Employee> _employees = [];

  static const String _allDepartments = 'All Departments';
  String _selectedDepartment = _allDepartments;

  final TextEditingController _searchController = TextEditingController();

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() => setState(() {}));

    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD
  // ==========================================================

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Shifts and Employees hit CONFIRMED endpoints (GET /shifts,
      // GET /employees) — if either of these fails, something is
      // genuinely wrong and the screen shows the error state.
      final results = await Future.wait([
        _shiftRosterService.getShifts(),
        _employeeService.getEmployees(status: 'active'),
      ]);

      if (!mounted) return;

      final shifts = results[0] as List<ShiftModel>;
      final employees = results[1] as List<Employee>;

      // Roster schedules use an UNCONFIRMED endpoint (see
      // ShiftRosterService.getRosterSchedules — no matching route
      // was found in your API docs). Load it separately so a 404
      // there just leaves the roster table empty instead of taking
      // down the shifts list too.
      List<RosterScheduleModel> rosterSchedules = [];

      try {
        rosterSchedules = await _shiftRosterService.getRosterSchedules();
      } catch (e) {
        debugPrint('ROSTER SCHEDULES LOAD FAILED (endpoint unconfirmed): $e');
      }

      if (!mounted) return;

      setState(() {
        _shifts = shifts;
        _employees = employees;
        _rosterSchedules = rosterSchedules;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _reloadShifts() async {
    final shifts = await _shiftRosterService.getShifts();
    if (!mounted) return;
    setState(() => _shifts = shifts);
  }

  /// Re-fetches roster schedules. Since the underlying endpoint is
  /// UNCONFIRMED (see ShiftRosterService.getRosterSchedules), a
  /// failure here just leaves the roster table as-is rather than
  /// throwing back into whatever action (assign / delete) triggered
  /// this refresh — that action should still be able to report its
  /// own success/failure independently.
  Future<void> _reloadRosterSchedules() async {
    try {
      final schedules = await _shiftRosterService.getRosterSchedules();
      if (!mounted) return;
      setState(() => _rosterSchedules = schedules);
    } catch (e) {
      debugPrint('ROSTER SCHEDULES REFRESH FAILED (endpoint unconfirmed): $e');
    }
  }

  // ==========================================================
  // DERIVED DATA
  // ==========================================================

  List<String> get _departmentOptions {
    final departments = _employees
        .map((employee) => employee.department.trim())
        .where((department) => department.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return [_allDepartments, ...departments];
  }

  List<RosterScheduleModel> get _filteredRosterSchedules {
    final query = _searchController.text.trim().toLowerCase();

    return _rosterSchedules.where((schedule) {
      final matchesDepartment = _selectedDepartment == _allDepartments ||
          (schedule.departmentName ?? '').toLowerCase() ==
              _selectedDepartment.toLowerCase();

      final matchesSearch = query.isEmpty ||
          (schedule.employeeName ?? '').toLowerCase().contains(query) ||
          (schedule.employeeCode ?? '').toLowerCase().contains(query) ||
          (schedule.employeeEmail ?? '').toLowerCase().contains(query);

      return matchesDepartment && matchesSearch;
    }).toList();
  }

  // ==========================================================
  // SHIFT ACTIONS
  // ==========================================================

  Future<void> _openCreateShiftDialog() async {
    final data = await showCreateShiftDialog(context);
    if (data == null) return;

    setState(() => _isSaving = true);

    try {
      await _shiftRosterService.createShift(data);
      await _reloadShifts();
      _showMessage('Shift created successfully.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openEditShiftDialog(ShiftModel shift) async {
    final data = await showEditShiftDialog(context, shift);
    if (data == null) return;

    setState(() => _isSaving = true);

    try {
      await _shiftRosterService.updateShift(shift.id, data);
      await _reloadShifts();
      _showMessage('Shift updated successfully.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDeleteShift(ShiftModel shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            'Delete Shift?',
            style: TextStyle(fontWeight: FontWeight.w700, color: _textDark),
          ),
          content: const Text(
            'Are you sure you want to delete this shift? Existing roster '
                'schedules using this shift may be affected.',
            style: TextStyle(fontSize: 13.5, color: _textMedium),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: _textMedium),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _shiftRosterService.deleteShift(shift.id);
      await _reloadShifts();
      _showMessage('Shift deleted.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ==========================================================
  // ROSTER ACTIONS
  // ==========================================================

  Future<void> _openAssignRosterDialog() async {
    if (_shifts.isEmpty) {
      _showMessage('Create a shift before assigning a roster schedule.');
      return;
    }

    final result = await showAssignRosterDialog(
      context,
      shifts: _shifts,
      employees: _employees,
    );

    if (result == null) return;

    final shiftId = result['shiftId'] as String;
    final startDate = result['startDate'] as DateTime;
    final endDate = result['endDate'] as DateTime;
    final employeeIds = List<String>.from(result['employeeIds'] as List);

    setState(() => _isSaving = true);

    var successCount = 0;
    var failureCount = 0;

    for (final employeeId in employeeIds) {
      try {
        await _shiftRosterService.assignRoster({
          'employeeId': employeeId,
          'shiftId': shiftId,
          'startDate': startDate.toIso8601String().split('T').first,
          'endDate': endDate.toIso8601String().split('T').first,
        });
        successCount++;
      } catch (_) {
        failureCount++;
      }
    }

    await _reloadRosterSchedules();

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (failureCount == 0) {
      _showMessage(
        'Roster schedule assigned to $successCount employee'
            '${successCount == 1 ? '' : 's'}.',
      );
    } else {
      _showMessage(
        'Assigned to $successCount employee(s); $failureCount failed.',
      );
    }
  }

  Future<void> _confirmDeleteRosterSchedule(RosterScheduleModel schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text(
            'Remove Roster Schedule?',
            style: TextStyle(fontWeight: FontWeight.w700, color: _textDark),
          ),
          content: Text(
            'Remove this schedule for '
                '${schedule.employeeName ?? 'this employee'}?',
            style: const TextStyle(fontSize: 13.5, color: _textMedium),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: _textMedium),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await _shiftRosterService.deleteRosterSchedule(schedule.id);
      await _reloadRosterSchedules();
      _showMessage('Roster schedule removed.');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323A46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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
                child: CircularProgressIndicator(color: _primary),
              )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                color: _primary,
                onRefresh: _loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 14 : 24,
                    mobile ? 16 : 22,
                    mobile ? 14 : 24,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(mobile),
                      SizedBox(height: mobile ? 18 : 24),
                      _buildShiftsSection(mobile),
                      SizedBox(height: mobile ? 20 : 28),
                      _buildRosterSection(mobile),
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

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget _buildTopBar(bool mobile) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: mobile ? 6 : 16),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: (_isSaving || _isDeleting)
                  ? null
                  : () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 21, color: _textDark),
            ),
            const SizedBox(width: 2),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.schedule_outlined,
                color: _primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Shift Roster & Planner',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ),
            if ((_isSaving || _isDeleting))
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PAGE HEADER
  // ==========================================================

  Widget _buildPageHeader(bool mobile) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rotational Shift & Roster Planner',
          style: TextStyle(
            fontSize: mobile ? 20 : 25,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Configure morning, general, flexi, and overnight night shifts '
              'with grace times and assigned employee rosters.',
          style: TextStyle(fontSize: 13, color: _textLight),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _openCreateShiftDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Create Shift'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _textDark,
            side: const BorderSide(color: Color(0xFFD9DEE7)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _openAssignRosterDialog,
          icon: const Icon(Icons.event_available_outlined, size: 18),
          label: const Text('Assign Shift Roster'),
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleBlock, const SizedBox(height: 14), actions],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        actions,
      ],
    );
  }

  // ==========================================================
  // SHIFTS SECTION
  // ==========================================================

  Widget _buildShiftsSection(bool mobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configured Shifts',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_shifts.length} shift${_shifts.length == 1 ? '' : 's'} configured',
              style: const TextStyle(fontSize: 12, color: _textLight),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: _divider),
            const SizedBox(height: 16),
            if (_shifts.isEmpty)
              _buildEmptyShiftsState()
            else
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: _shifts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final shift = entry.value;

                  return ShiftCard(
                    shift: shift,
                    accentColor: _shiftPalette[index % _shiftPalette.length],
                    onEdit: () => _openEditShiftDialog(shift),
                    onDelete: () => _confirmDeleteShift(shift),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyShiftsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.schedule_outlined,
              size: 28,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No shifts configured yet',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your first shift to start building the roster.',
            style: TextStyle(fontSize: 12.5, color: _textLight),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openCreateShiftDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Shift'),
            style: FilledButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ROSTER SECTION
  // ==========================================================

  Widget _buildRosterSection(bool mobile) {
    final filtered = _filteredRosterSchedules;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Employee Roster Schedules',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${filtered.length} schedule${filtered.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: _textLight),
            ),
            const SizedBox(height: 14),
            _buildRosterFilters(mobile),
            const SizedBox(height: 14),
            const Divider(height: 1, color: _divider),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              _buildEmptyRosterState()
            else
              RosterTable(
                schedules: filtered,
                onDelete: _confirmDeleteRosterSchedule,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterFilters(bool mobile) {
    final departmentDropdown = DropdownButtonFormField<String>(
      value: _departmentOptions.contains(_selectedDepartment)
          ? _selectedDepartment
          : _allDepartments,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.account_tree_outlined, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
      items: _departmentOptions.map((department) {
        return DropdownMenuItem<String>(
          value: department,
          child: Text(department, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedDepartment = value);
      },
    );

    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search employee or code...',
        hintStyle: const TextStyle(fontSize: 13.5, color: _textLight),
        prefixIcon: const Icon(Icons.search_rounded, size: 19),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.close_rounded, size: 18),
          onPressed: () => _searchController.clear(),
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD9DEE5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
    );

    if (mobile) {
      return Column(
        children: [
          departmentDropdown,
          const SizedBox(height: 10),
          searchField,
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 220, child: departmentDropdown),
        const SizedBox(width: 12),
        Expanded(child: searchField),
      ],
    );
  }

  Widget _buildEmptyRosterState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              size: 28,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No roster schedules found',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Assign a shift roster to see it listed here.',
            style: TextStyle(fontSize: 12.5, color: _textLight),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR STATE
  // ==========================================================

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load shift roster',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textMedium),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(backgroundColor: _primary),
            ),
          ],
        ),
      ),
    );
  }
}