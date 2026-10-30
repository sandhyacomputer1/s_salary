import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import '../services/admin_employee_service.dart';
import 'admin_employee_form_helpers.dart';
import 'admin_employee_theme.dart';

/// Lock icon -> "Access & Credentials - <name>".
/// Portal access, work mode, login email and (optional) new password.
/// Returns `true` when saved.
class AdminAccessDialog extends StatefulWidget {
  final AdminEmployeeService service;
  final AdminEmployeeModel employee;

  const AdminAccessDialog({
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
      builder: (_) => AdminAccessDialog(service: service, employee: employee),
    );
  }

  @override
  State<AdminAccessDialog> createState() => _AdminAccessDialogState();
}

class _AdminAccessDialogState extends State<AdminAccessDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final TextEditingController _password = TextEditingController();

  late bool _portalAccess;
  late String _workMode;
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.employee.email);
    _portalAccess = widget.employee.portalAccess;
    _workMode = widget.employee.isFieldEmployee ? 'field' : 'in_house';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final email = _email.text.trim();
    final password = _password.text;

    try {
      await widget.service.updateAccess(
        widget.employee.id,
        portalAccess: _portalAccess,
        workMode: _workMode,
        // only send what changed, so the server never sees a "duplicate" email
        email: email == widget.employee.email ? null : email,
        password: password.isEmpty ? null : password,
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
              'Access & Credentials - ${widget.employee.name}',
              _saving ? null : () => Navigator.of(context).pop(false),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 8, 26, 8),
                child: Form(key: _formKey, child: _body()),
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
        adminEmpLabel('Portal Access Status'),
        Row(
          children: [
            _radio('Enabled', AdminEmpColors.success, _portalAccess, () => setState(() => _portalAccess = true)),
            const SizedBox(width: 18),
            _radio('Disabled', AdminEmpColors.danger, !_portalAccess, () => setState(() => _portalAccess = false)),
          ],
        ),
        const SizedBox(height: 22),
        adminEmpLabel('Employee Work Mode'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _modeCard(
                value: 'in_house',
                title: 'In-House',
                desc: 'Check-in/out only',
                accent: AdminEmpColors.blue,
                soft: AdminEmpColors.blueSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _modeCard(
                value: 'field',
                title: 'Field Employee',
                desc: '10-Min GPS tracking',
                accent: AdminEmpColors.green,
                soft: AdminEmpColors.greenSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        adminEmpLabel('Login Email *'),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14.5, color: AdminEmpColors.text),
          decoration: adminEmpInput('name@company.com'),
          validator: (v) {
            final s = v?.trim() ?? '';
            if (s.isEmpty) return 'Login email is required';
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        adminEmpLabel('New Password (Leave blank to keep unchanged)'),
        TextFormField(
          controller: _password,
          obscureText: _obscure,
          style: const TextStyle(fontSize: 14.5, color: AdminEmpColors.text),
          decoration: adminEmpInput(
            'Set new password...',
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 19,
                color: AdminEmpColors.muted,
              ),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            return v.length < 6 ? 'Password must be at least 6 characters' : null;
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _radio(String label, Color color, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 19,
              color: selected ? AdminEmpColors.blue : AdminEmpColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
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
          border: Border.all(
            color: selected ? accent : AdminEmpColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 19,
              color: selected ? accent : AdminEmpColors.muted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AdminEmpColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(desc, style: TextStyle(fontSize: 12, color: accent)),
                ],
              ),
            ),
          ],
        ),
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
                onPressed: _saving ? null : _save,
                style: adminEmpPrimaryButton(),
                child: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}