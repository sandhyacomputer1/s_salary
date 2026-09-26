import 'package:flutter/material.dart';

import '../models/department_model.dart';
import 'create_department_dialog.dart' show DepartmentFormDialog;

// =================================================================
// EDIT DEPARTMENT DIALOG
//
// Pre-filled with the department being edited. Returns a data map
// (name, code, description) via Navigator.pop(), or null if
// cancelled — does NOT call any service itself.
// =================================================================

Future<Map<String, dynamic>?> showEditDepartmentDialog(
    BuildContext context,
    DepartmentModel department,
    ) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => EditDepartmentDialog(department: department),
  );
}

class EditDepartmentDialog extends StatefulWidget {
  final DepartmentModel department;

  const EditDepartmentDialog({super.key, required this.department});

  @override
  State<EditDepartmentDialog> createState() => _EditDepartmentDialogState();
}

class _EditDepartmentDialogState extends State<EditDepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.department.name);
    _codeController = TextEditingController(text: widget.department.code);
    _descriptionController = TextEditingController(
      text: widget.department.description,
    );
  }

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
      title: 'Edit Department',
      confirmLabel: 'Update Department',
      confirmIcon: Icons.save_outlined,
      onConfirm: _submit,
      formKey: _formKey,
      nameController: _nameController,
      codeController: _codeController,
      descriptionController: _descriptionController,
    );
  }
}