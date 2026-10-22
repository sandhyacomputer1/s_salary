import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routes/app_routes.dart';
import '../models/payroll_request.dart';
import '../models/salary_structure_model.dart';
import '../services/payroll_service.dart';
import 'payroll_format.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kFieldBorder = Color(0xFFD9DEE7);
const Color _kDanger = Color(0xFFDC2626);

/// "Set Salary - <name>": base salary, effective date, allowances and the
/// estimated gross. Resolves to true when the salary was saved.
class SetSalaryDialog extends StatefulWidget {
  const SetSalaryDialog({
    super.key,
    required this.employeeId,
    required this.employeeName,
    this.current,
  });

  final String employeeId;
  final String employeeName;

  /// The employee's existing structure, if any (pre-fills the form).
  final SalaryStructure? current;

  static Future<bool?> show(
    BuildContext context, {
    required String employeeId,
    required String employeeName,
    SalaryStructure? current,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SetSalaryDialog(
            employeeId: employeeId,
            employeeName: employeeName,
            current: current,
          ),
        ),
      ),
    );
  }

  @override
  State<SetSalaryDialog> createState() => _SetSalaryDialogState();
}

class _SetSalaryDialogState extends State<SetSalaryDialog> {
  final PayrollService _service = PayrollService();

  late final SalaryStructure _draft;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _draft =
        widget.current?.copy() ??
        SalaryStructure(
          employeeId: widget.employeeId,
          employeeName: widget.employeeName,
          baseSalary: 0,
          effectiveFrom: DateTime.now(),
          allowances: [],
        );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.effectiveFrom ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null || !mounted) return;

    setState(() => _draft.effectiveFrom = picked);
  }

  Future<void> _save() async {
    if (_saving) return; // no duplicate submissions
    FocusScope.of(context).unfocus();

    final problem = PayrollValidator.structure(_draft);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.saveStructure(
        widget.employeeId,
        SalaryStructureRequest(_draft),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PayrollException catch (e) {
      if (!mounted) return;

      if (e.isAuthError) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        return;
      }

      // Everything typed stays; only the banner changes.
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = 'Could not save the salary. Please try again.';
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  _errorBanner(_error!),
                  const SizedBox(height: 14),
                ],
                _label('Base Salary (₹ / month)'),
                TextFormField(
                  initialValue: _draft.baseSalary > 0
                      ? _plain(_draft.baseSalary)
                      : '',
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: _dec(hint: 'e.g. 50000'),
                  onChanged: (v) => setState(
                    () => _draft.baseSalary = double.tryParse(v.trim()) ?? 0,
                  ),
                ),
                const SizedBox(height: 14),
                _label('Effective From'),
                InkWell(
                  onTap: _saving ? null : _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: _dec(
                      suffix: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                      ),
                    ),
                    child: Text(
                      _draft.effectiveFrom == null
                          ? 'Select a date'
                          : _ddMMyyyy(_draft.effectiveFrom!),
                      style: const TextStyle(fontSize: 14, color: _kTextDark),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Allowances',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => setState(
                              () => _draft.allowances.add(
                                SalaryAllowance(name: '', amount: 0),
                              ),
                            ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextDark,
                        side: const BorderSide(color: _kFieldBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_draft.allowances.isEmpty)
                  Text(
                    'No allowances added.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  )
                else
                  for (final allowance in _draft.allowances)
                    _allowanceRow(allowance),
                const SizedBox(height: 14),
                _grossBox(),
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
          Expanded(
            child: Text(
              'Set Salary - ${widget.employeeName}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextDark,
              side: const BorderSide(color: _kFieldBorder),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                : const Text('Save Salary'),
          ),
        ],
      ),
    );
  }

  Widget _allowanceRow(SalaryAllowance allowance) {
    return Padding(
      key: ObjectKey(allowance),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: allowance.name,
              enabled: !_saving,
              decoration: _dec(hint: 'Name (e.g. HRA)'),
              onChanged: (v) => allowance.name = v,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: allowance.amount > 0
                  ? _plain(allowance.amount)
                  : '',
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: _dec(hint: 'Amount'),
              onChanged: (v) => setState(
                () => allowance.amount = double.tryParse(v.trim()) ?? 0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove allowance',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: _saving
                ? null
                : () => setState(() => _draft.allowances.remove(allowance)),
          ),
        ],
      ),
    );
  }

  Widget _grossBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF8E0D2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Estimated Gross / month',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Text(
            PayrollFormat.rupeesExact(_draft.estimatedGross),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SMALL HELPERS
  // ==========================================================

  /// 66000.0 -> "66000", 66000.5 -> "66000.5"
  String _plain(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  String _ddMMyyyy(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day-$month-${d.year}';
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kTextDark,
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
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
    OutlineInputBorder outline(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
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
    );
  }
}
