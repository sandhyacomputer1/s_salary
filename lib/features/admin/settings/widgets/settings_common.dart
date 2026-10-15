import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Palette copied from AdminDashboardScreen.
const Color kSetPrimary = Color(0xFFE96832);
const Color kSetTextDark = Color(0xFF18212F);
const Color kSetBorder = Color(0xFFD9DEE7);
const Color kSetMuted = Color(0xFF7A8494);
const Color kSetDanger = Color(0xFFDC2626);

/// Empty or invalid text becomes [fallback]; validation then reports it.
int parseInt(String text, {int fallback = 0}) =>
    int.tryParse(text.trim()) ?? fallback;

double parseDouble(String text, {double fallback = 0}) =>
    double.tryParse(text.trim()) ?? fallback;

/// Whole numbers are shown without ".0" (8.0 -> "8").
String showNumber(num value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

InputDecoration settingsDecoration({String? hint, Widget? suffix}) {
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
    border: outline(kSetBorder),
    enabledBorder: outline(kSetBorder),
    disabledBorder: outline(const Color(0xFFEDEFF3)),
    focusedBorder: outline(kSetPrimary),
  );
}

/// Label above a field, with an optional helper line below it.
class SettingsLabeled extends StatelessWidget {
  const SettingsLabeled({
    super.key,
    required this.label,
    required this.child,
    this.helper,
  });

  final String label;
  final Widget child;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kSetTextDark,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}

/// 2 or 3 fields side by side on wide screens, stacked on narrow ones.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: children[i]),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              children[i],
            ],
          ],
        );
      },
    );
  }
}

/// Text field that edits a model value in place. Its initial text is set once,
/// so the screen rebuilds the tabs with a new key after a reload.
class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  /// Digits only.
  static List<TextInputFormatter> get digits => [
    FilteringTextInputFormatter.digitsOnly,
  ];

  /// Digits and one decimal point.
  static List<TextInputFormatter> get decimals => [
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
  ];

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: kSetTextDark),
      decoration: settingsDecoration(hint: hint),
    );
  }
}

/// Read-only HH:mm field that opens a 24-hour time picker.
class SettingsTimeField extends StatelessWidget {
  const SettingsTimeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    var initial = const TimeOfDay(hour: 9, minute: 0);

    if (RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
      final p = value.split(':');
      initial = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked == null) return;

    onChanged(
      '${picked.hour.toString().padLeft(2, '0')}:'
      '${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: settingsDecoration(
          suffix: const Icon(Icons.access_time_rounded, size: 20),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, color: kSetTextDark),
        ),
      ),
    );
  }
}

/// Grey checkbox row, as in the web Settings screens.
class SettingsCheckTile extends StatelessWidget {
  const SettingsCheckTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: kSetPrimary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kSetTextDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SettingsNoteTone { orange, blue }

/// Tinted explanation box (orange for rules, blue for information).
class SettingsNote extends StatelessWidget {
  const SettingsNote({
    super.key,
    required this.title,
    required this.text,
    this.tone = SettingsNoteTone.orange,
  });

  final String title;
  final String text;
  final SettingsNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final orange = tone == SettingsNoteTone.orange;

    final background = orange
        ? const Color(0xFFFFF4EE)
        : const Color(0xFFEFF6FF);
    final border = orange ? const Color(0xFFF8D4C2) : const Color(0xFFBFDBFE);
    final strong = orange ? const Color(0xFF9A3412) : const Color(0xFF1D4ED8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: TextStyle(fontWeight: FontWeight.w700, color: strong),
            ),
            TextSpan(
              text: text,
              style: TextStyle(color: strong),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 13, height: 1.45),
      ),
    );
  }
}

/// "Save Company Rules & Settings" bar shown at the bottom of every tab.
class SettingsSaveBar extends StatelessWidget {
  const SettingsSaveBar({
    super.key,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  /// True when something on any tab differs from the saved version.
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFEDEFF3)),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 10,
          children: [
            if (dirty && !saving)
              const Text(
                'You have unsaved changes',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB45309),
                ),
              ),
            FilledButton(
              onPressed: (dirty && !saving) ? onSave : null,
              style: FilledButton.styleFrom(
                backgroundColor: kSetPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Company Rules & Settings'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small outlined action button ("+ Add Slab", "+ Add Leave Type", ...).
class SettingsOutlineButton extends StatelessWidget {
  const SettingsOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.add, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: kSetTextDark,
        side: const BorderSide(color: kSetBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
