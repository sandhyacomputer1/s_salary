import 'package:flutter/material.dart';

import '../models/emp_leave_balance_model.dart';
import '../models/emp_leave_model.dart';

class EmpLeaveForm extends StatefulWidget {
  final List<EmpLeaveBalanceModel> balances;
  final bool isSubmitting;

  /// Returns true when the request was accepted by the backend.
  final Future<bool> Function(EmpLeaveRequest request) onSubmit;

  const EmpLeaveForm({
    super.key,
    required this.balances,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<EmpLeaveForm> createState() => _EmpLeaveFormState();
}

class _EmpLeaveFormState extends State<EmpLeaveForm> {
  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFF3EE);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color fill = Color(0xFFF7F8FA);
  static const Color danger = Color(0xFFD64545);

  final TextEditingController _reasonController = TextEditingController();

  String? _selectedType;
  bool _isHalfDay = false;
  late DateTime _startDate;
  late DateTime _endDate;

  bool _busy = false;
  String? _reasonError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _startDate = today;
    _endDate = today;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // ============================================================
  // DERIVED STATE
  // ============================================================

  List<String> get _types {
    final fromBackend = widget.balances
        .map((b) => b.leaveType)
        .where((t) => t.isNotEmpty)
        .toList();

    final source =
    fromBackend.isNotEmpty ? fromBackend : EmpLeaveTypeHelper.fallbackTypes;

    return source.toSet().toList();
  }

  String get _effectiveType {
    final types = _types;
    final selected = _selectedType;
    if (selected != null && types.contains(selected)) return selected;
    return types.first;
  }

  bool get _isRangeValid => !_endDate.isBefore(_startDate);

  /// Inclusive calendar days (matches the backend's totals in leave history).
  int get _inclusiveDays {
    final start = DateTime.utc(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime.utc(_endDate.year, _endDate.month, _endDate.day);
    return end.difference(start).inDays + 1;
  }

  double get _totalDays => _isHalfDay ? 0.5 : _inclusiveDays.toDouble();

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: isStart ? DateTime(now.year - 1, 1, 1) : _startDate,
      lastDate: DateTime(now.year + 2, 12, 31),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(primary: primary),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      _formError = null;

      if (isStart) {
        _startDate = _dateOnly(picked);
        if (_isHalfDay || _endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = _dateOnly(picked);
      }
    });
  }

  void _setHalfDay(bool value) {
    setState(() {
      _isHalfDay = value;
      _formError = null;

      // Every half-day record in leave history is a single day.
      if (value) _endDate = _startDate;
    });
  }

