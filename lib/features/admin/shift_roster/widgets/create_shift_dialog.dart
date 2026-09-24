import 'package:flutter/material.dart';

// =================================================================
// CREATE SHIFT DIALOG
//
// Collects input only — it does NOT call any service. Returns a
// data map (matching ShiftModel.toJson()'s shape) via
// Navigator.pop(), or null if cancelled.
// =================================================================

Future<Map<String, dynamic>?> showCreateShiftDialog(BuildContext context) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => const CreateShiftDialog(),
  );
}

class CreateShiftDialog extends StatefulWidget {
  const CreateShiftDialog({super.key});

  @override
  State<CreateShiftDialog> createState() => _CreateShiftDialogState();
}

class _CreateShiftDialogState extends State<CreateShiftDialog> {
  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color border = Color(0xFFD9DEE5);
  static const Color errorColor = Color(0xFFD32F2F);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _graceController = TextEditingController(text: '15');
  final _requiredHoursController = TextEditingController(text: '8');

  bool _isOvernight = false;
  bool _isFlexiHours = false;

  String? _timeOrderError;

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

  static final RegExp _timeRegExp = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

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

  int _minutesOf(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
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

    // NOTE: 'name'/'shiftName' and 'graceMinutes'/'gracePeriodMinutes'
    // are both sent because your API docs don't confirm which key
    // the admin POST /shifts route actually expects (see
    // ShiftModel's doc comment). Once confirmed, drop the extra key.
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
      title: 'Create New Shift',
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

// =================================================================
// SHARED FORM BODY
//
// Used by both CreateShiftDialog and EditShiftDialog so the two
// stay visually identical. Kept in this file since it is only a
// private implementation detail of the create/edit dialogs.
// =================================================================

class ShiftFormDialog extends StatelessWidget {
  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFD9DEE5);
  static const Color errorColor = Color(0xFFD32F2F);

  final String title;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final TextEditingController graceController;
  final TextEditingController requiredHoursController;
  final bool isOvernight;
  final bool isFlexiHours;
  final ValueChanged<bool> onOvernightChanged;
  final ValueChanged<bool> onFlexiHoursChanged;
  final Future<void> Function(TextEditingController controller) onPickTime;
  final String? timeOrderError;
  final RegExp timeRegExp;

  const ShiftFormDialog({
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    required this.formKey,
    required this.nameController,
    required this.codeController,
    required this.startTimeController,
    required this.endTimeController,
    required this.graceController,
    required this.requiredHoursController,
    required this.isOvernight,
    required this.isFlexiHours,
    required this.onOvernightChanged,
    required this.onFlexiHoursChanged,
    required this.onPickTime,
    required this.timeOrderError,
    required this.timeRegExp,
  });

  InputDecoration _decoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: textLight),
      suffixIcon: suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
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

                  _label('Shift Name'),
                  TextFormField(
                    controller: nameController,
                    decoration: _decoration('e.g. Night Shift'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Shift name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  _label('Shift Code'),
                  TextFormField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _decoration('e.g. NS'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Shift code is required'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Start Time (24h)'),
                            TextFormField(
                              controller: startTimeController,
                              decoration: _decoration(
                                'e.g. 09:00',
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () => onPickTime(startTimeController),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (!timeRegExp.hasMatch(value.trim())) {
                                  return 'Use HH:mm';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('End Time (24h)'),
                            TextFormField(
                              controller: endTimeController,
                              decoration: _decoration(
                                'e.g. 18:00',
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.access_time_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () => onPickTime(endTimeController),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (!timeRegExp.hasMatch(value.trim())) {
                                  return 'Use HH:mm';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (timeOrderError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      timeOrderError!,
                      style: const TextStyle(fontSize: 12, color: errorColor),
                    ),
                  ],
                  const SizedBox(height: 14),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Grace Minutes'),
                            TextFormField(
                              controller: graceController,
                              keyboardType: TextInputType.number,
                              decoration: _decoration('e.g. 15'),
                              validator: (value) {
                                final parsed = int.tryParse(value?.trim() ?? '');
                                if (parsed == null || parsed < 0) {
                                  return 'Must be 0 or more';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Required Shift Hours'),
                            TextFormField(
                              controller: requiredHoursController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: _decoration('e.g. 8'),
                              validator: (value) {
                                final parsed = double.tryParse(
                                  value?.trim() ?? '',
                                );
                                if (parsed == null || parsed <= 0) {
                                  return 'Must be greater than 0';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  CheckboxListTile(
                    value: isOvernight,
                    onChanged: (value) => onOvernightChanged(value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: primary,
                    dense: true,
                    title: const Text(
                      '🌙 Overnight Shift (Crosses Midnight e.g. 10:00 PM to 6:00 AM)',
                      style: TextStyle(fontSize: 13, color: textDark),
                    ),
                  ),
                  CheckboxListTile(
                    value: isFlexiHours,
                    onChanged: (value) => onFlexiHoursChanged(value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: primary,
                    dense: true,
                    title: const Text(
                      '⏱ Enable Flexi-Hours Window',
                      style: TextStyle(fontSize: 13, color: textDark),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: textMedium),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onConfirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(confirmLabel),
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