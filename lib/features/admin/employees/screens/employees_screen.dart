import 'package:flutter/material.dart';
import 'employee_details_screen.dart';
import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
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
  static const Color _pageBg = Color(0xFFF7F8FA);

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  // ==========================================================
  // SERVICES / CONTROLLERS
  // ==========================================================

  final EmployeeService _employeeService = EmployeeService();

  final TextEditingController _searchController = TextEditingController();

  // ==========================================================
  // DATA
  // ==========================================================

  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedDepartment = 'All';

  // ==========================================================
  // INIT / DISPOSE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_applyFilters);

    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD
  // ==========================================================

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employees = await _employeeService.getEmployees(
        status: 'active',
      );

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================================
  // FILTERS
  // ==========================================================

  void _applyFilters() {
    final searchText = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredEmployees = _employees.where((employee) {
        final matchesSearch = searchText.isEmpty ||
            employee.name.toLowerCase().contains(searchText) ||
            employee.email.toLowerCase().contains(searchText) ||
            employee.employeeCode.toLowerCase().contains(searchText) ||
            employee.designation.toLowerCase().contains(searchText) ||
            employee.department.toLowerCase().contains(searchText);

        final matchesDepartment = _selectedDepartment == 'All' ||
            employee.department.toLowerCase() ==
                _selectedDepartment.toLowerCase();

        return matchesSearch && matchesDepartment;
      }).toList();
    });
  }

  List<String> get _departments {
    final departments = _employees
        .map((employee) => employee.department.trim())
        .where((department) => department.isNotEmpty)
        .toSet()
        .toList();

    departments.sort();

    return ['All', ...departments];
  }

  bool get _hasActiveFilter =>
      _searchController.text.isNotEmpty || _selectedDepartment != 'All';

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _selectedDepartment = 'All';
    });

    _applyFilters();
  }

  // ==========================================================
  // FILTER SHEET
  // ==========================================================

  Future<void> _openFilterSheet() async {
    final departments = _departments;

    String temp = _departments.contains(_selectedDepartment)
        ? _selectedDepartment
        : 'All';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------------------------------
                    // GRAB HANDLE
                    // ------------------------------------------

                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9DEE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------
                    // TITLE
                    // ------------------------------------------

                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _primaryLight,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 19,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Filter Employees',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: _textMedium,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    const Divider(height: 1, color: _border),

                    const SizedBox(height: 16),

                    // ------------------------------------------
                    // DEPARTMENT
                    // ------------------------------------------

                    const Text(
                      'DEPARTMENT',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: _textLight,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: departments.map((department) {
                            final selected = temp == department;

                            return ChoiceChip(
                              label: Text(department),
                              selected: selected,
                              showCheckmark: false,
                              backgroundColor: Colors.white,
                              selectedColor: _primaryLight,
                              side: BorderSide(
                                color: selected ? _primary : _border,
                                width: selected ? 1.4 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              labelStyle: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: selected ? _primary : _textMedium,
                              ),
                              onSelected: (_) {
                                setSheetState(() {
                                  temp = department;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ------------------------------------------
                    // ACTIONS
                    // ------------------------------------------

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                temp = 'All';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textDark,
                              side: const BorderSide(color: _border),
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _selectedDepartment = temp;
                              });

                              _applyFilters();

                              Navigator.pop(sheetContext);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Apply Filter',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // OPEN DETAILS
  // ==========================================================

  Future<void> _openEmployee(Employee employee) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return EmployeeDetailsScreen(
            employee: employee,
          );
        },
      ),
    );

    if (result == true) {
      _loadEmployees();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  // ==========================================================
  // APP BAR
  // ==========================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 0,
      iconTheme: const IconThemeData(color: _textDark),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: _border),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 19,
              color: _primary,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Employees',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _loadEmployees,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ==========================================================
  // BODY  (page scrolls, content uses the full width)
  // ==========================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final mobile = _isMobile;

    return RefreshIndicator(
      color: _primary,
      onRefresh: _loadEmployees,
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
            SizedBox(height: mobile ? 14 : 20),
            _buildSearchRow(),
            if (_selectedDepartment != 'All') ...[
              const SizedBox(height: 12),
              _buildActiveFilterChips(),
            ],
            SizedBox(height: mobile ? 14 : 18),
            _buildResultsSection(mobile),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PAGE HEADER
  // ==========================================================

  Widget _buildPageHeader(bool mobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Employee Directory',
                style: TextStyle(
                  fontSize: mobile ? 22 : 27,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Search, filter and manage your active workforce.',
                style: TextStyle(
                  fontSize: mobile ? 13 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.groups_2_outlined,
                size: 17,
                color: _primary,
              ),
              const SizedBox(width: 7),
              Text(
                '${_employees.length} Active',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SEARCH + FILTER ICON
  // ==========================================================

  Widget _buildSearchRow() {
    final filterActive = _selectedDepartment != 'All';

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              fontSize: 14.5,
              color: _textDark,
            ),
            decoration: InputDecoration(
              hintText: 'Search name, email, code, designation...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: _textLight,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 21,
                color: _textMedium,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: _textMedium,
                ),
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: _outline(_border),
              enabledBorder: _outline(_border),
              focusedBorder: _outline(_primary, 1.4),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ------------------------------------------------
        // FILTER ICON BUTTON
        // ------------------------------------------------

        Tooltip(
          message: 'Filter',
          child: InkWell(
            onTap: _openFilterSheet,
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: filterActive ? _primaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: filterActive ? _primary : _border,
                      width: filterActive ? 1.4 : 1,
                    ),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 22,
                    color: filterActive ? _primary : _textMedium,
                  ),
                ),
                if (filterActive)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ==========================================================
  // ACTIVE FILTER CHIPS
  // ==========================================================

  Widget _buildActiveFilterChips() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: _primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _primary.withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_tree_outlined,
              size: 15,
              color: _primary,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                'Department: $_selectedDepartment',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedDepartment = 'All';
                });

                _applyFilters();
              },
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: _primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // RESULTS SECTION
  // ==========================================================

  Widget _buildResultsSection(bool mobile) {
    final pad = mobile ? 14.0 : 20.0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, 14),
            child: _buildResultHeader(),
          ),
          const Divider(height: 1),
          if (_filteredEmployees.isEmpty)
            _buildNoResults()
          else if (mobile)
            _buildEmployeeList()
          else
            _buildEmployeeTable(),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_filteredEmployees.length} Employees',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _hasActiveFilter
                    ? 'Showing filtered results'
                    : 'Showing all active employees',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (_hasActiveFilter)
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(
              Icons.filter_alt_off_outlined,
              size: 18,
            ),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: _primary,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // EMPLOYEE LIST (PHONE)
  // ==========================================================

  Widget _buildEmployeeList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _filteredEmployees.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: Color(0xFFEDEFF3),
      ),
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];

        final line2 = [
          employee.employeeCode,
          employee.designation,
        ].where((value) => value.trim().isNotEmpty).join('  •  ');

        final line3 = [
          employee.department,
          employee.email,
        ].where((value) => value.trim().isNotEmpty).join('  •  ');

        return InkWell(
          onTap: () => _openEmployee(employee),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _avatar(employee.name, 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name.trim().isEmpty
                            ? 'Unnamed Employee'
                            : employee.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (line2.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          line2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _textMedium,
                          ),
                        ),
                      ],
                      if (line3.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          line3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A8494),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFFB6BDC8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // EMPLOYEE TABLE (DESKTOP / TABLET)
  // Columns stretch to the full width, header stays fixed,
  // only the rows scroll.
  // ==========================================================

  Widget _cell(int flex, Widget child) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: child,
      ),
    );
  }

  Widget _buildEmployeeTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showDesignation = constraints.maxWidth >= 950;

        const headStyle = TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7B8493),
          letterSpacing: 0.4,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ------------------------------------------------
            // HEADER ROW
            // ------------------------------------------------

            Container(
              color: const Color(0xFFFAFBFC),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              child: Row(
                children: [
                  _cell(30, const Text('EMPLOYEE', style: headStyle)),
                  _cell(13, const Text('CODE', style: headStyle)),
                  if (showDesignation)
                    _cell(18, const Text('DESIGNATION', style: headStyle)),
                  _cell(18, const Text('DEPARTMENT', style: headStyle)),
                  _cell(17, const Text('MOBILE', style: headStyle)),
                  _cell(13, const Text('STATUS', style: headStyle)),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEDEFF3)),

            // ------------------------------------------------
            // ROWS (page scrolls)
            // ------------------------------------------------

            SizedBox(
              width: double.infinity,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredEmployees.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Color(0xFFEDEFF3),
                ),
                itemBuilder: (context, index) {
                  final employee = _filteredEmployees[index];

                  return InkWell(
                    onTap: () => _openEmployee(employee),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // ----------------------------------
                          // NAME + EMAIL
                          // ----------------------------------

                          _cell(
                            30,
                            Row(
                              children: [
                                _avatar(employee.name, 38),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.name.trim().isEmpty
                                            ? 'Unnamed Employee'
                                            : employee.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _display(employee.email),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: _textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _cell(
                            13,
                            Text(
                              _display(employee.employeeCode),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),

                          if (showDesignation)
                            _cell(
                              18,
                              Text(
                                _display(employee.designation),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textMedium,
                                ),
                              ),
                            ),

                          _cell(
                            18,
                            Text(
                              _display(employee.department),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textMedium,
                              ),
                            ),
                          ),

                          _cell(
                            17,
                            Text(
                              _display(employee.phone),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _textMedium,
                              ),
                            ),
                          ),

                          _cell(
                            13,
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _StatusBadge(status: employee.status),
                            ),
                          ),

                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: Color(0xFFB6BDC8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // NO RESULTS
  // ==========================================================

  Widget _buildNoResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No employees found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing your search or filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
              foregroundColor: _textDark,
              side: const BorderSide(color: Color(0xFFD9DEE7)),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear Filters'),
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
              'Unable to load employees',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadEmployees,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  Widget _avatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  String _display(String value) {
    if (value.trim().isEmpty) {
      return '—';
    }

    return value;
  }

  String _initials(String name) {
    final clean = name.trim();

    if (clean.isEmpty) {
      return '?';
    }

    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// =================================================================
// STATUS BADGE
// =================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status.trim().toLowerCase() == 'active';

    final label = status.trim().isEmpty ? 'N/A' : status;

    final background =
    isActive ? const Color(0xFFE9F8EF) : const Color(0xFFFDECEC);

    final foreground =
    isActive ? const Color(0xFF18864B) : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label[0].toUpperCase() + label.substring(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}