  Future<void> _handleSubmit() async {
    if (_busy || widget.isSubmitting) return;

    FocusScope.of(context).unfocus();

    final reason = _reasonController.text.trim();
    final type = _effectiveType;

    String? reasonError;
    String? formError;

    if (reason.isEmpty) {
      reasonError = 'Please enter a reason for your leave.';
    }

    if (!_isRangeValid) {
      formError = 'End date cannot be before start date.';
    } else {
      final balance =
          widget.balances.where((b) => b.leaveType == type).firstOrNull;

      // Soft check for paid types only; the backend stays the final authority.
      if (balance != null &&
          EmpLeaveTypeHelper.isPaid(type) &&
          _totalDays > balance.remaining) {
        formError = 'Insufficient ${EmpLeaveTypeHelper.displayName(type)} balance. '
            'You have ${EmpLeaveTypeHelper.formatDays(balance.remaining)} day(s) remaining.';
      }
    }

    if (reasonError != null || formError != null) {
      setState(() {
        _reasonError = reasonError;
        _formError = formError;
      });
      return;
    }

    setState(() {
      _reasonError = null;
      _formError = null;
      _busy = true;
    });

    var success = false;

    try {
      success = await widget.onSubmit(
        EmpLeaveRequest(
          leaveType: type,
          startDate: _startDate,
          endDate: _endDate,
          reason: reason,
          isHalfDay: _isHalfDay,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (success && mounted) _resetForm();
  }

  void _resetForm() {
    final today = _dateOnly(DateTime.now());

    setState(() {
      _reasonController.clear();
      _selectedType = null;
      _isHalfDay = false;
      _startDate = today;
      _endDate = today;
      _reasonError = null;
      _formError = null;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final disabled = _busy || widget.isSubmitting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apply for Leave',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Submit full-day or half-day leave applications with real-time balance checks',
                style: TextStyle(fontSize: 13.5, color: textMedium),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: border),
              const SizedBox(height: 18),
              _row(
                wide,
                _field('Leave Type *', _typeDropdown(disabled)),
                _field('Leave Duration Option *', _durationToggle(disabled)),
              ),
              const SizedBox(height: 16),
              _row(
                wide,
                _field(
                  'Start Date *',
                  _dateField(
                    _startDate,
                    disabled ? null : () => _pickDate(isStart: true),
                  ),
                ),
                _field(
                  'End Date *',
                  _dateField(
                    _endDate,
                    (disabled || _isHalfDay)
                        ? null
                        : () => _pickDate(isStart: false),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _field('Reason for Leave Application *', _reasonField(disabled)),
              const SizedBox(height: 16),
              if (_formError != null) ...[
                _errorBanner(_formError!),
                const SizedBox(height: 12),
              ],
              _summaryBar(wide, disabled),
            ],
          );
        },
      ),
    );
  }

  Widget _row(bool wide, Widget left, Widget right) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, const SizedBox(height: 16), right],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _field(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _typeDropdown(bool disabled) {
    final types = _types;
    final selected = _effectiveType;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: textMedium),
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          items: [
            for (final type in types)
              DropdownMenuItem<String>(
                value: type,
                child: Text(
                  EmpLeaveTypeHelper.optionLabel(type),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: disabled
              ? null
              : (value) {
            if (value == null) return;
            setState(() {
              _selectedType = value;
              _formError = null;
            });
          },
        ),
      ),
    );
  }

  Widget _durationToggle(bool disabled) {
    return Row(
      children: [
        Expanded(
          child: _toggleButton(
            'Full Day (1.0)',
            !_isHalfDay,
            disabled ? null : () => _setHalfDay(false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _toggleButton(
            'Half Day (0.5)',
            _isHalfDay,
            disabled ? null : () => _setHalfDay(true),
          ),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback? onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primaryLight : fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? primary : border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? primary : textMedium,
          ),
        ),
      ),
    );
  }

  Widget _dateField(DateTime value, VoidCallback? onTap) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                EmpLeaveFormat.input(value),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: enabled ? textDark : textLight,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: enabled ? textMedium : textLight,
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _reasonField(bool disabled) {
    return TextField(
      controller: _reasonController,
      enabled: !disabled,
      minLines: 4,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 14.5, color: textDark),
      onChanged: (_) {
        if (_reasonError != null || _formError != null) {
          setState(() {
            _reasonError = null;
            _formError = null;
          });
        }
      },
      decoration: InputDecoration(
        hintText:
        'Please explain the reason for your leave request (e.g. personal work, medical rest, family function)...',
        hintStyle: const TextStyle(fontSize: 13.5, color: textLight),
        filled: true,
        fillColor: fill,
        errorText: _reasonError,
        contentPadding: const EdgeInsets.all(14),
        border: _inputBorder(border),
        enabledBorder: _inputBorder(border),
        disabledBorder: _inputBorder(border),
        focusedBorder: _inputBorder(primary, 1.4),
        errorBorder: _inputBorder(danger),
        focusedErrorBorder: _inputBorder(danger, 1.4),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBar(bool wide, bool disabled) {
    final days =
    _isRangeValid ? EmpLeaveTypeHelper.formatDays(_totalDays) : '—';

    final total = Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        children: [
          const TextSpan(text: 'Total Duration: '),
          TextSpan(
            text: '$days Day(s)',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: _isHalfDay ? ' (Half Day Request)' : ' (Full Day Request)',
          ),
        ],
      ),
    );

    final button = SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: disabled ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: disabled
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        )
            : const Text(
          'Submit Leave Request',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: wide
          ? Row(
        children: [
          Expanded(child: total),
          const SizedBox(width: 12),
          button,
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [total, const SizedBox(height: 12), button],
      ),
    );
  }
}