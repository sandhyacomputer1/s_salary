import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);

class EmployeeAccessDialog extends StatefulWidget {
  final String employeeName;
  final String currentEmail;
  final String currentWorkMode;
  final bool currentPortalAccess;

  const EmployeeAccessDialog({
    super.key,
    required this.employeeName,
    required this.currentEmail,
    required this.currentWorkMode,
    required this.currentPortalAccess,
  });

  static Future<void> show(BuildContext context, {required String employeeName, required String email, required String workMode, required bool portalAccess}) {
    return showDialog(
      context: context,
      builder: (_) => EmployeeAccessDialog(
        employeeName: employeeName,
        currentEmail: email,
        currentWorkMode: workMode,
        currentPortalAccess: portalAccess,
      ),
    );
  }

  @override
  State<EmployeeAccessDialog> createState() => _EmployeeAccessDialogState();
}

class _EmployeeAccessDialogState extends State<EmployeeAccessDialog> {
  late bool _portalAccess;
  late String _workMode;
  late TextEditingController _emailCtrl;
  final TextEditingController _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _portalAccess = widget.currentPortalAccess;
    _workMode = widget.currentWorkMode;
    _emailCtrl = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Access & Credentials - ${widget.employeeName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextDark),
              ),
              const SizedBox(height: 20),

              const Text('Portal Access Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _portalAccess,
                    activeColor: _kPrimary,
                    onChanged: (v) => setState(() => _portalAccess = v!),
                  ),
                  const Text('Enabled', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  Radio<bool>(
                    value: false,
                    groupValue: _portalAccess,
                    activeColor: _kPrimary,
                    onChanged: (v) => setState(() => _portalAccess = v!),
                  ),
                  const Text('Disabled', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Employee Work Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _modeCard('In-House', 'Check-in/out only', 'in_house', Icons.business),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _modeCard('Field Employee', '10-Min GPS tracking', 'field', Icons.location_on),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Login Email *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),

              const Text('New Password (Leave blank to keep unchanged)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Set new password...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: _kTextDark)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved (Note: Backend endpoint for these fields may need verification)')),
                      );
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard(String title, String sub, String value, IconData icon) {
    final selected = _workMode == value;
    return InkWell(
      onTap: () => setState(() => _workMode = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? const Color(0xFF2563EB) : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF2563EB) : _kTextDark)),
                  Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}