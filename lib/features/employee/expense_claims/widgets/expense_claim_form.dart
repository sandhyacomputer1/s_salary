import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/expense_colors.dart';
import '../utils/expense_formatters.dart';

typedef ExpenseClaimSubmitCallback = Future<bool> Function({
required String category,
required double amount,
required DateTime expenseDate,
required String description,
String? billUrl,
});

class ExpenseClaimForm extends StatefulWidget {
  final bool isSubmitting;

  /// Must return true only when the server confirmed the claim.
  final ExpenseClaimSubmitCallback onSubmit;

  const ExpenseClaimForm({
    super.key,
    required this.isSubmitting,
    required this.onSubmit,
  });

  /// ⚠️ Confirm these strings against the web app / Postman.
  static const List<String> categories = [
    'Travel / Transport / Fuel',
    'Food',
    'Supplies',
    'Medical',
    'Other',
  ];

  @override
  State<ExpenseClaimForm> createState() => _ExpenseClaimFormState();
}

class _ExpenseClaimFormState extends State<ExpenseClaimForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _billController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _category;
  DateTime? _expenseDate;

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _billController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate ?? now,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _expenseDate = picked;
        _dateController.text = ExpenseFormatters.instantDate(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (widget.isSubmitting) return; // block duplicate taps
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final bill = _billController.text.trim();

    final ok = await widget.onSubmit(
      category: _category!,
      amount: amount,
      expenseDate: _expenseDate!,
      description: _descriptionController.text.trim(),
      billUrl: bill.isEmpty ? null : bill,
    );

    if (ok && mounted) {
      _formKey.currentState!.reset();
      _amountController.clear();
      _dateController.clear();
      _billController.clear();
      _descriptionController.clear();
      setState(() {
        _category = null;
        _expenseDate = null;
      });
    }
  }

  InputDecoration _decoration(String label, {String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ExpenseColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ExpenseColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ExpenseColors.primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isSubmitting;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            isExpanded: true,
            decoration: _decoration('Expense Category *'),
            items: ExpenseClaimForm.categories
                .map((c) => DropdownMenuItem(
              value: c,
              child: Text(c, overflow: TextOverflow.ellipsis),
            ))
                .toList(),
            onChanged: disabled ? null : (v) => setState(() => _category = v),
            validator: (v) => v == null ? 'Please select a category' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            enabled: !disabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: _decoration('Claim Amount (₹) *', hint: 'e.g. 1250.50'),
            validator: (v) {
              final value = double.tryParse((v ?? '').trim());
              if (value == null) return 'Enter the claim amount';
              if (value <= 0) return 'Amount must be greater than zero';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dateController,
            readOnly: true,
            enabled: !disabled,
            onTap: _pickDate,
            decoration: _decoration(
              'Expense Date *',
              hint: 'Select date',
              suffix: const Icon(Icons.calendar_today_outlined, size: 20),
            ),
            validator: (v) =>
            (_expenseDate == null) ? 'Please select the expense date' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _billController,
            enabled: !disabled,
            keyboardType: TextInputType.url,
            decoration: _decoration(
              'Bill / Receipt URL (optional)',
              hint: 'https://...',
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return null;
              final uri = Uri.tryParse(value);
              final valid = uri != null &&
                  (uri.scheme == 'http' || uri.scheme == 'https') &&
                  uri.host.isNotEmpty;
              return valid ? null : 'Enter a valid http(s) link';
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            enabled: !disabled,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(
              'Detailed Expense Description *',
              hint: 'What was this expense for?',
            ),
            validator: (v) => (v ?? '').trim().isEmpty
                ? 'Please describe the expense'
                : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ExpenseColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: disabled ? null : _submit,
            child: disabled
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
                : const Text(
              'Submit Claim',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}