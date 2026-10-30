import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/admin_employee_model.dart';
import '../models/admin_salary_structure_model.dart';
import '../services/admin_employee_service.dart';
import 'admin_employee_form_helpers.dart';
import 'admin_employee_theme.dart';

/// "$" icon -> "Set Salary - <name>".
/// Base salary, effective date, allowances and the estimated gross.
/// Returns `true` when saved.
class AdminSalaryDialog extends StatefulWidget {
  final AdminEmployeeService service;
  final AdminEmployeeModel employee;

  const AdminSalaryDialog({
    super.key,
    required this.service,
    required this.employee,
  });

  static Future<bool?> show(
      BuildContext context, {
        required AdminEmployeeService service,
        required AdminEmployeeModel employee,
      }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AdminSalaryDialog(service: service, employee: employee),
    );
  }

  @override
  State<AdminSalaryDialog> createState() => _AdminSalaryDialogState();
}

class _AllowanceRow {
  static int _seq = 0;
  final int id = _seq++;
  final TextEditingController name;
  final TextEditingController amount;

  _AllowanceRow({String name = '', String amount = ''})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: amount);

  double get value => double.tryParse(amount.text.trim()) ?? 0;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _AdminSalaryDialogState extends State<AdminSalaryDialog> {
  final TextEditingController _base = TextEditingController();
  final List<_AllowanceRow> _allowances = [];

  DateTime _effectiveFrom = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _base.dispose();
    for (final a in _allowances) {
      a.dispose();
    }
    super.dispose();
  }

  /// Loads the saved structure; falls back to the salary shown in the list.
  Future<void> _prefill() async {
    final existing = await widget.service.getSalaryStructure(widget.employee.id);
    if (!mounted) return;

    setState(() {
      if (existing != null) {
        _base.text = _num(existing.baseSalary);
        _effectiveFrom = existing.effectiveFrom;
        for (final a in existing.allowances) {
          _allowances.add(_AllowanceRow(name: a.name, amount: _num(a.amount)));
        }
      } else if (widget.employee.baseSalary != null) {
        _base.text = _num(widget.employee.baseSalary!);
      }
      _loading = false;
    });
  }

  String _num(double v) => v == v.roundToDouble() ? v.round().toString() : v.toString();

  double get _baseValue => double.tryParse(_base.text.trim()) ?? 0;
  double get _gross => _baseValue + _allowances.fold<double>(0, (s, a) => s + a.value);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _effectiveFrom = picked);
  }

  void _addAllowance() => setState(() => _allowances.add(_AllowanceRow()));

  void _removeAllowance(_AllowanceRow row) {
    setState(() => _allowances.remove(row));
    row.dispose();
  }

  Future<void> _save() async {
    if (_baseValue <= 0) {
      setState(() => _error = 'Enter a base salary greater than 0');
      return;
    }

    final allowances = <AdminAllowance>[];
    for (final a in _allowances) {
      final name = a.name.text.trim();
      if (name.isEmpty && a.value == 0) continue; // empty row
      if (name.isEmpty || a.value <= 0) {
        setState(() => _error = 'Each allowance needs a name and an amount');
        return;
      }
      allowances.add(AdminAllowance(name: name, amount: a.value));
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.saveSalary(
        widget.employee.id,
        AdminSalaryStructure(
          baseSalary: _baseValue,
          effectiveFrom: _effectiveFrom,
          allowances: allowances,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 540, maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            adminEmpDialogTitle(
              'Set Salary - ${widget.employee.name}',
              _saving ? null : () => Navigator.of(context).pop(false),
            ),
            Flexible(
              child: _loading
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(color: AdminEmpColors.primary)),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 8, 26, 8),
                child: _body(),
              ),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        adminEmpLabel('Base Salary (₹ / month)'),
        TextField(
          controller: _base,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14.5, color: AdminEmpColors.text),
          decoration: adminEmpInput('e.g. 45000'),
        ),
        const SizedBox(height: 20),
        adminEmpLabel('Effective From'),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: adminEmpInput(
              '',
              suffix: const Icon(Icons.calendar_today_outlined, size: 18, color: AdminEmpColors.text),
            ),
            child: Text(
              adminEmpFieldDate(_effectiveFrom),
              style: const TextStyle(fontSize: 14.5, color: AdminEmpColors.text),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Allowances',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AdminEmpColors.text,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _addAllowance,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                foregroundColor: AdminEmpColors.text,
                side: const BorderSide(color: AdminEmpColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_allowances.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'No allowances added.',
              style: TextStyle(fontSize: 13.5, color: AdminEmpColors.muted),
            ),
          )
        else
          for (final a in _allowances) _allowanceRow(a),
        const SizedBox(height: 16),
        _grossBox(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _allowanceRow(_AllowanceRow a) {
    return Padding(
      key: ValueKey(a.id),
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              controller: a.name,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: AdminEmpColors.text),
              decoration: adminEmpInput('e.g. HRA'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: TextField(
              controller: a.amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: AdminEmpColors.text),
              decoration: adminEmpInput('Amount'),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _removeAllowance(a),
            icon: const Icon(Icons.close_rounded, size: 18, color: AdminEmpColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _grossBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFBE3D8)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Estimated Gross / month',
              style: TextStyle(fontSize: 13.5, color: AdminEmpColors.muted),
            ),
          ),
          Text(
            adminEmpRupees(_gross),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AdminEmpColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) adminEmpErrorBox(_error!),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                style: adminEmpOutlineButton(),
                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: (_saving || _loading) ? null : _save,
                style: adminEmpPrimaryButton(),
                child: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Save Salary', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}