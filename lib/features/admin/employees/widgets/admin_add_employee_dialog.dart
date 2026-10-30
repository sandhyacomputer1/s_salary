import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/admin_employee_create_request.dart';
import '../models/admin_employee_model.dart';
import '../services/admin_employee_service.dart';
import 'admin_employee_theme.dart';

/// "Add New Employee" dialog (matches the web form).
/// Returns `true` when an employee was created.
class AdminAddEmployeeDialog extends StatefulWidget {
  final AdminEmployeeService service;
  final List<String> departments;

  /// Admin roles that are already taken (e.g. {'hr'}) -> shown disabled.
  final Set<String> occupiedRoles;

  const AdminAddEmployeeDialog({
    super.key,
    required this.service,
    required this.departments,
    this.occupiedRoles = const {},
  });

  static Future<bool?> show(
      BuildContext context, {
        required AdminEmployeeService service,
        required List<String> departments,
        Set<String> occupiedRoles = const {},
      }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminAddEmployeeDialog(
        service: service,
        departments: departments,
        occupiedRoles: occupiedRoles,
      ),
    );
  }

  @override
  State<AdminAddEmployeeDialog> createState() => _AdminAddEmployeeDialogState();
}

class _AdminAddEmployeeDialogState extends State<AdminAddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _salary = TextEditingController();
  final _address = TextEditingController();
  final _emergency = TextEditingController();
  final _account = TextEditingController();
  final _ifsc = TextEditingController();
  final _bank = TextEditingController();

  DateTime _doj = DateTime.now();
  DateTime? _dob;

  late String _department;
  String _employmentType = 'full_time';
  String _workMode = 'in_house';
  String _adminRole = 'none';
  String _gender = 'male';

  bool _saving = false;
  String? _error;

  static const _employmentTypes = {
    'full_time': 'Full Time',
    'part_time': 'Part Time',
    'contract': 'Contract',
    'intern': 'Intern',
  };

  static const _genders = {'male': 'Male', 'female': 'Female', 'other': 'Other'};

  static const _roles = {
    'none': 'None (Standard Employee - Fixed base role)',
    'hr': 'HR Admin — Manage Employees, Attendance & Leaves',
    'accountant': 'Accountant — Manage Salary Structures & Payroll',
    'manager': 'Manager — View Team Overview & Approve Requests',
  };

  @override
  void initState() {
    super.initState();
    _department = widget.departments.isNotEmpty ? widget.departments.first : '';
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _salary, _address, _emergency, _account, _ifsc, _bank]) {
      c.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------
  // actions
  // ------------------------------------------------------------

  Future<void> _pickDate({required bool joining}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: joining ? _doj : (_dob ?? DateTime(now.year - 25)),
      firstDate: DateTime(1950),
      lastDate: joining ? DateTime(now.year + 2) : now,
    );
    if (picked == null) return;
    setState(() => joining ? _doj = picked : _dob = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final request = AdminEmployeeCreateRequest(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      dateOfJoining: _doj,
      department: _department,
      employmentType: _employmentType,
      workMode: _workMode,
      baseSalary: double.tryParse(_salary.text.trim()),
      adminRole: _adminRole,
      dob: _dob,
      gender: _gender,
      address: _address.text,
      emergencyContact: _emergency.text,
      accountNumber: _account.text,
      ifsc: _ifsc.text,
      bankName: _bank.text,
    );

    try {
      final result = await widget.service.createEmployee(request);
      if (!mounted) return;
      await _showCreatedDialog(result);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// tempPassword is returned ONCE by the server, so show it right away.
  Future<void> _showCreatedDialog(AdminEmployeeCreateResult r) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Employee Created', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.employeeCode.isNotEmpty) Text('Employee code: ${r.employeeCode}'),
            if (r.tempPassword != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Temporary password (shown only once):',
                style: TextStyle(color: AdminEmpColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminEmpColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  r.tempPassword!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AdminEmpColors.text,
                  ),
                ),
              ),
            ],
            if (!r.salarySaved) ...[
              const SizedBox(height: 12),
              const Text(
                'Employee was created, but the base salary could not be saved. '
                    'Please set it from the salary action.',
                style: TextStyle(color: AdminEmpColors.danger, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          if (r.tempPassword != null)
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: r.tempPassword!)),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44),
              backgroundColor: AdminEmpColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 810, maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _titleBar(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                child: Form(key: _formKey, child: _form()),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _titleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 16, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Add New Employee',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AdminEmpColors.text,
              ),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded, color: AdminEmpColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminEmpColors.dangerSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AdminEmpColors.danger, fontSize: 13),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44),
                  foregroundColor: AdminEmpColors.text,
                  side: const BorderSide(color: AdminEmpColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44),
                  backgroundColor: AdminEmpColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: _saving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.add, size: 18),
                label: Text(
                  _saving ? 'Saving...' : 'Save Employee',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('ACCOUNT & BASIC INFO'),
        _twoCol(
          _labeled('Full Name', required: true, child: _text(_name, 'e.g. Rahul Sharma', validator: _req('Full name'))),
          _labeled('Work Email', required: true, child: _text(_email, 'rahul@company.com', keyboard: TextInputType.emailAddress, validator: _emailValidator)),
        ),
        _twoCol(
          _labeled('Phone Number', child: _text(_phone, '+91 9876543210', keyboard: TextInputType.phone)),
          _labeled('Date of Joining', required: true, child: _dateField(_doj, () => _pickDate(joining: true))),
        ),
        _section('JOB ROLE & SALARY'),
        _twoCol(
          _labeled('Department', required: true, child: _departmentDropdown()),
          _labeled('Employment Type', child: _mapDropdown(_employmentTypes, _employmentType, (v) => setState(() => _employmentType = v))),
        ),
        _labeled(
          'Initial Monthly Base Salary (₹)',
          child: _text(
            _salary,
            'e.g. 45000',
            keyboard: TextInputType.number,
            formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          ),
        ),
        _labeled('Employee Work Mode & Location Tracking', required: true, child: _workModeCards()),
        _labeled(
          'Admin Role & Access Level (Optional - Max 1 HR, 1 Accountant, 1 Manager per company)',
          child: _roleDropdown(),
        ),
        _section('PERSONAL DETAILS'),
        _twoCol(
          _labeled('Date of Birth', child: _dateField(_dob, () => _pickDate(joining: false))),
          _labeled('Gender', child: _mapDropdown(_genders, _gender, (v) => setState(() => _gender = v))),
        ),
        _labeled('Residential Address', child: _text(_address, 'City, State, Country')),
        _labeled('Emergency Contact Phone', child: _text(_emergency, 'Parent/Spouse phone', keyboard: TextInputType.phone)),
        _section('BANK DETAILS'),
        _twoCol(
          _labeled('Account Number', child: _text(_account, 'Bank account number', keyboard: TextInputType.number)),
          _labeled('IFSC Code', child: _text(_ifsc, 'e.g. SBIN0001234', caps: true)),
        ),
        _labeled('Bank Name', child: _text(_bank, 'e.g. State Bank of India')),
        const SizedBox(height: 8),
      ],
    );
  }

  // ------------------------------------------------------------
  // field builders
  // ------------------------------------------------------------

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AdminEmpColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AdminEmpColors.border),
        ],
      ),
    );
  }

  Widget _labeled(String label, {required Widget child, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$label *' : label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AdminEmpColors.text,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  /// Two columns on wide dialogs, stacked on phones.
  Widget _twoCol(Widget a, Widget b) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 520) return Column(children: [a, b]);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 16),
            Expanded(child: b),
          ],
        );
      },
    );
  }

  InputDecoration _dec(String hint) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(AdminEmpColors.border),
      focusedBorder: border(AdminEmpColors.primary),
      errorBorder: border(AdminEmpColors.danger),
      focusedErrorBorder: border(AdminEmpColors.danger),
    );
  }

  Widget _text(
      TextEditingController c,
      String hint, {
        TextInputType? keyboard,
        String? Function(String?)? validator,
        List<TextInputFormatter>? formatters,
        bool caps = false,
      }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: validator,
      inputFormatters: formatters,
      textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.none,
      style: const TextStyle(fontSize: 14.5, color: AdminEmpColors.text),
      decoration: _dec(hint),
    );
  }

  Widget _dateField(DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: _dec('').copyWith(
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AdminEmpColors.text),
        ),
        child: Text(
          adminEmpFieldDate(value),
          style: TextStyle(
            fontSize: 14.5,
            color: value == null ? const Color(0xFF9CA3AF) : AdminEmpColors.text,
          ),
        ),
      ),
    );
  }

  Widget _departmentDropdown() {
    final items = widget.departments;
    return DropdownButtonFormField<String>(
      value: items.contains(_department) ? _department : null,
      isExpanded: true,
      decoration: _dec('Select department'),
      validator: (v) => (v == null || v.isEmpty) ? 'Select a department' : null,
      items: items.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
      onChanged: (v) => setState(() => _department = v ?? _department),
    );
  }

  Widget _mapDropdown(Map<String, String> options, String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _dec(''),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _roleDropdown() {
    return DropdownButtonFormField<String>(
      value: _adminRole,
      isExpanded: true,
      decoration: _dec(''),
      items: _roles.entries.map((e) {
        final occupied = widget.occupiedRoles.contains(e.key);
        return DropdownMenuItem<String>(
          value: e.key,
          enabled: !occupied,
          child: Text(
            occupied ? '${e.value} (Occupied)' : e.value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: occupied ? AdminEmpColors.muted : AdminEmpColors.text,
            ),
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _adminRole = v);
      },
    );
  }

  Widget _workModeCards() {
    return LayoutBuilder(
      builder: (context, c) {
        final inHouse = _modeCard(
          value: 'in_house',
          title: 'In-House Employee',
          desc: 'Office / Stationed. Location tracked ONLY during Check-In & Check-Out.',
          accent: AdminEmpColors.blue,
          soft: AdminEmpColors.blueSoft,
        );
        final field = _modeCard(
          value: 'field',
          title: 'Field Employee',
          desc: 'On-the-go / Field work. Continuous GPS tracking every 10 mins with live map tracking.',
          accent: AdminEmpColors.green,
          soft: AdminEmpColors.greenSoft,
        );
        if (c.maxWidth < 520) {
          return Column(children: [inHouse, const SizedBox(height: 12), field]);
        }
        // IntrinsicHeight: "stretch" needs a bounded height, and the form
        // lives inside a scroll view (unbounded height).
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: inHouse),
              const SizedBox(width: 16),
              Expanded(child: field),
            ],
          ),
        );
      },
    );
  }

  Widget _modeCard({
    required String value,
    required String title,
    required String desc,
    required Color accent,
    required Color soft,
  }) {
    final selected = _workMode == value;
    return InkWell(
      onTap: () => setState(() => _workMode = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? soft : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accent : AdminEmpColors.border, width: selected ? 1.6 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? accent : AdminEmpColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AdminEmpColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12.5, height: 1.35, color: accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // validators
  // ------------------------------------------------------------

  String? Function(String?) _req(String name) =>
          (v) => (v == null || v.trim().isEmpty) ? '$name is required' : null;

  String? _emailValidator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Work email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Enter a valid email';
    return null;
  }
}