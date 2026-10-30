import 'package:flutter/material.dart';
import 'admin_employee_theme.dart';

/// Shared look for the small employee dialogs (Access, Salary).
InputDecoration adminEmpInput(String hint, {Widget? suffix}) {
  OutlineInputBorder b(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
    isDense: true,
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: b(AdminEmpColors.border),
    focusedBorder: b(AdminEmpColors.primary),
    errorBorder: b(AdminEmpColors.danger),
    focusedErrorBorder: b(AdminEmpColors.danger),
  );
}

Widget adminEmpLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AdminEmpColors.text,
    ),
  ),
);

/// Dialog header: title + close button.
Widget adminEmpDialogTitle(String title, VoidCallback? onClose) => Padding(
  padding: const EdgeInsets.fromLTRB(26, 22, 12, 8),
  child: Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AdminEmpColors.text,
          ),
        ),
      ),
      IconButton(
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded, color: AdminEmpColors.muted),
      ),
    ],
  ),
);

ButtonStyle adminEmpPrimaryButton() => ElevatedButton.styleFrom(
  minimumSize: const Size(0, 46),
  backgroundColor: AdminEmpColors.primary,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 22),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

ButtonStyle adminEmpOutlineButton() => OutlinedButton.styleFrom(
  minimumSize: const Size(0, 46),
  foregroundColor: AdminEmpColors.text,
  side: const BorderSide(color: AdminEmpColors.border),
  padding: const EdgeInsets.symmetric(horizontal: 22),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

Widget adminEmpErrorBox(String message) => Container(
  width: double.infinity,
  margin: const EdgeInsets.only(bottom: 12),
  padding: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: AdminEmpColors.dangerSoft,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    message,
    style: const TextStyle(color: AdminEmpColors.danger, fontSize: 13),
  ),
);