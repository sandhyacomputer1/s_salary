import 'package:flutter/material.dart';

import '../models/shift_model.dart';
import 'create_shift_dialog.dart' show ShiftFormDialog;

// =================================================================
// EDIT SHIFT DIALOG
//
// Same fields and validation as CreateShiftDialog (shares the
// ShiftFormDialog body so both stay visually identical), pre-filled
// with the shift being edited. Returns a data map on save, or null
// if cancelled — it does NOT call any service itself.
// =================================================================

Future<Map<String, dynamic>?> showEditShiftDialog(
    BuildContext context,
    ShiftModel shift,
    ) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => EditShiftDialog(shift: shift),
  );
}

class EditShiftDialog extends StatefulWidget {
  final ShiftModel shift;

  const EditShiftDialog({super.key, required this.shift});

  @override
  State<EditShiftDialog> createState() => _EditShiftDialogState();
}

class _EditShiftDialogState extends State<EditShiftDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _graceController;
  late final TextEditingController _requiredHoursController;

  late bool _isOvernight;
  late bool _isFlexiHours;

  String? _timeOrderError;

  static final RegExp _timeRegExp = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

  @override
  void initState() {
    super.initState();

    final shift = widget.shift;

    _nameController = TextEditingController(text: shift.name);
    _codeController = TextEditingController(text: shift.code);
    _startTimeController = TextEditingController(text: shift.startTime);
    _endTimeController = TextEditingController(text: shift.endTime);
    _graceController = TextEditingController(
      text: shift.graceMinutes.toString(),
    );
    _requiredHoursController = TextEditingController(
      text: _formatHours(shift.requiredHours),
    );

    _isOvernight = shift.isOvernight;
    _isFlexiHours = shift.isFlexiHours;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _graceController.dispose();
    _requiredHoursController.dispose();
    super.dispose();
  }

  String _formatHours(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  int _minutesOf(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selected == null) return;

    final hour = selected.hour.toString().padLeft(2, '0');
    final minute = selected.minute.toString().padLeft(2, '0');

    setState(() {
      controller.text = '$hour:$minute';
    });
  }

  void _submit() {
    setState(() {
      _timeOrderError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final start = _startTimeController.text.trim();
    final end = _endTimeController.text.trim();

    if (!_isOvernight && _minutesOf(end) <= _minutesOf(start)) {
      setState(() {
        _timeOrderError =
        'End time must be after start time, or enable Overnight Shift.';
      });
      return;
    }

    // See CreateShiftDialog for why both key spellings are sent —
    // the admin update route's real field names aren't confirmed.
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'shiftName': _nameController.text.trim(),
      'code': _codeController.text.trim(),
      'startTime': start,
      'endTime': end,
      'graceMinutes': int.parse(_graceController.text.trim()),
      'gracePeriodMinutes': int.parse(_graceController.text.trim()),
      'requiredHours': double.parse(_requiredHoursController.text.trim()),
      'isOvernight': _isOvernight,
      'isFlexiHours': _isFlexiHours,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShiftFormDialog(
      title: 'Edit Shift Configuration',
      confirmLabel: 'Save Shift',
      onConfirm: _submit,
      formKey: _formKey,
      nameController: _nameController,
      codeController: _codeController,
      startTimeController: _startTimeController,
      endTimeController: _endTimeController,
      graceController: _graceController,
      requiredHoursController: _requiredHoursController,
      isOvernight: _isOvernight,
      isFlexiHours: _isFlexiHours,
      onOvernightChanged: (value) => setState(() => _isOvernight = value),
      onFlexiHoursChanged: (value) => setState(() => _isFlexiHours = value),
      onPickTime: _pickTime,
      timeOrderError: _timeOrderError,
      timeRegExp: _timeRegExp,
    );
  }
}