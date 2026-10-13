import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/employee.dart';
import '../models/team_member_model.dart';
import '../models/team_request.dart';
import '../services/team_roles_service.dart';

// Palette copied from AdminDashboardScreen.
const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kFieldBorder = Color(0xFFD9DEE7);
const Color _kPageBg = Color(0xFFF7F8FA);
const Color _kDanger = Color(0xFFDC2626);

enum _Mode { existing, create }

class AddTeamMemberDialog extends StatefulWidget {
  const AddTeamMemberDialog({super.key, required this.members});

  /// Current team, used to mark occupied roles and to hide employees who
  /// already hold an admin role.
  final List<TeamMember> members;

  /// Resolves to a success message when something was saved, otherwise null.
  static Future<String?> show(
      BuildContext context, {
        required List<TeamMember> members,
      }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: AddTeamMemberDialog(members: members),
        ),
      ),
    );
  }

  @override
  State<AddTeamMemberDialog> createState() => _AddTeamMemberDialogState();
}

class _AddTeamMemberDialogState extends State<AddTeamMemberDialog> {
  final TeamRolesService _service = TeamRolesService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _designation = TextEditingController();
  final _department = TextEditingController();
  final _salary = TextEditingController();

  _Mode _mode = _Mode.existing;
  String? _role;
  String? _employeeId;

  List<Employee> _employees = const [];
  bool _loadingEmployees = true;
  String? _employeesError;

  bool _saving = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _role = _firstFreeRole();
    _loadEmployees();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _password,
      _designation,
      _department,
      _salary,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================================
  // DATA
  // ==========================================================

  Future<void> _loadEmployees() async {
    setState(() {
      _loadingEmployees = true;
      _employeesError = null;
    });

    try {
      final list = await _service.fetchEmployees();
      if (!mounted) return;
      setState(() {
        _employees = list;
        _loadingEmployees = false;
      });
    } on TeamRolesException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        _goToLogin();
        return;
      }
      setState(() {
        _loadingEmployees = false;
        _employeesError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingEmployees = false;
        _employeesError = 'Could not load employees.';
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
          (route) => false,
    );
  }

  /// Employees who do not already hold an admin role.
  List<Employee> get _eligible {
    final taken = widget.members
        .map((m) => m.employeeId)
        .where((id) => id.isNotEmpty)
        .toSet();

    return _employees.where((e) => !taken.contains(e.id)).toList();
  }

