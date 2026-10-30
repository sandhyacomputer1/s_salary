import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/admin_bulk_import_models.dart';
import '../services/admin_employee_service.dart';
import 'admin_employee_theme.dart';

/// "Autonomous Bulk Employee Onboarding": a grid to onboard many employees
/// with one API call. Returns `true` when at least one employee was created.
class AdminBulkImportDialog extends StatefulWidget {
  final AdminEmployeeService service;
  final List<String> departments;

  /// Number used for the first AUTO CODE shown in the grid (e.g. 4 -> EMP-0004).
  /// The server still assigns the real codes.
  final int nextCodeNumber;

  const AdminBulkImportDialog({
    super.key,
    required this.service,
    required this.departments,
    this.nextCodeNumber = 1,
  });

  static Future<bool?> show(
      BuildContext context, {
        required AdminEmployeeService service,
        required List<String> departments,
        int nextCodeNumber = 1,
      }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminBulkImportDialog(
        service: service,
        departments: departments,
        nextCodeNumber: nextCodeNumber,
      ),
    );
  }

  @override
  State<AdminBulkImportDialog> createState() => _AdminBulkImportDialogState();
}

/// One editable grid row.
class _GridRow {
  static int _seq = 0;
  final int id = _seq++;

  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();

  String department;
  String workMode = 'in_house';
  String employmentType = 'full_time';

  _GridRow(this.department);

  bool get isBlank =>
      name.text.trim().isEmpty &&
          email.text.trim().isEmpty &&
          phone.text.trim().isEmpty;

  bool get nameOk => name.text.trim().isNotEmpty;
  bool get emailOk =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim());
  bool get isValid => nameOk && emailOk && department.isNotEmpty;

  void clear() {
    name.clear();
    email.clear();
    phone.clear();
  }

  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
  }
}

class _AdminBulkImportDialogState extends State<AdminBulkImportDialog> {
  final List<_GridRow> _rows = [];

  bool _showErrors = false;
  bool _saving = false;
  String? _error;
  AdminBulkImportResult? _result;

  // Fixed widths so dropdown text is never cut ("In-H...", "Full ...").
  static const double _deptW = 160;
  static const double _modeW = 140;
  static const double _typeW = 140;

  static const _workModes = {'in_house': 'In-House', 'field': 'Field'};
  static const _empTypes = {
    'full_time': 'Full Time',
    'part_time': 'Part Time',
    'contract': 'Contract',
    'intern': 'Intern',
  };

