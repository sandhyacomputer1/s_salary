import 'package:flutter/material.dart';

import '../models/company_settings_model.dart';
import 'settings_common.dart';

// =================================================================
// LATE ATTENDANCE RULES
// =================================================================

class SettingsLateTab extends StatelessWidget {
  const SettingsLateTab({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  final CompanySettings settings;
  final VoidCallback onChanged;
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  CompanySettings get _s => settings;

  @override
  Widget build(BuildContext context) {
    final n = _s.lateThreshold;
    final days = showNumber(_s.lateDeductionDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsNote(
          title: '$n-Late Attendance Penalty Rule',
          text:
              'Automatically tracks employee late check-ins in the monthly '
              'attendance log. When an employee reaches the set threshold '
              '(currently $n lates), the system deducts the specified daily '
              'rate penalty from the payable monthly total.',
        ),
        const SizedBox(height: 16),
        SettingsCheckTile(
          label: 'Enable Automated Late Check-In Salary Deduction Rule',
          value: _s.lateEnabled,
          onChanged: (v) {
            _s.lateEnabled = v;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsLabeled(
                label: 'Late Check-In Threshold Count',
                helper: 'Every $n late check-ins triggers a penalty cut.',
                child: SettingsTextField(
                  initialValue: '${_s.lateThreshold}',
                  enabled: _s.lateEnabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: SettingsTextField.digits,
                  onChanged: (v) {
                    _s.lateThreshold = parseInt(v);
                    onChanged();
                  },
                ),
              ),
              const SizedBox(height: 16),
              SettingsLabeled(
                label: 'Salary Deduction Amount (in Days Salary Cut)',
                helper: '$days day salary cut for every $n late occurrences.',
                child: SettingsTextField(
                  initialValue: showNumber(_s.lateDeductionDays),
                  enabled: _s.lateEnabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: SettingsTextField.decimals,
                  onChanged: (v) {
                    _s.lateDeductionDays = parseDouble(v);
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ),
        SettingsSaveBar(dirty: dirty, saving: saving, onSave: onSave),
      ],
    );
  }
}

// =================================================================
// PROFESSIONAL TAX (PT) SLABS
// =================================================================

class SettingsPtTab extends StatelessWidget {
  const SettingsPtTab({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  final CompanySettings settings;
  final VoidCallback onChanged;
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  static const double _tableMinWidth = 760;

  CompanySettings get _s => settings;

  void _addSlab() {
    // Starts above the previous slab so the new row doesn't overlap it.
    final next = _s.ptSlabs.isEmpty ? 0.0 : _s.ptSlabs.last.maxSalary + 1;

    _s.ptSlabs.add(PtSlab(minSalary: next, maxSalary: next, ptAmount: 0));
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsNote(
          tone: SettingsNoteTone.blue,
          title: 'Professional Tax (PT) Calculation Engine',
          text:
              'Calculates state-mandated PT tax cuts directly from monthly '
              'gross salary during payroll generation.',
        ),
        const SizedBox(height: 16),
        SettingsCheckTile(
          label: 'Enable Automated Professional Tax (PT) Calculation',
          value: _s.ptEnabled,
          onChanged: (v) {
            _s.ptEnabled = v;
            onChanged();
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'PT Salary Tax Slabs Table',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kSetTextDark,
                ),
              ),
            ),
            SettingsOutlineButton(
              label: 'Add Slab',
              onPressed: _s.ptEnabled ? _addSlab : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _table(),
        SettingsSaveBar(dirty: dirty, saving: saving, onSave: onSave),
      ],
    );
  }

  Widget _table() {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: Color(0xFF7B8493),
    );

    Widget head(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text, style: headerStyle),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < _tableMinWidth
            ? _tableMinWidth
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      head('MIN SALARY (₹)', 3),
                      head('MAX SALARY (₹)', 3),
                      head('MONTHLY PT AMOUNT (₹)', 3),
                      head('FEB SPECIAL PT AMOUNT (₹)', 3),
                      const SizedBox(width: 56),
                    ],
                  ),
                ),
                if (_s.ptSlabs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'No PT slabs configured.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else
                  for (final slab in _s.ptSlabs) _slabRow(slab),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _slabRow(PtSlab slab) {
    Widget cell(Widget child) => Expanded(
      flex: 3,
      child: Padding(padding: const EdgeInsets.only(right: 10), child: child),
    );

    Widget number({
      required String initial,
      required ValueChanged<String> onText,
      String? hint,
    }) => SettingsTextField(
      initialValue: initial,
      hint: hint,
      enabled: _s.ptEnabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: SettingsTextField.decimals,
      onChanged: onText,
    );

    return Container(
      key: ObjectKey(slab),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          cell(
            number(
              initial: showNumber(slab.minSalary),
              onText: (v) {
                slab.minSalary = parseDouble(v);
                onChanged();
              },
            ),
          ),
          cell(
            number(
              initial: showNumber(slab.maxSalary),
              onText: (v) {
                slab.maxSalary = parseDouble(v);
                onChanged();
              },
            ),
          ),
          cell(
            number(
              initial: showNumber(slab.ptAmount),
              onText: (v) {
                slab.ptAmount = parseDouble(v);
                onChanged();
              },
            ),
          ),
          cell(
            number(
              initial: slab.febAmount == null
                  ? ''
                  : showNumber(slab.febAmount!),
              hint: 'Default',
              onText: (v) {
                slab.febAmount = v.trim().isEmpty ? null : parseDouble(v);
                onChanged();
              },
            ),
          ),
          SizedBox(
            width: 56,
            child: IconButton(
              tooltip: 'Remove slab',
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: _s.ptEnabled
                  ? () {
                      _s.ptSlabs.remove(slab);
                      onChanged();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