  Employee? get _selectedEmployee {
    final id = _employeeId;
    if (id == null) return null;

    for (final e in _employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// The member who already holds [role], when single-role-per-company is on.
  TeamMember? _occupant(String role) {
    if (!TeamRole.enforceSingleRolePerCompany) return null;

    for (final m in widget.members) {
      if (m.role == role) return m;
    }
    return null;
  }

  String? _firstFreeRole() {
    for (final role in TeamRole.assignable) {
      if (_occupant(role) == null) return role;
    }
    return null;
  }

  // ==========================================================
  // SUBMIT
  // ==========================================================

  Future<void> _submit() async {
    if (_saving) return; // prevent duplicate submissions
    FocusScope.of(context).unfocus();

    setState(() => _error = null);

    final role = _role;
    if (role == null) {
      setState(() => _error = 'Select an admin role.');
      return;
    }

    if (_mode == _Mode.existing) {
      if (_employeeId == null) {
        setState(() => _error = 'Select an employee.');
        return;
      }
    } else if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);

    try {
      if (_mode == _Mode.existing) {
        await _service.assignToExistingEmployee(
          AssignExistingRequest(employeeId: _employeeId!, role: role),
        );
      } else {
        await _service.createMember(
          CreateMemberRequest(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            password: _password.text,
            designation: _designation.text,
            department: _department.text,
            monthlySalary: _salary.text,
            role: role,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        _mode == _Mode.existing
            ? 'Admin role assigned.'
            : 'Team member created and role assigned.',
      );
    } on TeamRolesException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        _goToLogin();
        return;
      }
      // Form values are kept; only the banner changes.
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Please try again.';
      });
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _policyBox(),
                const SizedBox(height: 16),
                _modeTabs(),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  _errorBanner(_error!),
                  const SizedBox(height: 14),
                ],
                if (_mode == _Mode.existing)
                  _existingSection()
                else
                  _createSection(),
                const SizedBox(height: 20),
                _roleSection(),
              ],
            ),
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Add Team Member & Assign Role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final label = _mode == _Mode.existing
        ? 'Assign Admin Role'
        : 'Create & Assign Role';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: _kFieldBorder),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FilledButton(
              onPressed: (_saving || _role == null) ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(label),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // POLICY BOX + MODE TABS
  // ==========================================================

  Widget _policyBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dual-Role System Policy',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D4ED8),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Every team member is automatically an Employee (for salary '
                'slips, payroll & attendance) and can be assigned 1 '
                'Administrative Role (HR, Accountant, Manager, or General Admin).',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTabs() {
    Widget tab(String label, _Mode mode) {
      final selected = _mode == mode;

      return Expanded(
        child: InkWell(
          onTap: _saving
              ? null
              : () => setState(() {
            _mode = mode;
            _error = null;
          }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? _kPrimary : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? _kPrimary : _kTextDark,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          tab('Assign Role to Existing Employee', _Mode.existing),
          const SizedBox(width: 4),
          tab('Create New Team Member & Employee', _Mode.create),
        ],
      ),
    );
  }

  // ==========================================================
  // MODE A: EXISTING EMPLOYEE
  // ==========================================================

  Widget _existingSection() {
    if (_loadingEmployees) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_employeesError != null) {
      return Column(
        children: [
          Text(
            _employeesError!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9B1C1C)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    final eligible = _eligible;

    if (eligible.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kPageBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Every active employee already has an admin role.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      );
    }

    final selected = _selectedEmployee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labeled(
          'Select Employee *',
          DropdownButtonFormField<String>(
            initialValue: _employeeId,
            isExpanded: true,
            decoration: _dec(hint: 'Choose an employee'),
            items: [
              for (final e in eligible)
                DropdownMenuItem<String>(
                  value: e.id,
                  child: Text(
                    e.employeeCode.isEmpty
                        ? e.name
                        : '${e.employeeCode} - ${e.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() {
              _employeeId = value;
              _error = null;
            }),
          ),
        ),
        if (selected != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPageBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Wrap(
              spacing: 28,
              runSpacing: 10,
              children: [
                _infoItem('Code', selected.employeeCode),
                _infoItem('Department', selected.department),
                _infoItem('Phone', selected.phone),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value.trim().isEmpty ? '—' : value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // MODE B: CREATE NEW MEMBER
  // ==========================================================

  Widget _createSection() {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final two = width >= 520 ? 2 : 1;
          final three = width >= 620 ? 3 : (width >= 520 ? 2 : 1);

          return Column(
            children: [
              _grid(two, [
                _labeled(
                  'Full Name *',
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec(hint: 'e.g. Priya Sharma'),
                    validator: (v) => _required(v, 'Full name'),
                  ),
                ),
                _labeled(
                  'Work Email *',
                  TextFormField(
                    controller: _email,
                    enabled: !_saving,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(hint: 'priya@company.com'),
                    validator: _emailValidator,
                  ),
                ),
                _labeled(
                  'Phone Number',
                  TextFormField(
                    controller: _phone,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(hint: '+91 9876543210'),
                    validator: _phoneValidator,
                  ),
                ),
                _labeled(
                  'Initial Password *',
                  TextFormField(
                    controller: _password,
                    enabled: !_saving,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(
                      hint: 'Min 6 characters',
                      suffix: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: _passwordValidator,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _grid(three, [
                _labeled(
                  'Designation',
                  TextFormField(
                    controller: _designation,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(hint: 'e.g. HR Lead'),
                  ),
                ),
                _labeled(
                  'Department',
                  TextFormField(
                    controller: _department,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    decoration: _dec(hint: 'e.g. HR / Finance'),
                  ),
                ),
                _labeled(
                  'Monthly Base Salary (₹)',
                  TextFormField(
                    controller: _salary,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    textInputAction: TextInputAction.done,
                    decoration: _dec(hint: 'e.g. 50000'),
                    validator: _salaryValidator,
                  ),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // ROLE SELECTION
  // ==========================================================

  Widget _roleSection() {
    final hint = TeamRole.enforceSingleRolePerCompany
        ? ' (Max 1 HR, 1 Accountant, 1 Manager per company)'
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Select Admin Role & Access Level *',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kTextDark,
            ),
            children: [
              TextSpan(
                text: hint,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final columns = constraints.maxWidth >= 520 ? 2 : 1;
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final role in TeamRole.assignable)
                  SizedBox(width: width, child: _roleCard(role)),
              ],
            );
          },
        ),
        if (_role == null) ...[
          const SizedBox(height: 10),
          const Text(
            'All admin roles are already assigned. Change or revoke an '
                'existing role first.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF9B1C1C)),
          ),
        ],
      ],
    );
  }

  Widget _roleCard(String role) {
    final occupant = _occupant(role);
    final disabled = occupant != null;
    final selected = _role == role && !disabled;

    return InkWell(
      onTap: (disabled || _saving) ? null : () => setState(() => _role = role),
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF4EE)
                : (disabled ? const Color(0xFFF9FAFB) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? _kPrimary : _kFieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      TeamRole.label(role),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? _kPrimary : _kTextDark,
                      ),
                    ),
                  ),
                  if (selected)
                    const Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    )
                  else if (disabled)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Occupied (${occupant!.name})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                TeamRole.description(role),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // VALIDATORS
  // ==========================================================

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  String? _emailValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Work email is required';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s);
    return ok ? null : 'Enter a valid email address';
  }

  /// Optional. Accepts 7-15 digits, ignoring spaces, dashes and a leading '+'.
  String? _phoneValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    final digits = s.replaceAll(RegExp(r'[\s\-+]'), '');
    return RegExp(r'^\d{7,15}$').hasMatch(digits)
        ? null
        : 'Enter a valid phone number';
  }

  /// The web form marks the password as required.
  String? _passwordValidator(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Initial password is required';
    return s.length < 6 ? 'Minimum 6 characters' : null;
  }

  String? _salaryValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    final n = double.tryParse(s);
    if (n == null || n < 0) return 'Enter a valid amount';
    return null;
  }

  // ==========================================================
  // SMALL BUILDERS
  // ==========================================================

  Widget _grid(int columns, List<Widget> items) {
    final rows = <Widget>[];

    for (var i = 0; i < items.length; i += columns) {
      final chunk = items.skip(i).take(columns).toList();

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: 16),
              Expanded(
                child: j < chunk.length ? chunk[j] : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );

      if (i + columns < items.length) {
        rows.add(const SizedBox(height: 14));
      }
    }

    return Column(children: rows);
  }

  Widget _labeled(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _kDanger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9B1C1C)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec({String? hint, Widget? suffix}) {
    OutlineInputBorder outline(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: outline(_kFieldBorder),
      enabledBorder: outline(_kFieldBorder),
      disabledBorder: outline(const Color(0xFFEDEFF3)),
      focusedBorder: outline(_kPrimary),
      errorBorder: outline(_kDanger),
      focusedErrorBorder: outline(_kDanger),
    );
  }
}