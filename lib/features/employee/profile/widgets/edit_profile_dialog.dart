// lib/features/employee/profile/widgets/edit_profile_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_profile_details_model.dart';
import '../models/employee_profile_model.dart';
import '../repositories/employee_profile_repository.dart';
import '../utils/profile_colors.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final EmployeeProfileModel profile;
  final int initialTab;

  const EditProfileDialog({
    super.key,
    required this.profile,
    this.initialTab = 0,
  });

  @override
  ConsumerState<EditProfileDialog> createState() =>
      _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _phone;
  late final TextEditingController _dob;
  late final TextEditingController _bloodGroup;
  late final TextEditingController _emergency;
  late final TextEditingController _address;
  late final TextEditingController _bankName;
  late final TextEditingController _accountNumber;
  late final TextEditingController _ifsc;
  late final TextEditingController _upi;

  String _gender = 'male';
  String _marital = 'single';

  static const _genders = ['male', 'female', 'other'];
  static const _maritals = ['single', 'married', 'other'];

  @override
  void initState() {
    super.initState();
    final u = widget.profile.user;
    final p = widget.profile.employee.personalDetails;
    final b = widget.profile.employee.bankDetails;

    _phone = TextEditingController(text: u.phone);
    _dob = TextEditingController(text: p.dob);
    _bloodGroup = TextEditingController(text: p.bloodGroup);
    _emergency = TextEditingController(text: p.emergencyContact);
    _address = TextEditingController(text: p.address);
    _bankName = TextEditingController(text: b.bankName);
    _accountNumber = TextEditingController(text: b.accountNumber);
    _ifsc = TextEditingController(text: b.ifsc);
    _upi = TextEditingController(text: b.upiId);

    _gender = _genders.contains(p.gender.toLowerCase())
        ? p.gender.toLowerCase()
        : 'male';
    _marital = _maritals.contains(p.maritalStatus.toLowerCase())
        ? p.maritalStatus.toLowerCase()
        : 'single';
  }

  @override
  void dispose() {
    _phone.dispose();
    _dob.dispose();
    _bloodGroup.dispose();
    _emergency.dispose();
    _address.dispose();
    _bankName.dispose();
    _accountNumber.dispose();
    _ifsc.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final personal = PersonalDetails(
      dob: _dob.text.trim(),
      gender: _gender,
      maritalStatus: _marital,
      bloodGroup: _bloodGroup.text.trim(),
      address: _address.text.trim(),
      emergencyContact: _emergency.text.trim(),
    );

    final bank = BankDetails(
      accountNumber: _accountNumber.text.trim(),
      ifsc: _ifsc.text.trim().toUpperCase(),
      bankName: _bankName.text.trim(),
      upiId: _upi.text.trim(),
    );

    final ok = await ref
        .read(profileUpdateControllerProvider.notifier)
        .save(
      employeeDocId: widget.profile.employeeDocId,
      personal: personal,
      bank: bank,
      phone: _phone.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } else {
      final err = ref.read(profileUpdateControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err?.toString().replaceFirst('Exception: ', '') ??
                'Failed to update profile.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileUpdateControllerProvider).isLoading;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profile & Bank Details',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: ProfileColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Update your contact, emergency, and bank account information',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: ProfileColors.textLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: ProfileColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: ProfileColors.textMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ProfileColors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'PERSONAL & EMERGENCY DETAILS',
                        style: ProfileColors.sectionHeaderStyle,
                      ),
                      const SizedBox(height: 16),
                      _two(
                        _text(_phone, 'Phone Number',
                            keyboard: TextInputType.phone),
                        _text(_dob, 'Date of Birth',
                            hint: 'DD-MM-YYYY',
                            keyboard: TextInputType.datetime),
                      ),
                      const SizedBox(height: 14),
                      _two(
                        _dropdown('Gender', _gender, _genders,
                                (v) => setState(() => _gender = v!)),
                        _dropdown('Marital Status', _marital, _maritals,
                                (v) => setState(() => _marital = v!)),
                      ),
                      const SizedBox(height: 14),
                      _two(
                        _text(_bloodGroup, 'Blood Group',
                            hint: 'e.g. O+, A+, B+'),
                        _text(_emergency, 'Emergency Contact (Name & Phone)',
                            keyboard: TextInputType.phone),
                      ),
                      const SizedBox(height: 14),
                      _text(_address, 'Residential Address',
                          maxLines: 3),
                      const SizedBox(height: 22),
                      const Text(
                        'BANK ACCOUNT & IFSC DETAILS',
                        style: ProfileColors.sectionHeaderStyle,
                      ),
                      const SizedBox(height: 16),
                      _two(
                        _text(_bankName, 'Bank Name',
                            hint: 'e.g. HDFC Bank, SBI, ICICI'),
                        _text(_accountNumber, 'Bank Account Number',
                            hint: 'e.g. 50100012345678',
                            keyboard: TextInputType.number),
                      ),
                      const SizedBox(height: 14),
                      _two(
                        _text(_ifsc, 'IFSC Code',
                            hint: 'e.g. HDFC0001234',
                            textCapitalization:
                            TextCapitalization.characters),
                        _text(_upi, 'UPI ID',
                            hint: 'e.g. name@upi or name@okaxis'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: ProfileColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: ProfileColors.surfaceAlt,
                      foregroundColor: ProfileColors.textMedium,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: ProfileColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Save Profile Changes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _two(Widget a, Widget b) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 480) {
          return Column(
            children: [a, const SizedBox(height: 14), b],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 14),
            Expanded(child: b),
          ],
        );
      },
    );
  }

  Widget _text(
      TextEditingController c,
      String label, {
        String? hint,
        TextInputType keyboard = TextInputType.text,
        TextCapitalization textCapitalization = TextCapitalization.none,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ProfileColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          keyboardType: keyboard,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ProfileColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ProfileColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: ProfileColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
      String label,
      String value,
      List<String> items,
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ProfileColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ProfileColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ProfileColors.border),
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e[0].toUpperCase() + e.substring(1)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}