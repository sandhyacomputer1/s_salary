import 'package:flutter/material.dart';

// =================================================================
// CREATE DEPARTMENT DIALOG
//
// Collects input only — does NOT call any service. Returns a data
// map (name, code, description) via Navigator.pop(), or null if
// cancelled.
// =================================================================

Future<Map<String, dynamic>?> showCreateDepartmentDialog(
    BuildContext context,
    ) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => const CreateDepartmentDialog(),
  );
}

class CreateDepartmentDialog extends StatefulWidget {
  const CreateDepartmentDialog({super.key});

  @override
  State<CreateDepartmentDialog> createState() =>
      _CreateDepartmentDialogState();
}

class _CreateDepartmentDialogState extends State<CreateDepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return DepartmentFormDialog(
      title: 'Create New Department',
      confirmLabel: 'Create Department',
      confirmIcon: Icons.add_rounded,
      onConfirm: _submit,
      formKey: _formKey,
      nameController: _nameController,
      codeController: _codeController,
      descriptionController: _descriptionController,
    );
  }
}

// =================================================================
// SHARED FORM BODY — used by both Create and Edit dialogs.
// =================================================================

class DepartmentFormDialog extends StatelessWidget {
  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFD9DEE5);

  final String title;
  final String confirmLabel;
  final IconData confirmIcon;
  final VoidCallback onConfirm;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController descriptionController;

  const DepartmentFormDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.confirmIcon,
    required this.onConfirm,
    required this.formKey,
    required this.nameController,
    required this.codeController,
    required this.descriptionController,
  });

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: textLight),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _label('Department Name', required: true),
                  TextFormField(
                    controller: nameController,
                    decoration: _decoration('e.g. Engineering, Sales, Operations'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Department name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _label('Department Code / Short Code'),
                  TextFormField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _decoration('e.g. ENG, SAL, OPS'),
                  ),
                  const SizedBox(height: 14),
                  _label('Description & Purpose'),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: _decoration(
                      'Brief description of responsibilities...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: textMedium),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onConfirm,
                        icon: Icon(confirmIcon, size: 17),
                        label: Text(confirmLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}