  String get _defaultDept =>
      widget.departments.isNotEmpty ? widget.departments.first : '';

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) {
      _rows.add(_GridRow(_defaultDept));
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------

  int get _validCount => _rows.where((r) => !r.isBlank && r.isValid).length;

  String _code(int index) =>
      'EMP-${(widget.nextCodeNumber + index).toString().padLeft(4, '0')}';

  void _addRow() => setState(() => _rows.add(_GridRow(_defaultDept)));

  void _clearGrid() {
    setState(() {
      for (final r in _rows) {
        r.clear();
      }
      _showErrors = false;
      _error = null;
    });
  }

  void _removeRow(_GridRow row) {
    if (_rows.length <= 1) {
      setState(row.clear);
      return;
    }
    setState(() {
      _rows.remove(row);
    });
    row.dispose();
  }

  void _close() {
    Navigator.of(context).pop((_result?.importedCount ?? 0) > 0);
  }

  Future<void> _submit() async {
    final filled = _rows.where((r) => !r.isBlank).toList();

    if (filled.any((r) => !r.isValid)) {
      setState(() {
        _showErrors = true;
        _error = 'Please fix the highlighted rows. Name, a valid email and a '
            'department are required.';
      });
      return;
    }
    if (filled.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final entries = filled
          .map((r) => AdminBulkImportEntry(
        name: r.name.text,
        email: r.email.text,
        phone: r.phone.text,
        department: r.department,
        workMode: r.workMode,
        employmentType: r.employmentType,
      ))
          .toList();

      final result = await widget.service.bulkImport(entries);
      if (!mounted) return;
      setState(() {
        _result = result;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
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
        constraints: BoxConstraints(maxWidth: 1180, maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _titleBar(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 8),
                child: _result == null ? _gridBody() : _resultPanel(_result!),
              ),
            ),
            if (_result == null) _footer(),
            if (_result != null) const SizedBox(height: 20),
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
              'Autonomous Bulk Employee Onboarding',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AdminEmpColors.text,
              ),
            ),
          ),
          IconButton(
            onPressed: _saving ? null : _close,
            icon: const Icon(Icons.close_rounded, color: AdminEmpColors.muted),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // grid
  // ------------------------------------------------------------

  Widget _gridBody() {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1080;

        final intro = const Text(
          'Directly enter employee details in the grid below. Departments are '
              'selectable from pre-defined company departments and Employee Codes '
              'are calculated automatically.',
          style: TextStyle(fontSize: 13.5, color: AdminEmpColors.muted, height: 1.4),
        );

        final buttons = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: _saving ? null : _clearGrid,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: AdminEmpColors.text,
                side: const BorderSide(color: AdminEmpColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Clear Grid', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: _saving ? null : _addRow,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: AdminEmpColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('+ Add Row', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Expanded(child: intro), const SizedBox(width: 16), buttons],
              )
            else ...[
              intro,
              const SizedBox(height: 12),
              buttons,
            ],
            const SizedBox(height: 16),
            wide ? _wideGrid() : _compactList(),
          ],
        );
      },
    );
  }

  // ----- wide (web / tablet): table -----

  Widget _wideGrid() {
    const h = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AdminEmpColors.muted,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AdminEmpColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AdminEmpColors.headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const Row(
              children: [
                SizedBox(width: 30, child: Text('#', style: h)),
                SizedBox(width: 92, child: Text('AUTO CODE', style: h)),
                Expanded(flex: 30, child: Text('FULL NAME *', style: h)),
                Expanded(flex: 30, child: Text('WORK EMAIL *', style: h)),
                Expanded(flex: 26, child: Text('PHONE NUMBER', style: h)),
                SizedBox(width: _deptW, child: Text('DEPARTMENT *', style: h)),
                SizedBox(width: _modeW, child: Text('WORK MODE *', style: h)),
                SizedBox(width: _typeW, child: Text('EMP TYPE', style: h)),
                SizedBox(width: 40),
              ],
            ),
          ),
          for (var i = 0; i < _rows.length; i++) ...[
            _wideRow(i, _rows[i]),
            if (i != _rows.length - 1)
              const Divider(height: 1, color: AdminEmpColors.border),
          ],
        ],
      ),
    );
  }

  Widget _wideRow(int index, _GridRow r) {
    return Container(
      key: ValueKey(r.id),
      color: index.isOdd ? const Color(0xFFFAFAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AdminEmpColors.primary,
              ),
            ),
          ),
          SizedBox(width: 92, child: _codeChip(_code(index))),
          Expanded(flex: 30, child: _pad(_nameField(r))),
          Expanded(flex: 30, child: _pad(_emailField(r))),
          Expanded(flex: 26, child: _pad(_phoneField(r))),
          SizedBox(width: _deptW, child: _pad(_deptDropdown(r))),
          SizedBox(width: _modeW, child: _pad(_mapDropdown(_workModes, r.workMode, (v) => setState(() => r.workMode = v)))),
          SizedBox(width: _typeW, child: _pad(_mapDropdown(_empTypes, r.employmentType, (v) => setState(() => r.employmentType = v)))),
          SizedBox(
            width: 40,
            child: IconButton(
              tooltip: 'Remove row',
              onPressed: _saving ? null : () => _removeRow(r),
              icon: const Icon(Icons.close_rounded, size: 18, color: AdminEmpColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pad(Widget w) =>
      Padding(padding: const EdgeInsets.only(right: 12), child: w);

  // ----- compact (phone): one card per row -----

  Widget _compactList() {
    return Column(
      children: [
        for (var i = 0; i < _rows.length; i++) _compactCard(i, _rows[i]),
      ],
    );
  }

  Widget _compactCard(int index, _GridRow r) {
    return Container(
      key: ValueKey(r.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AdminEmpColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AdminEmpColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              _codeChip(_code(index)),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _saving ? null : () => _removeRow(r),
                icon: const Icon(Icons.close_rounded, size: 18, color: AdminEmpColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _nameField(r),
          const SizedBox(height: 10),
          _emailField(r),
          const SizedBox(height: 10),
          _phoneField(r),
          const SizedBox(height: 10),
          _deptDropdown(r),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _mapDropdown(_workModes, r.workMode, (v) => setState(() => r.workMode = v))),
              const SizedBox(width: 10),
              Expanded(child: _mapDropdown(_empTypes, r.employmentType, (v) => setState(() => r.employmentType = v))),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // cells
  // ------------------------------------------------------------

  Widget _codeChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        code,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AdminEmpColors.text,
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, {bool error = false}) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );
    final normal = error ? AdminEmpColors.danger : AdminEmpColors.border;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      enabledBorder: b(normal),
      focusedBorder: b(error ? AdminEmpColors.danger : AdminEmpColors.primary),
    );
  }

  bool _bad(_GridRow r, bool fieldOk) =>
      _showErrors && !r.isBlank && !fieldOk;

  Widget _nameField(_GridRow r) {
    return TextField(
      controller: r.name,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, color: AdminEmpColors.text),
      decoration: _dec('e.g. Rahul Sharma', error: _bad(r, r.nameOk)),
    );
  }

  Widget _emailField(_GridRow r) {
    return TextField(
      controller: r.email,
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, color: AdminEmpColors.text),
      decoration: _dec('rahul@company.com', error: _bad(r, r.emailOk)),
    );
  }

  Widget _phoneField(_GridRow r) {
    return TextField(
      controller: r.phone,
      keyboardType: TextInputType.phone,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14, color: AdminEmpColors.text),
      decoration: _dec('+91 9876543210'),
    );
  }

  static const TextStyle _ddStyle =
  TextStyle(fontSize: 13.5, color: AdminEmpColors.text);

  Widget _deptDropdown(_GridRow r) {
    final items = widget.departments;
    return DropdownButtonFormField<String>(
      value: items.contains(r.department) ? r.department : null,
      isExpanded: true,
      style: _ddStyle,
      iconSize: 20,
      decoration: _dec('Select'),
      items: items.map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: (v) => setState(() => r.department = v ?? r.department),
    );
  }

  Widget _mapDropdown(
      Map<String, String> options,
      String value,
      ValueChanged<String> onChanged,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: _ddStyle,
      iconSize: 20,
      decoration: _dec(''),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  // ------------------------------------------------------------
  // footer
  // ------------------------------------------------------------

  Widget _footer() {
    final n = _validCount;
    return Padding(
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
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : _close,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  foregroundColor: AdminEmpColors.text,
                  side: const BorderSide(color: AdminEmpColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: (_saving || n == 0) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  backgroundColor: AdminEmpColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFF4B79F),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  'Confirm & Onboard ($n) Employees',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // result
  // ------------------------------------------------------------

  Widget _resultPanel(AdminBulkImportResult r) {
    final passwords = r.imported.where((e) => e.tempPassword.isNotEmpty).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminEmpColors.greenSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onboarding Completed! Successfully onboarded ${r.importedCount} employee(s).',
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AdminEmpColors.green,
            ),
          ),
          if (r.errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Warnings / Failed Rows (${r.errors.length}):',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(height: 8),
            for (final e in r.errors)
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 4),
                child: Text(
                  'Row ${e.row}: ${e.email} — ${e.error}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                ),
              ),
          ],
          if (passwords.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Temporary passwords (shown only once)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AdminEmpColors.text,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    final text = passwords
                        .map((e) => '${e.employeeCode}\t${e.name}\t${e.email}\t${e.tempPassword}')
                        .join('\n');
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy all'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminEmpColors.border),
              ),
              child: Column(
                children: [
                  for (final e in passwords)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 84,
                            child: Text(
                              e.employeeCode,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${e.name}  •  ${e.email}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, color: AdminEmpColors.muted),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SelectableText(
                            e.tempPassword,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AdminEmpColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _close,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 46),
                backgroundColor: AdminEmpColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Done & Close', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}