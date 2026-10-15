import 'package:flutter/material.dart';

import '../models/company_settings_model.dart';
import 'settings_common.dart';

/// "Shift & Work Timings" tab: shift times, grace, minimum hours, missed
/// check-out rule, check-in options and the week-off rule.
class SettingsShiftTab extends StatelessWidget {
  const SettingsShiftTab({
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

  static String _ordinal(int n) {
    switch (n) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${n}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsRow(
          children: [
            SettingsLabeled(
              label: 'Shift Start (HH:MM)',
              child: SettingsTimeField(
                value: _s.startTime,
                onChanged: (v) {
                  _s.startTime = v;
                  onChanged();
                },
              ),
            ),
            SettingsLabeled(
              label: 'Shift End (HH:MM)',
              child: SettingsTimeField(
                value: _s.endTime,
                onChanged: (v) {
                  _s.endTime = v;
                  onChanged();
                },
              ),
            ),
            SettingsLabeled(
              label: 'Grace Minutes',
              child: SettingsTextField(
                initialValue: '${_s.graceMinutes}',
                keyboardType: TextInputType.number,
                inputFormatters: SettingsTextField.digits,
                onChanged: (v) {
                  _s.graceMinutes = parseInt(v);
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsRow(
          children: [
            SettingsLabeled(
              label: 'Minimum Hours for Full-Day',
              child: SettingsTextField(
                initialValue: showNumber(_s.minFullDayHours),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: SettingsTextField.decimals,
                onChanged: (v) {
                  _s.minFullDayHours = parseDouble(v);
                  onChanged();
                },
              ),
            ),
            SettingsLabeled(
              label: 'Minimum Hours for Half-Day',
              child: SettingsTextField(
                initialValue: showNumber(_s.minHalfDayHours),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: SettingsTextField.decimals,
                onChanged: (v) {
                  _s.minHalfDayHours = parseDouble(v);
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _missedCheckOut(),
        const SizedBox(height: 14),
        _checkInOptions(),
        const SizedBox(height: 18),
        const Divider(height: 1, color: Color(0xFFEDEFF3)),
        const SizedBox(height: 16),
        _weekOff(),
        SettingsSaveBar(dirty: dirty, saving: saving, onSave: onSave),
      ],
    );
  }

  // ==========================================================
  // MISSED CHECK-OUT RULE
  // ==========================================================

  Widget _missedCheckOut() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'If Employee Forgot Check-Out (Missed Check-Out Rule)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: kSetTextDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select how the system automatically calculates daily attendance '
            'status when an employee checks in but fails to check out before '
            'day end.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _ruleCard(
                  value: MissedCheckOutRule.halfDay,
                  title: 'Count as Half Day (Recommended)',
                  subtitle:
                      'Deducts half-day credit automatically to '
                      'encourage timely check-out.',
                ),
                _ruleCard(
                  value: MissedCheckOutRule.fullDay,
                  title: 'Count as Full Day (Present)',
                  subtitle:
                      'Grants full day attendance even if check-out '
                      'timestamp is missing.',
                ),
              ];

              if (constraints.maxWidth >= 560) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                );
              }

              return Column(
                children: [cards[0], const SizedBox(height: 10), cards[1]],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _ruleCard({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final selected = _s.missedCheckOutRule == value;

    return InkWell(
      onTap: () {
        _s.missedCheckOutRule = value;
        onChanged();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4EE) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? kSetPrimary : kSetBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 19,
                color: selected ? kSetPrimary : kSetMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? kSetPrimary : kSetTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CHECK-IN OPTIONS
  // ==========================================================

  Widget _checkInOptions() {
    final tiles = [
      SettingsCheckTile(
        label: 'Allow multiple check-in per day',
        value: _s.allowMultipleCheckIn,
        onChanged: (v) {
          _s.allowMultipleCheckIn = v;
          onChanged();
        },
      ),
      SettingsCheckTile(
        label: 'Require photo selfie on check-in',
        value: _s.requirePhotoOnCheckIn,
        onChanged: (v) {
          _s.requirePhotoOnCheckIn = v;
          onChanged();
        },
      ),
      SettingsCheckTile(
        label: 'Require photo selfie on check-out',
        value: _s.requirePhotoOnCheckOut,
        onChanged: (v) {
          _s.requirePhotoOnCheckOut = v;
          onChanged();
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }

  // ==========================================================
  // WEEK-OFF RULE
  // ==========================================================

  Widget _weekOff() {
    final showFixed = _s.weekOffType != WeekOffType.nthWeekday;
    final showNth = _s.weekOffType != WeekOffType.fixedDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsLabeled(
          label: 'Week-Off Rule Configuration',
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _dropdown<String>(
              value: WeekOffType.all.contains(_s.weekOffType)
                  ? _s.weekOffType
                  : WeekOffType.fixedDays,
              items: {
                for (final type in WeekOffType.all)
                  type: WeekOffType.label(type),
              },
              onChanged: (v) {
                _s.weekOffType = v;
                onChanged();
              },
            ),
          ),
        ),
        if (showFixed) ...[
          const SizedBox(height: 12),
          Text(
            'Select weekly off days:',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final day in kWeekDays)
                FilterChip(
                  label: Text(day),
                  selected: _s.fixedDays.contains(day),
                  showCheckmark: false,
                  selectedColor: const Color(0xFFFFEEE7),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: _s.fixedDays.contains(day)
                        ? kSetPrimary
                        : kSetBorder,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    color: _s.fixedDays.contains(day)
                        ? kSetPrimary
                        : kSetTextDark,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      _s.fixedDays.add(day);
                      _s.fixedDays.sort(
                        (a, b) => kWeekDays
                            .indexOf(a)
                            .compareTo(kWeekDays.indexOf(b)),
                      );
                    } else {
                      _s.fixedDays.remove(day);
                    }
                    onChanged();
                  },
                ),
            ],
          ),
        ],
        if (showNth) ...[
          const SizedBox(height: 14),
          Text(
            'Nth weekday off (e.g. every 2nd Friday):',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          for (final rule in _s.nthRules)
            Padding(
              key: ObjectKey(rule),
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: _dropdown<int>(
                      value: rule.nth < 1 ? 1 : (rule.nth > 5 ? 5 : rule.nth),
                      items: {for (var n = 1; n <= 5; n++) n: _ordinal(n)},
                      onChanged: (v) {
                        rule.nth = v;
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdown<String>(
                      value: kWeekDays.contains(rule.day)
                          ? rule.day
                          : kWeekDays.first,
                      items: {for (final d in kWeekDays) d: d},
                      onChanged: (v) {
                        rule.day = v;
                        onChanged();
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove rule',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _s.nthRules.remove(rule);
                      onChanged();
                    },
                  ),
                ],
              ),
            ),
          SettingsOutlineButton(
            label: 'Add rule',
            onPressed: () {
              _s.nthRules.add(NthWeekdayRule(nth: 1, day: 'Monday'));
              onChanged();
            },
          ),
        ],
      ],
    );
  }

  Widget _dropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return InputDecorator(
      decoration: settingsDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(fontSize: 14, color: kSetTextDark),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: [
            for (final entry in items.entries)
              DropdownMenuItem<T>(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }
}
