// // import 'package:flutter/material.dart';
// //
// // import '../../../../data/services/employee_service.dart';
// //
// // class AddEmployeeScreen extends StatefulWidget {
// //   const AddEmployeeScreen({
// //     super.key,
// //   });
// //
// //   @override
// //   State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
// // }
// //
// // class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //
// //   final EmployeeService _employeeService = EmployeeService();
// //
// //   // ==========================================================
// //   // COLORS
// //   // ==========================================================
// //
// //   static const Color primary = Color(0xFFE96832);
// //   static const Color primaryLight = Color(0xFFFFF1EB);
// //   static const Color textDark = Color(0xFF18212F);
// //   static const Color textMedium = Color(0xFF4B5563);
// //   static const Color textLight = Color(0xFF8A93A1);
// //   static const Color border = Color(0xFFD9DEE5);
// //   static const Color divider = Color(0xFFE9ECF0);
// //   static const Color pageBackground = Color(0xFFF7F8FA);
// //   static const Color errorColor = Color(0xFFD32F2F);
// //
// //   // ==========================================================
// //   // CONTROLLERS
// //   // ==========================================================
// //
// //   final TextEditingController _nameController = TextEditingController();
// //   final TextEditingController _emailController = TextEditingController();
// //   final TextEditingController _phoneController = TextEditingController();
// //   final TextEditingController _passwordController = TextEditingController();
// //   final TextEditingController _designationController = TextEditingController();
// //   final TextEditingController _salaryController = TextEditingController();
// //   final TextEditingController _addressController = TextEditingController();
// //   final TextEditingController _emergencyPhoneController =
// //   TextEditingController();
// //   final TextEditingController _emergencyNameController =
// //   TextEditingController();
// //   final TextEditingController _emergencyRelationshipController =
// //   TextEditingController();
// //   final TextEditingController _accountNumberController =
// //   TextEditingController();
// //   final TextEditingController _ifscController = TextEditingController();
// //   final TextEditingController _bankNameController = TextEditingController();
// //   final TextEditingController _upiController = TextEditingController();
// //
// //   // ==========================================================
// //   // DROPDOWNS
// //   // ==========================================================
// //
// //   String? _department;
// //   String? _employmentType;
// //   String? _workMode;
// //   String? _adminRole;
// //   String _gender = 'Male';
// //
// //   // ==========================================================
// //   // DATES
// //   // ==========================================================
// //
// //   DateTime? _dateOfJoining;
// //   DateTime? _dateOfBirth;
// //
// //   // ==========================================================
// //   // DEPARTMENTS
// //   // ==========================================================
// //
// //   List<String> _departments = [];
// //   bool _isLoadingDepartments = true;
// //
// //   // ==========================================================
// //   // PASSWORD
// //   // ==========================================================
// //
// //   bool _obscurePassword = true;
// //
// //   // ==========================================================
// //   // SAVE STATE
// //   // ==========================================================
// //
// //   bool _isSaving = false;
// //
// //   // ==========================================================
// //   // INIT
// //   // ==========================================================
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //
// //     _loadDepartments();
// //   }
// //
// //   // ==========================================================
// //   // LOAD DEPARTMENTS
// //   // ==========================================================
// //
// //   Future<void> _loadDepartments() async {
// //     try {
// //       final response = await _employeeService.getDepartments();
// //
// //       final departments = <String>[];
// //
// //       if (response is List) {
// //         for (final item in response) {
// //           if (item is Map) {
// //             final name = item['name']?.toString().trim() ?? '';
// //
// //             if (name.isNotEmpty && !departments.contains(name)) {
// //               departments.add(name);
// //             }
// //           }
// //         }
// //       }
// //
// //       if (!mounted) {
// //         return;
// //       }
// //
// //       setState(() {
// //         _departments = departments;
// //         _isLoadingDepartments = false;
// //       });
// //     } catch (e) {
// //       debugPrint('DEPARTMENT LOAD ERROR: $e');
// //
// //       if (!mounted) {
// //         return;
// //       }
// //
// //       setState(() {
// //         _isLoadingDepartments = false;
// //       });
// //
// //       _showMessage('Unable to load departments.');
// //     }
// //   }
// //
// //   // ==========================================================
// //   // SAVE EMPLOYEE
// //   // ==========================================================
// //
// //   Future<void> _saveEmployee() async {
// //     if (!_formKey.currentState!.validate()) {
// //       return;
// //     }
// //
// //     if (_department == null || _department!.isEmpty) {
// //       _showMessage('Please select department.');
// //       return;
// //     }
// //
// //     if (_employmentType == null || _employmentType!.isEmpty) {
// //       _showMessage('Please select employment type.');
// //       return;
// //     }
// //
// //     if (_workMode == null || _workMode!.isEmpty) {
// //       _showMessage('Please select work mode.');
// //       return;
// //     }
// //
// //     if (_dateOfJoining == null) {
// //       _showMessage('Please select date of joining.');
// //       return;
// //     }
// //
// //     final salary = double.tryParse(
// //       _salaryController.text.trim(),
// //     );
// //
// //     if (salary == null) {
// //       _showMessage('Please enter a valid monthly salary.');
// //       return;
// //     }
// //
// //     setState(() {
// //       _isSaving = true;
// //     });
// //
// //     try {
// //       // ======================================================
// //       // DOCUMENTED POST /employees PAYLOAD
// //       // ======================================================
// //
// //       final response = await _employeeService.createEmployee(
// //         name: _nameController.text.trim(),
// //         email: _emailController.text.trim(),
// //         phone: _phoneController.text.trim(),
// //         password: _passwordController.text,
// //         designation: _designationController.text.trim(),
// //         department: _department!,
// //         monthlySalary: salary,
// //         employmentType: _employmentType!,
// //         workMode: _workMode!,
// //         accountNumber: _accountNumberController.text.trim(),
// //         ifsc: _ifscController.text.trim(),
// //         bankName: _bankNameController.text.trim(),
// //         upiId: _upiController.text.trim(),
// //       );
// //
// //       // ======================================================
// //       // EMPLOYEE CREATED
// //       // ======================================================
// //
// //       if (!mounted) {
// //         return;
// //       }
// //
// //       setState(() {
// //         _isSaving = false;
// //       });
// //
// //       final employee = response['employee'];
// //
// //       final tempPassword = response['tempPassword']?.toString();
// //
// //       await _showSuccessDialog(
// //         employee: employee,
// //         tempPassword: tempPassword,
// //       );
// //
// //       if (!mounted) {
// //         return;
// //       }
// //
// //       Navigator.pop(context, true);
// //     } catch (e) {
// //       if (!mounted) {
// //         return;
// //       }
// //
// //       setState(() {
// //         _isSaving = false;
// //       });
// //
// //       _showMessage(
// //         e.toString().replaceFirst('Exception: ', ''),
// //       );
// //     }
// //   }
// //
// //   // ==========================================================
// //   // SUCCESS DIALOG
// //   // ==========================================================
// //
// //   Future<void> _showSuccessDialog({
// //     dynamic employee,
// //     String? tempPassword,
// //   }) async {
// //     String employeeName = '';
// //     String employeeEmail = '';
// //
// //     if (employee is Map) {
// //       employeeName = employee['name']?.toString() ?? '';
// //       employeeEmail = employee['email']?.toString() ?? '';
// //     }
// //
// //     await showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) {
// //         return AlertDialog(
// //           backgroundColor: Colors.white,
// //           shape: RoundedRectangleBorder(
// //             borderRadius: BorderRadius.circular(14),
// //           ),
// //           title: Row(
// //             children: [
// //               Container(
// //                 width: 38,
// //                 height: 38,
// //                 decoration: BoxDecoration(
// //                   color: const Color(0xFFE9F8EF),
// //                   borderRadius: BorderRadius.circular(10),
// //                 ),
// //                 child: const Icon(
// //                   Icons.check_rounded,
// //                   color: Color(0xFF18864B),
// //                 ),
// //               ),
// //               const SizedBox(width: 12),
// //               const Text(
// //                 'Employee Created',
// //                 style: TextStyle(
// //                   fontSize: 17,
// //                   fontWeight: FontWeight.w700,
// //                   color: textDark,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           content: SizedBox(
// //             width: 340,
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 if (employeeName.isNotEmpty)
// //                   Text(
// //                     employeeName,
// //                     style: const TextStyle(
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.w700,
// //                       color: textDark,
// //                     ),
// //                   ),
// //                 if (employeeEmail.isNotEmpty)
// //                   Padding(
// //                     padding: const EdgeInsets.only(top: 4),
// //                     child: Text(
// //                       employeeEmail,
// //                       style: const TextStyle(
// //                         fontSize: 13,
// //                         color: textMedium,
// //                       ),
// //                     ),
// //                   ),
// //                 if (tempPassword != null && tempPassword.isNotEmpty) ...[
// //                   const SizedBox(height: 18),
// //                   const Text(
// //                     'TEMPORARY PASSWORD',
// //                     style: TextStyle(
// //                       fontSize: 11,
// //                       fontWeight: FontWeight.w700,
// //                       letterSpacing: 0.5,
// //                       color: textLight,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Container(
// //                     width: double.infinity,
// //                     padding: const EdgeInsets.all(12),
// //                     decoration: BoxDecoration(
// //                       color: pageBackground,
// //                       borderRadius: BorderRadius.circular(8),
// //                       border: Border.all(color: border),
// //                     ),
// //                     child: SelectableText(
// //                       tempPassword,
// //                       style: const TextStyle(
// //                         fontSize: 16,
// //                         fontWeight: FontWeight.w700,
// //                         color: textDark,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ],
// //             ),
// //           ),
// //           actions: [
// //             FilledButton(
// //               onPressed: () {
// //                 Navigator.pop(context);
// //               },
// //               style: FilledButton.styleFrom(
// //                 backgroundColor: primary,
// //                 foregroundColor: Colors.white,
// //                 shape: RoundedRectangleBorder(
// //                   borderRadius: BorderRadius.circular(8),
// //                 ),
// //               ),
// //               child: const Text('Done'),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   // ==========================================================
// //   // DATE PICKERS
// //   // ==========================================================
// //
// //   Widget _pickerTheme(BuildContext context, Widget? child) {
// //     return Theme(
// //       data: Theme.of(context).copyWith(
// //         colorScheme: Theme.of(context).colorScheme.copyWith(
// //           primary: primary,
// //         ),
// //       ),
// //       child: child!,
// //     );
// //   }
// //
// //   Future<void> _selectDateOfJoining() async {
// //     final selected = await showDatePicker(
// //       context: context,
// //       initialDate: _dateOfJoining ?? DateTime.now(),
// //       firstDate: DateTime(2000),
// //       lastDate: DateTime(2100),
// //       builder: _pickerTheme,
// //     );
// //
// //     if (selected != null) {
// //       setState(() {
// //         _dateOfJoining = selected;
// //       });
// //     }
// //   }
// //
// //   Future<void> _selectDateOfBirth() async {
// //     final selected = await showDatePicker(
// //       context: context,
// //       initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
// //       firstDate: DateTime(1950),
// //       lastDate: DateTime.now(),
// //       builder: _pickerTheme,
// //     );
// //
// //     if (selected != null) {
// //       setState(() {
// //         _dateOfBirth = selected;
// //       });
// //     }
// //   }
// //
// //   // ==========================================================
// //   // DATE FORMAT
// //   // ==========================================================
// //
// //   String _formatDate(DateTime? date) {
// //     if (date == null) {
// //       return '';
// //     }
// //
// //     return '${date.day.toString().padLeft(2, '0')}-'
// //         '${date.month.toString().padLeft(2, '0')}-'
// //         '${date.year}';
// //   }
// //
// //   // ==========================================================
// //   // INPUT DECORATION
// //   // ==========================================================
// //
// //   OutlineInputBorder _outline(Color color, [double width = 1]) {
// //     return OutlineInputBorder(
// //       borderRadius: BorderRadius.circular(6),
// //       borderSide: BorderSide(color: color, width: width),
// //     );
// //   }
// //
// //   InputDecoration _inputDecoration({
// //     required String hint,
// //     Widget? suffixIcon,
// //   }) {
// //     return InputDecoration(
// //       isDense: true,
// //       hintText: hint,
// //       hintStyle: const TextStyle(
// //         fontSize: 13,
// //         color: textLight,
// //       ),
// //       errorStyle: const TextStyle(
// //         fontSize: 11,
// //         height: 1.1,
// //       ),
// //       suffixIcon: suffixIcon,
// //       suffixIconConstraints: const BoxConstraints(
// //         minWidth: 36,
// //         minHeight: 30,
// //       ),
// //       filled: true,
// //       fillColor: Colors.white,
// //       contentPadding: const EdgeInsets.symmetric(
// //         horizontal: 12,
// //         vertical: 12,
// //       ),
// //       border: _outline(border),
// //       enabledBorder: _outline(border),
// //       focusedBorder: _outline(primary, 1.4),
// //       errorBorder: _outline(errorColor),
// //       focusedErrorBorder: _outline(errorColor, 1.4),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // LABEL ABOVE FIELD
// //   // ==========================================================
// //
// //   Widget _labeled({
// //     required String label,
// //     required Widget child,
// //     bool required = false,
// //     String? helper,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         RichText(
// //           text: TextSpan(
// //             text: label,
// //             style: const TextStyle(
// //               fontSize: 12.5,
// //               fontWeight: FontWeight.w600,
// //               color: textDark,
// //             ),
// //             children: [
// //               if (required)
// //                 const TextSpan(
// //                   text: ' *',
// //                   style: TextStyle(color: errorColor),
// //                 ),
// //             ],
// //           ),
// //         ),
// //         const SizedBox(height: 6),
// //         child,
// //         if (helper != null) ...[
// //           const SizedBox(height: 5),
// //           Text(
// //             helper,
// //             style: const TextStyle(
// //               fontSize: 11,
// //               color: textLight,
// //             ),
// //           ),
// //         ],
// //       ],
// //     );
// //   }
// //
// //   // ==========================================================
// //   // TEXT FIELD
// //   // ==========================================================
// //
// //   Widget _textField({
// //     required String label,
// //     required String hint,
// //     required TextEditingController controller,
// //     TextInputType? keyboardType,
// //     bool obscureText = false,
// //     bool required = false,
// //     Widget? suffixIcon,
// //     int maxLines = 1,
// //   }) {
// //     return _labeled(
// //       label: label,
// //       required: required,
// //       child: TextFormField(
// //         controller: controller,
// //         keyboardType: keyboardType,
// //         obscureText: obscureText,
// //         maxLines: maxLines,
// //         style: const TextStyle(
// //           fontSize: 13.5,
// //           color: textDark,
// //         ),
// //         decoration: _inputDecoration(
// //           hint: hint,
// //           suffixIcon: suffixIcon,
// //         ),
// //         validator: required
// //             ? (value) {
// //           if (value == null || value.trim().isEmpty) {
// //             return '$label is required';
// //           }
// //
// //           return null;
// //         }
// //             : null,
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // DROPDOWN
// //   // ==========================================================
// //
// //   Widget _dropdown({
// //     required String label,
// //     required String? value,
// //     required List<String> items,
// //     required ValueChanged<String?> onChanged,
// //     bool required = true,
// //     String? helper,
// //   }) {
// //     return _labeled(
// //       label: label,
// //       required: required,
// //       helper: helper,
// //       child: DropdownButtonFormField<String>(
// //         value: items.contains(value) ? value : null,
// //         isExpanded: true,
// //         icon: const Icon(
// //           Icons.keyboard_arrow_down_rounded,
// //           size: 20,
// //           color: textMedium,
// //         ),
// //         style: const TextStyle(
// //           fontSize: 13.5,
// //           color: textDark,
// //         ),
// //         hint: const Text(
// //           'Select',
// //           style: TextStyle(
// //             fontSize: 13,
// //             color: textLight,
// //           ),
// //         ),
// //         decoration: _inputDecoration(hint: 'Select'),
// //         items: items.map((item) {
// //           return DropdownMenuItem<String>(
// //             value: item,
// //             child: Text(
// //               _formatValue(item),
// //               overflow: TextOverflow.ellipsis,
// //             ),
// //           );
// //         }).toList(),
// //         onChanged: onChanged,
// //         validator: required
// //             ? (value) {
// //           if (value == null || value.isEmpty) {
// //             return 'Please select $label';
// //           }
// //
// //           return null;
// //         }
// //             : null,
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // DATE FIELD
// //   // ==========================================================
// //
// //   Widget _dateField({
// //     required String label,
// //     required String hint,
// //     required DateTime? value,
// //     required VoidCallback onTap,
// //     bool required = false,
// //   }) {
// //     return FormField<DateTime>(
// //       validator: required
// //           ? (_) {
// //         if (value == null) {
// //           return '$label is required';
// //         }
// //
// //         return null;
// //       }
// //           : null,
// //       builder: (field) {
// //         return _labeled(
// //           label: label,
// //           required: required,
// //           child: InkWell(
// //             onTap: onTap,
// //             borderRadius: BorderRadius.circular(6),
// //             child: InputDecorator(
// //               decoration: _inputDecoration(
// //                 hint: hint,
// //                 suffixIcon: const Icon(
// //                   Icons.calendar_today_outlined,
// //                   size: 16,
// //                   color: textMedium,
// //                 ),
// //               ).copyWith(
// //                 errorText: field.hasError ? field.errorText : null,
// //               ),
// //               child: Text(
// //                 value == null ? hint : _formatDate(value),
// //                 style: TextStyle(
// //                   fontSize: 13.5,
// //                   color: value == null ? textLight : textDark,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         );
// //       },
// //     );
// //   }
// //
// //   // ==========================================================
// //   // LAYOUT HELPERS
// //   // ==========================================================
// //
// //   /// Responsive grid: 4 / 3 / 2 / 1 columns depending on width.
// //   Widget _grid(List<Widget> items) {
// //     return LayoutBuilder(
// //       builder: (context, constraints) {
// //         final width = constraints.maxWidth;
// //
// //         int columns;
// //         if (width >= 1100) {
// //           columns = 4;
// //         } else if (width >= 780) {
// //           columns = 3;
// //         } else if (width >= 500) {
// //           columns = 2;
// //         } else {
// //           columns = 1;
// //         }
// //
// //         const double gap = 20;
// //
// //         final itemWidth = (width - gap * (columns - 1)) / columns;
// //
// //         return Wrap(
// //           spacing: gap,
// //           runSpacing: 16,
// //           children: items.map((item) {
// //             return SizedBox(
// //               width: itemWidth,
// //               child: item,
// //             );
// //           }).toList(),
// //         );
// //       },
// //     );
// //   }
// //
// //   Widget _section({
// //     required String title,
// //     required Widget child,
// //     bool last = false,
// //   }) {
// //     return Padding(
// //       padding: EdgeInsets.only(bottom: last ? 0 : 22),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             children: [
// //               Container(
// //                 width: 3,
// //                 height: 15,
// //                 decoration: BoxDecoration(
// //                   color: primary,
// //                   borderRadius: BorderRadius.circular(2),
// //                 ),
// //               ),
// //               const SizedBox(width: 8),
// //               Text(
// //                 title,
// //                 style: const TextStyle(
// //                   fontSize: 14,
// //                   fontWeight: FontWeight.w700,
// //                   color: textDark,
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 8),
// //           const Divider(height: 1, color: divider),
// //           const SizedBox(height: 14),
// //           child,
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // WORK MODE OPTION
// //   // ==========================================================
// //
// //   Widget _workModeOption({
// //     required String value,
// //     required String title,
// //     required String description,
// //     required IconData icon,
// //   }) {
// //     final selected = _workMode == value;
// //
// //     return InkWell(
// //       onTap: () {
// //         setState(() {
// //           _workMode = value;
// //         });
// //       },
// //       borderRadius: BorderRadius.circular(8),
// //       child: AnimatedContainer(
// //         duration: const Duration(milliseconds: 160),
// //         padding: const EdgeInsets.all(12),
// //         decoration: BoxDecoration(
// //           color: selected ? primaryLight : Colors.white,
// //           borderRadius: BorderRadius.circular(8),
// //           border: Border.all(
// //             color: selected ? primary : border,
// //             width: selected ? 1.4 : 1,
// //           ),
// //         ),
// //         child: Row(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Icon(
// //               icon,
// //               size: 20,
// //               color: selected ? primary : const Color(0xFF64748B),
// //             ),
// //             const SizedBox(width: 10),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     title,
// //                     style: const TextStyle(
// //                       fontSize: 13,
// //                       fontWeight: FontWeight.w700,
// //                       color: textDark,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 2),
// //                   Text(
// //                     description,
// //                     style: const TextStyle(
// //                       fontSize: 11.5,
// //                       height: 1.35,
// //                       color: Color(0xFF64748B),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             const SizedBox(width: 8),
// //             Icon(
// //               selected
// //                   ? Icons.radio_button_checked_rounded
// //                   : Icons.radio_button_unchecked_rounded,
// //               size: 19,
// //               color: selected ? primary : const Color(0xFFB6BDC8),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // BUILD
// //   // ==========================================================
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: Column(
// //         children: [
// //           _buildPageHeader(),
// //           Expanded(
// //             child: Form(
// //               key: _formKey,
// //               child: SingleChildScrollView(
// //                 padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
// //                 child: Center(
// //                   child: ConstrainedBox(
// //                     constraints: const BoxConstraints(maxWidth: 1400),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         _buildAccountSection(),
// //                         _buildJobSection(),
// //                         _buildWorkModeSection(),
// //                         _buildPersonalSection(),
// //                         _buildBankSection(),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ),
// //           _buildFixedFooter(),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // PAGE HEADER
// //   // ==========================================================
// //
// //   Widget _buildPageHeader() {
// //     return Container(
// //       width: double.infinity,
// //       height: 62,
// //       decoration: const BoxDecoration(
// //         color: Colors.white,
// //         border: Border(
// //           bottom: BorderSide(color: border),
// //         ),
// //       ),
// //       child: Padding(
// //         padding: const EdgeInsets.symmetric(horizontal: 16),
// //         child: Row(
// //           children: [
// //             IconButton(
// //               tooltip: 'Back',
// //               onPressed: _isSaving
// //                   ? null
// //                   : () {
// //                 Navigator.pop(context);
// //               },
// //               icon: const Icon(
// //                 Icons.arrow_back_rounded,
// //                 size: 21,
// //                 color: textDark,
// //               ),
// //             ),
// //             const SizedBox(width: 4),
// //             Container(
// //               width: 36,
// //               height: 36,
// //               decoration: BoxDecoration(
// //                 color: primaryLight,
// //                 borderRadius: BorderRadius.circular(10),
// //               ),
// //               child: const Icon(
// //                 Icons.person_add_alt_1_rounded,
// //                 color: primary,
// //                 size: 19,
// //               ),
// //             ),
// //             const SizedBox(width: 12),
// //             const Expanded(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     'Add New Employee',
// //                     maxLines: 1,
// //                     overflow: TextOverflow.ellipsis,
// //                     style: TextStyle(
// //                       fontSize: 17,
// //                       fontWeight: FontWeight.w700,
// //                       color: textDark,
// //                     ),
// //                   ),
// //                   SizedBox(height: 1),
// //                   Text(
// //                     'Create an employee profile and assign work details.',
// //                     maxLines: 1,
// //                     overflow: TextOverflow.ellipsis,
// //                     style: TextStyle(
// //                       fontSize: 11,
// //                       color: textLight,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Container(
// //               padding: const EdgeInsets.symmetric(
// //                 horizontal: 10,
// //                 vertical: 6,
// //               ),
// //               decoration: BoxDecoration(
// //                 color: pageBackground,
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: Border.all(color: border),
// //               ),
// //               child: const Row(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   Icon(
// //                     Icons.admin_panel_settings_outlined,
// //                     size: 15,
// //                     color: textMedium,
// //                   ),
// //                   SizedBox(width: 6),
// //                   Text(
// //                     'Admin',
// //                     style: TextStyle(
// //                       fontSize: 12,
// //                       fontWeight: FontWeight.w600,
// //                       color: textMedium,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // ACCOUNT SECTION
// //   // ==========================================================
// //
// //   Widget _buildAccountSection() {
// //     return _section(
// //       title: 'Account & Basic Info',
// //       child: _grid([
// //         _textField(
// //           label: 'Full Name',
// //           hint: 'e.g. Rahul Sharma',
// //           controller: _nameController,
// //           required: true,
// //         ),
// //         _textField(
// //           label: 'Work Email',
// //           hint: 'rahul@company.com',
// //           controller: _emailController,
// //           keyboardType: TextInputType.emailAddress,
// //           required: true,
// //         ),
// //         _textField(
// //           label: 'Phone Number',
// //           hint: '+91 9876543210',
// //           controller: _phoneController,
// //           keyboardType: TextInputType.phone,
// //           required: true,
// //         ),
// //         _textField(
// //           label: 'Password',
// //           hint: 'Create login password',
// //           controller: _passwordController,
// //           obscureText: _obscurePassword,
// //           required: true,
// //           suffixIcon: IconButton(
// //             splashRadius: 18,
// //             onPressed: () {
// //               setState(() {
// //                 _obscurePassword = !_obscurePassword;
// //               });
// //             },
// //             icon: Icon(
// //               _obscurePassword
// //                   ? Icons.visibility_outlined
// //                   : Icons.visibility_off_outlined,
// //               size: 18,
// //               color: textMedium,
// //             ),
// //           ),
// //         ),
// //       ]),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // JOB SECTION
// //   // ==========================================================
// //
// //   Widget _buildJobSection() {
// //     return _section(
// //       title: 'Job Role & Salary',
// //       child: _grid([
// //         _textField(
// //           label: 'Designation',
// //           hint: 'e.g. Software Engineer',
// //           controller: _designationController,
// //           required: true,
// //         ),
// //         _isLoadingDepartments
// //             ? _loadingField('Department')
// //             : _dropdown(
// //           label: 'Department',
// //           value: _department,
// //           items: _departments,
// //           onChanged: (value) {
// //             setState(() {
// //               _department = value;
// //             });
// //           },
// //         ),
// //         _dropdown(
// //           label: 'Employment Type',
// //           value: _employmentType,
// //           items: const [
// //             'full_time',
// //             'part_time',
// //             'contract',
// //             'intern',
// //           ],
// //           onChanged: (value) {
// //             setState(() {
// //               _employmentType = value;
// //             });
// //           },
// //         ),
// //         _textField(
// //           label: 'Monthly Salary (₹)',
// //           hint: 'e.g. 45000',
// //           controller: _salaryController,
// //           keyboardType: const TextInputType.numberWithOptions(
// //             decimal: true,
// //           ),
// //           required: true,
// //         ),
// //         _dateField(
// //           label: 'Date of Joining',
// //           hint: 'dd-mm-yyyy',
// //           value: _dateOfJoining,
// //           onTap: _selectDateOfJoining,
// //           required: true,
// //         ),
// //       ]),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // WORK MODE SECTION
// //   // ==========================================================
// //
// //   Widget _buildWorkModeSection() {
// //     return _section(
// //       title: 'Work Mode & Location Tracking',
// //       child: _grid([
// //         _workModeOption(
// //           value: 'in_house',
// //           title: 'In-House Employee',
// //           description:
// //           'Office / Stationed. Location tracked ONLY during Check-In & Check-Out.',
// //           icon: Icons.business_outlined,
// //         ),
// //         _workModeOption(
// //           value: 'remote',
// //           title: 'Field Employee',
// //           description:
// //           'On-the-go / Field work. Continuous GPS tracking every 10 mins with live map tracking.',
// //           icon: Icons.location_on_outlined,
// //         ),
// //         _dropdown(
// //           label: 'Admin Role & Access Level',
// //           value: _adminRole,
// //           items: const [
// //             'none',
// //             'hr_admin',
// //             'accountant',
// //             'manager',
// //           ],
// //           required: false,
// //           helper:
// //           'Maximum 1 HR Admin, 1 Accountant and 1 Manager per company.',
// //           onChanged: (value) {
// //             setState(() {
// //               _adminRole = value;
// //             });
// //           },
// //         ),
// //       ]),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // PERSONAL SECTION
// //   // ==========================================================
// //
// //   Widget _buildPersonalSection() {
// //     return _section(
// //       title: 'Personal Details',
// //       child: _grid([
// //         _dateField(
// //           label: 'Date of Birth',
// //           hint: 'dd-mm-yyyy',
// //           value: _dateOfBirth,
// //           onTap: _selectDateOfBirth,
// //         ),
// //         _dropdown(
// //           label: 'Gender',
// //           value: _gender,
// //           items: const [
// //             'Male',
// //             'Female',
// //             'Other',
// //           ],
// //           required: false,
// //           onChanged: (value) {
// //             if (value == null) {
// //               return;
// //             }
// //
// //             setState(() {
// //               _gender = value;
// //             });
// //           },
// //         ),
// //         _textField(
// //           label: 'Residential Address',
// //           hint: 'City, State, Country',
// //           controller: _addressController,
// //         ),
// //         _textField(
// //           label: 'Emergency Contact Name',
// //           hint: 'Parent / Spouse name',
// //           controller: _emergencyNameController,
// //         ),
// //         _textField(
// //           label: 'Emergency Contact Phone',
// //           hint: 'Parent / Spouse phone',
// //           controller: _emergencyPhoneController,
// //           keyboardType: TextInputType.phone,
// //         ),
// //         _textField(
// //           label: 'Emergency Relationship',
// //           hint: 'e.g. Parent, Spouse, Brother',
// //           controller: _emergencyRelationshipController,
// //         ),
// //       ]),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // BANK SECTION
// //   // ==========================================================
// //
// //   Widget _buildBankSection() {
// //     return _section(
// //       title: 'Bank Details',
// //       last: true,
// //       child: _grid([
// //         _textField(
// //           label: 'Account Number',
// //           hint: 'Bank account number',
// //           controller: _accountNumberController,
// //           keyboardType: TextInputType.number,
// //         ),
// //         _textField(
// //           label: 'IFSC Code',
// //           hint: 'e.g. SBIN0001234',
// //           controller: _ifscController,
// //         ),
// //         _textField(
// //           label: 'Bank Name',
// //           hint: 'e.g. State Bank of India',
// //           controller: _bankNameController,
// //         ),
// //         _textField(
// //           label: 'UPI ID',
// //           hint: 'e.g. employee@upi',
// //           controller: _upiController,
// //         ),
// //       ]),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // BOTTOM BAR
// //   // ==========================================================
// //
// //   Widget _buildFixedFooter() {
// //     return Container(
// //       width: double.infinity,
// //       decoration: const BoxDecoration(
// //         color: Colors.white,
// //         border: Border(
// //           top: BorderSide(color: border),
// //         ),
// //       ),
// //       child: SafeArea(
// //         top: false,
// //         child: Padding(
// //           padding: const EdgeInsets.symmetric(
// //             horizontal: 28,
// //             vertical: 10,
// //           ),
// //           child: Row(
// //             children: [
// //               const Spacer(),
// //               OutlinedButton(
// //                 onPressed: _isSaving
// //                     ? null
// //                     : () {
// //                   Navigator.pop(context);
// //                 },
// //                 style: OutlinedButton.styleFrom(
// //                   foregroundColor: textDark,
// //                   side: const BorderSide(color: border),
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 22,
// //                     vertical: 12,
// //                   ),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                 ),
// //                 child: const Text(
// //                   'Cancel',
// //                   style: TextStyle(
// //                     fontSize: 13,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(width: 10),
// //               FilledButton.icon(
// //                 onPressed: _isSaving ? null : _saveEmployee,
// //                 icon: _isSaving
// //                     ? const SizedBox(
// //                   width: 16,
// //                   height: 16,
// //                   child: CircularProgressIndicator(
// //                     strokeWidth: 2,
// //                     color: Colors.white,
// //                   ),
// //                 )
// //                     : const Icon(
// //                   Icons.person_add_alt_1_rounded,
// //                   size: 16,
// //                 ),
// //                 label: Text(
// //                   _isSaving ? 'Saving Employee...' : 'Save Employee',
// //                   style: const TextStyle(
// //                     fontSize: 13,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //                 style: FilledButton.styleFrom(
// //                   backgroundColor: primary,
// //                   foregroundColor: Colors.white,
// //                   disabledBackgroundColor: primary.withOpacity(0.6),
// //                   disabledForegroundColor: Colors.white,
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 22,
// //                     vertical: 12,
// //                   ),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(8),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // LOADING FIELD
// //   // ==========================================================
// //
// //   Widget _loadingField(String label) {
// //     return _labeled(
// //       label: label,
// //       required: true,
// //       child: InputDecorator(
// //         decoration: _inputDecoration(hint: 'Loading...'),
// //         child: const Row(
// //           children: [
// //             SizedBox(
// //               width: 14,
// //               height: 14,
// //               child: CircularProgressIndicator(
// //                 strokeWidth: 2,
// //                 color: primary,
// //               ),
// //             ),
// //             SizedBox(width: 10),
// //             Expanded(
// //               child: Text(
// //                 'Loading...',
// //                 overflow: TextOverflow.ellipsis,
// //                 style: TextStyle(
// //                   fontSize: 13,
// //                   color: textLight,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // FORMAT VALUE
// //   // ==========================================================
// //
// //   String _formatValue(String value) {
// //     if (value == 'none') {
// //       return 'None (Standard Employee)';
// //     }
// //
// //     return value.replaceAll('_', ' ').split(' ').map((word) {
// //       if (word.isEmpty) {
// //         return word;
// //       }
// //
// //       return word[0].toUpperCase() + word.substring(1);
// //     }).join(' ');
// //   }
// //
// //   // ==========================================================
// //   // MESSAGE
// //   // ==========================================================
// //
// //   void _showMessage(String message) {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(
// //         content: Text(message),
// //         behavior: SnackBarBehavior.floating,
// //         backgroundColor: const Color(0xFF323A46),
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(8),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // ==========================================================
// //   // DISPOSE
// //   // ==========================================================
// //
// //   @override
// //   void dispose() {
// //     _nameController.dispose();
// //     _emailController.dispose();
// //     _phoneController.dispose();
// //     _passwordController.dispose();
// //     _designationController.dispose();
// //     _salaryController.dispose();
// //     _addressController.dispose();
// //     _emergencyPhoneController.dispose();
// //     _emergencyNameController.dispose();
// //     _emergencyRelationshipController.dispose();
// //     _accountNumberController.dispose();
// //     _ifscController.dispose();
// //     _bankNameController.dispose();
// //     _upiController.dispose();
// //
// //     super.dispose();
// //   }
// // }
//
//
//
//
//
//
// import 'package:flutter/material.dart';
//
// import '../../../../data/services/employee_service.dart';
//
// class AddEmployeeScreen extends StatefulWidget {
//   const AddEmployeeScreen({
//     super.key,
//   });
//
//   @override
//   State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
// }
//
// class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final EmployeeService _employeeService = EmployeeService();
//
//   // ==========================================================
//   // COLORS
//   // ==========================================================
//
//   static const Color primary = Color(0xFFE96832);
//   static const Color primaryLight = Color(0xFFFFF1EB);
//   static const Color textDark = Color(0xFF18212F);
//   static const Color textMedium = Color(0xFF4B5563);
//   static const Color textLight = Color(0xFF8A93A1);
//   static const Color border = Color(0xFFD9DEE5);
//   static const Color divider = Color(0xFFE9ECF0);
//   static const Color pageBackground = Color(0xFFF7F8FA);
//   static const Color errorColor = Color(0xFFD32F2F);
//
//   // ==========================================================
//   // CONTROLLERS
//   // ==========================================================
//
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _designationController = TextEditingController();
//   final TextEditingController _salaryController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _emergencyPhoneController =
//   TextEditingController();
//   final TextEditingController _emergencyNameController =
//   TextEditingController();
//   final TextEditingController _emergencyRelationshipController =
//   TextEditingController();
//   final TextEditingController _accountNumberController =
//   TextEditingController();
//   final TextEditingController _ifscController = TextEditingController();
//   final TextEditingController _bankNameController = TextEditingController();
//   final TextEditingController _upiController = TextEditingController();
//
//   // ==========================================================
//   // DROPDOWNS
//   // ==========================================================
//
//   String? _department;
//   String? _employmentType;
//   String? _workMode;
//   String? _adminRole;
//   String _gender = 'Male';
//
//   // ==========================================================
//   // DATES
//   // ==========================================================
//
//   DateTime? _dateOfJoining;
//   DateTime? _dateOfBirth;
//
//   // ==========================================================
//   // DEPARTMENTS
//   // ==========================================================
//
//   List<String> _departments = [];
//   bool _isLoadingDepartments = true;
//
//   // ==========================================================
//   // PASSWORD
//   // ==========================================================
//
//   bool _obscurePassword = true;
//
//   // ==========================================================
//   // SAVE STATE
//   // ==========================================================
//
//   bool _isSaving = false;
//
//   // ==========================================================
//   // INIT
//   // ==========================================================
//
//   @override
//   void initState() {
//     super.initState();
//
//     _loadDepartments();
//   }
//
//   // ==========================================================
//   // LOAD DEPARTMENTS
//   // ==========================================================
//
//   Future<void> _loadDepartments() async {
//     try {
//       final response = await _employeeService.getDepartments();
//
//       final departments = <String>[];
//
//       if (response is List) {
//         for (final item in response) {
//           if (item is Map) {
//             final name = item['name']?.toString().trim() ?? '';
//
//             if (name.isNotEmpty && !departments.contains(name)) {
//               departments.add(name);
//             }
//           }
//         }
//       }
//
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         _departments = departments;
//         _isLoadingDepartments = false;
//       });
//     } catch (e) {
//       debugPrint('DEPARTMENT LOAD ERROR: $e');
//
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         _isLoadingDepartments = false;
//       });
//
//       _showMessage('Unable to load departments.');
//     }
//   }
//
//   // ==========================================================
//   // SAVE EMPLOYEE
//   // ==========================================================
//
//   Future<void> _saveEmployee() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     if (_department == null || _department!.isEmpty) {
//       _showMessage('Please select department.');
//       return;
//     }
//
//     if (_employmentType == null || _employmentType!.isEmpty) {
//       _showMessage('Please select employment type.');
//       return;
//     }
//
//     if (_workMode == null || _workMode!.isEmpty) {
//       _showMessage('Please select work mode.');
//       return;
//     }
//
//     if (_dateOfJoining == null) {
//       _showMessage('Please select date of joining.');
//       return;
//     }
//
//     final salary = double.tryParse(
//       _salaryController.text.trim(),
//     );
//
//     if (salary == null) {
//       _showMessage('Please enter a valid monthly salary.');
//       return;
//     }
//
//     setState(() {
//       _isSaving = true;
//     });
//
//     try {
//       // ======================================================
//       // DOCUMENTED POST /employees PAYLOAD
//       // ======================================================
//
//       final response = await _employeeService.createEmployee(
//         name: _nameController.text.trim(),
//         email: _emailController.text.trim(),
//         phone: _phoneController.text.trim(),
//         password: _passwordController.text,
//         designation: _designationController.text.trim(),
//         department: _department!,
//         monthlySalary: salary,
//         employmentType: _employmentType!,
//         workMode: _workMode!,
//         accountNumber: _accountNumberController.text.trim(),
//         ifsc: _ifscController.text.trim(),
//         bankName: _bankNameController.text.trim(),
//         upiId: _upiController.text.trim(),
//       );
//
//       // ======================================================
//       // EMPLOYEE CREATED
//       // ======================================================
//
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         _isSaving = false;
//       });
//
//       final employee = response['employee'];
//
//       final tempPassword = response['tempPassword']?.toString();
//
//       await _showSuccessDialog(
//         employee: employee,
//         tempPassword: tempPassword,
//       );
//
//       if (!mounted) {
//         return;
//       }
//
//       Navigator.pop(context, true);
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         _isSaving = false;
//       });
//
//       _showMessage(
//         e.toString().replaceFirst('Exception: ', ''),
//       );
//     }
//   }
//
//   // ==========================================================
//   // SUCCESS DIALOG
//   // ==========================================================
//
//   Future<void> _showSuccessDialog({
//     dynamic employee,
//     String? tempPassword,
//   }) async {
//     String employeeName = '';
//     String employeeEmail = '';
//
//     if (employee is Map) {
//       employeeName = employee['name']?.toString() ?? '';
//       employeeEmail = employee['email']?.toString() ?? '';
//     }
//
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           title: Row(
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFE9F8EF),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.check_rounded,
//                   color: Color(0xFF18864B),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 'Employee Created',
//                 style: TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.w700,
//                   color: textDark,
//                 ),
//               ),
//             ],
//           ),
//           content: SizedBox(
//             width: 340,
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (employeeName.isNotEmpty)
//                   Text(
//                     employeeName,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w700,
//                       color: textDark,
//                     ),
//                   ),
//                 if (employeeEmail.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 4),
//                     child: Text(
//                       employeeEmail,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: textMedium,
//                       ),
//                     ),
//                   ),
//                 if (tempPassword != null && tempPassword.isNotEmpty) ...[
//                   const SizedBox(height: 18),
//                   const Text(
//                     'TEMPORARY PASSWORD',
//                     style: TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w700,
//                       letterSpacing: 0.5,
//                       color: textLight,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: pageBackground,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: border),
//                     ),
//                     child: SelectableText(
//                       tempPassword,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: textDark,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           actions: [
//             FilledButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               style: FilledButton.styleFrom(
//                 backgroundColor: primary,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text('Done'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // ==========================================================
//   // DATE PICKERS
//   // ==========================================================
//
//   Widget _pickerTheme(BuildContext context, Widget? child) {
//     return Theme(
//       data: Theme.of(context).copyWith(
//         colorScheme: Theme.of(context).colorScheme.copyWith(
//           primary: primary,
//         ),
//       ),
//       child: child!,
//     );
//   }
//
//   Future<void> _selectDateOfJoining() async {
//     final selected = await showDatePicker(
//       context: context,
//       initialDate: _dateOfJoining ?? DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//       builder: _pickerTheme,
//     );
//
//     if (selected != null) {
//       setState(() {
//         _dateOfJoining = selected;
//       });
//     }
//   }
//
//   Future<void> _selectDateOfBirth() async {
//     final selected = await showDatePicker(
//       context: context,
//       initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
//       firstDate: DateTime(1950),
//       lastDate: DateTime.now(),
//       builder: _pickerTheme,
//     );
//
//     if (selected != null) {
//       setState(() {
//         _dateOfBirth = selected;
//       });
//     }
//   }
//
//   // ==========================================================
//   // DATE FORMAT
//   // ==========================================================
//
//   String _formatDate(DateTime? date) {
//     if (date == null) {
//       return '';
//     }
//
//     return '${date.day.toString().padLeft(2, '0')}-'
//         '${date.month.toString().padLeft(2, '0')}-'
//         '${date.year}';
//   }
//
//   // ==========================================================
//   // INPUT DECORATION
//   // ==========================================================
//
//   OutlineInputBorder _outline(Color color, [double width = 1]) {
//     return OutlineInputBorder(
//       borderRadius: BorderRadius.circular(6),
//       borderSide: BorderSide(color: color, width: width),
//     );
//   }
//
//   InputDecoration _inputDecoration({
//     required String hint,
//     Widget? suffixIcon,
//   }) {
//     return InputDecoration(
//       isDense: true,
//       hintText: hint,
//       hintStyle: const TextStyle(
//         fontSize: 14,
//         color: textLight,
//       ),
//       errorStyle: const TextStyle(
//         fontSize: 12,
//         height: 1.1,
//       ),
//       suffixIcon: suffixIcon,
//       suffixIconConstraints: const BoxConstraints(
//         minWidth: 36,
//         minHeight: 30,
//       ),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: 14,
//         vertical: 16,
//       ),
//       border: _outline(border),
//       enabledBorder: _outline(border),
//       focusedBorder: _outline(primary, 1.4),
//       errorBorder: _outline(errorColor),
//       focusedErrorBorder: _outline(errorColor, 1.4),
//     );
//   }
//
//   // ==========================================================
//   // LABEL ABOVE FIELD
//   // ==========================================================
//
//   Widget _labeled({
//     required String label,
//     required Widget child,
//     bool required = false,
//     String? helper,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: TextSpan(
//             text: label,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w600,
//               color: textDark,
//             ),
//             children: [
//               if (required)
//                 const TextSpan(
//                   text: ' *',
//                   style: TextStyle(color: errorColor),
//                 ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 6),
//         child,
//         if (helper != null) ...[
//           const SizedBox(height: 5),
//           Text(
//             helper,
//             style: const TextStyle(
//               fontSize: 12.5,
//               color: textLight,
//             ),
//           ),
//         ],
//       ],
//     );
//   }
//
//   // ==========================================================
//   // TEXT FIELD
//   // ==========================================================
//
//   Widget _textField({
//     required String label,
//     required String hint,
//     required TextEditingController controller,
//     TextInputType? keyboardType,
//     bool obscureText = false,
//     bool required = false,
//     Widget? suffixIcon,
//     int maxLines = 1,
//   }) {
//     return _labeled(
//       label: label,
//       required: required,
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         obscureText: obscureText,
//         maxLines: maxLines,
//         style: const TextStyle(
//           fontSize: 15.5,
//           color: textDark,
//         ),
//         decoration: _inputDecoration(
//           hint: hint,
//           suffixIcon: suffixIcon,
//         ),
//         validator: required
//             ? (value) {
//           if (value == null || value.trim().isEmpty) {
//             return '$label is required';
//           }
//
//           return null;
//         }
//             : null,
//       ),
//     );
//   }
//
//   // ==========================================================
//   // DROPDOWN
//   // ==========================================================
//
//   Widget _dropdown({
//     required String label,
//     required String? value,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//     bool required = true,
//     String? helper,
//   }) {
//     return _labeled(
//       label: label,
//       required: required,
//       helper: helper,
//       child: DropdownButtonFormField<String>(
//         value: items.contains(value) ? value : null,
//         isExpanded: true,
//         icon: const Icon(
//           Icons.keyboard_arrow_down_rounded,
//           size: 20,
//           color: textMedium,
//         ),
//         style: const TextStyle(
//           fontSize: 15.5,
//           color: textDark,
//         ),
//         hint: const Text(
//           'Select',
//           style: TextStyle(
//             fontSize: 14,
//             color: textLight,
//           ),
//         ),
//         decoration: _inputDecoration(hint: 'Select'),
//         items: items.map((item) {
//           return DropdownMenuItem<String>(
//             value: item,
//             child: Text(
//               _formatValue(item),
//               overflow: TextOverflow.ellipsis,
//             ),
//           );
//         }).toList(),
//         onChanged: onChanged,
//         validator: required
//             ? (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please select $label';
//           }
//
//           return null;
//         }
//             : null,
//       ),
//     );
//   }
//
//   // ==========================================================
//   // DATE FIELD
//   // ==========================================================
//
//   Widget _dateField({
//     required String label,
//     required String hint,
//     required DateTime? value,
//     required VoidCallback onTap,
//     bool required = false,
//   }) {
//     return FormField<DateTime>(
//       validator: required
//           ? (_) {
//         if (value == null) {
//           return '$label is required';
//         }
//
//         return null;
//       }
//           : null,
//       builder: (field) {
//         return _labeled(
//           label: label,
//           required: required,
//           child: InkWell(
//             onTap: onTap,
//             borderRadius: BorderRadius.circular(6),
//             child: InputDecorator(
//               decoration: _inputDecoration(
//                 hint: hint,
//                 suffixIcon: const Icon(
//                   Icons.calendar_today_outlined,
//                   size: 18,
//                   color: textMedium,
//                 ),
//               ).copyWith(
//                 errorText: field.hasError ? field.errorText : null,
//               ),
//               child: Text(
//                 value == null ? hint : _formatDate(value),
//                 style: TextStyle(
//                   fontSize: 15.5,
//                   color: value == null ? textLight : textDark,
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // ==========================================================
//   // LAYOUT HELPERS
//   // ==========================================================
//
//   /// Responsive grid: 4 / 3 / 2 / 1 columns depending on width.
//   Widget _grid(List<Widget> items) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final width = constraints.maxWidth;
//
//         int columns;
//         if (width >= 1300) {
//           columns = 4;
//         } else if (width >= 900) {
//           columns = 3;
//         } else if (width >= 560) {
//           columns = 2;
//         } else {
//           columns = 1;
//         }
//
//         const double gap = 20;
//
//         final itemWidth = (width - gap * (columns - 1)) / columns;
//
//         return Wrap(
//           spacing: gap,
//           runSpacing: 16,
//           children: items.map((item) {
//             return SizedBox(
//               width: itemWidth,
//               child: item,
//             );
//           }).toList(),
//         );
//       },
//     );
//   }
//
//   Widget _section({
//     required String title,
//     required Widget child,
//     bool last = false,
//   }) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: last ? 0 : 22),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 3,
//                 height: 15,
//                 decoration: BoxDecoration(
//                   color: primary,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.w700,
//                   color: textDark,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           const Divider(height: 1, color: divider),
//           const SizedBox(height: 14),
//           child,
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // WORK MODE OPTION
//   // ==========================================================
//
//   Widget _workModeOption({
//     required String value,
//     required String title,
//     required String description,
//     required IconData icon,
//   }) {
//     final selected = _workMode == value;
//
//     return InkWell(
//       onTap: () {
//         setState(() {
//           _workMode = value;
//         });
//       },
//       borderRadius: BorderRadius.circular(8),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 160),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: selected ? primaryLight : Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: selected ? primary : border,
//             width: selected ? 1.4 : 1,
//           ),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(
//               icon,
//               size: 20,
//               color: selected ? primary : const Color(0xFF64748B),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                       color: textDark,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     description,
//                     style: const TextStyle(
//                       fontSize: 13,
//                       height: 1.35,
//                       color: Color(0xFF64748B),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             Icon(
//               selected
//                   ? Icons.radio_button_checked_rounded
//                   : Icons.radio_button_unchecked_rounded,
//               size: 19,
//               color: selected ? primary : const Color(0xFFB6BDC8),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // BUILD
//   // ==========================================================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           _buildPageHeader(),
//           Expanded(
//             child: Form(
//               key: _formKey,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
//                 child: Center(
//                   child: ConstrainedBox(
//                     constraints: const BoxConstraints(maxWidth: 1400),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildAccountSection(),
//                         _buildJobSection(),
//                         _buildWorkModeSection(),
//                         _buildPersonalSection(),
//                         _buildBankSection(),
//                         _buildActionButtons(),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // PAGE HEADER
//   // ==========================================================
//
//   Widget _buildPageHeader() {
//     return Container(
//       width: double.infinity,
//       height: 62,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           bottom: BorderSide(color: border),
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Row(
//           children: [
//             IconButton(
//               tooltip: 'Back',
//               onPressed: _isSaving
//                   ? null
//                   : () {
//                 Navigator.pop(context);
//               },
//               icon: const Icon(
//                 Icons.arrow_back_rounded,
//                 size: 21,
//                 color: textDark,
//               ),
//             ),
//             const SizedBox(width: 4),
//             Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: primaryLight,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(
//                 Icons.person_add_alt_1_rounded,
//                 color: primary,
//                 size: 19,
//               ),
//             ),
//             const SizedBox(width: 12),
//             const Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Add New Employee',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.w700,
//                       color: textDark,
//                     ),
//                   ),
//                   SizedBox(height: 1),
//                   Text(
//                     'Create an employee profile and assign work details.',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: textLight,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 10,
//                 vertical: 6,
//               ),
//               decoration: BoxDecoration(
//                 color: pageBackground,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: border),
//               ),
//               child: const Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.admin_panel_settings_outlined,
//                     size: 15,
//                     color: textMedium,
//                   ),
//                   SizedBox(width: 6),
//                   Text(
//                     'Admin',
//                     style: TextStyle(
//                       fontSize: 13.5,
//                       fontWeight: FontWeight.w600,
//                       color: textMedium,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // ACCOUNT SECTION
//   // ==========================================================
//
//   Widget _buildAccountSection() {
//     return _section(
//       title: 'Account & Basic Info',
//       child: _grid([
//         _textField(
//           label: 'Full Name',
//           hint: 'e.g. Rahul Sharma',
//           controller: _nameController,
//           required: true,
//         ),
//         _textField(
//           label: 'Work Email',
//           hint: 'rahul@company.com',
//           controller: _emailController,
//           keyboardType: TextInputType.emailAddress,
//           required: true,
//         ),
//         _textField(
//           label: 'Phone Number',
//           hint: '+91 9876543210',
//           controller: _phoneController,
//           keyboardType: TextInputType.phone,
//           required: true,
//         ),
//         _textField(
//           label: 'Password',
//           hint: 'Create login password',
//           controller: _passwordController,
//           obscureText: _obscurePassword,
//           required: true,
//           suffixIcon: IconButton(
//             splashRadius: 18,
//             onPressed: () {
//               setState(() {
//                 _obscurePassword = !_obscurePassword;
//               });
//             },
//             icon: Icon(
//               _obscurePassword
//                   ? Icons.visibility_outlined
//                   : Icons.visibility_off_outlined,
//               size: 20,
//               color: textMedium,
//             ),
//           ),
//         ),
//       ]),
//     );
//   }
//
//   // ==========================================================
//   // JOB SECTION
//   // ==========================================================
//
//   Widget _buildJobSection() {
//     return _section(
//       title: 'Job Role & Salary',
//       child: _grid([
//         _textField(
//           label: 'Designation',
//           hint: 'e.g. Software Engineer',
//           controller: _designationController,
//           required: true,
//         ),
//         _isLoadingDepartments
//             ? _loadingField('Department')
//             : _dropdown(
//           label: 'Department',
//           value: _department,
//           items: _departments,
//           onChanged: (value) {
//             setState(() {
//               _department = value;
//             });
//           },
//         ),
//         _dropdown(
//           label: 'Employment Type',
//           value: _employmentType,
//           items: const [
//             'full_time',
//             'part_time',
//             'contract',
//             'intern',
//           ],
//           onChanged: (value) {
//             setState(() {
//               _employmentType = value;
//             });
//           },
//         ),
//         _textField(
//           label: 'Monthly Salary (₹)',
//           hint: 'e.g. 45000',
//           controller: _salaryController,
//           keyboardType: const TextInputType.numberWithOptions(
//             decimal: true,
//           ),
//           required: true,
//         ),
//         _dateField(
//           label: 'Date of Joining',
//           hint: 'dd-mm-yyyy',
//           value: _dateOfJoining,
//           onTap: _selectDateOfJoining,
//           required: true,
//         ),
//       ]),
//     );
//   }
//
//   // ==========================================================
//   // WORK MODE SECTION
//   // ==========================================================
//
//   Widget _buildWorkModeSection() {
//     return _section(
//       title: 'Work Mode & Location Tracking',
//       child: _grid([
//         _workModeOption(
//           value: 'in_house',
//           title: 'In-House Employee',
//           description:
//           'Office / Stationed. Location tracked ONLY during Check-In & Check-Out.',
//           icon: Icons.business_outlined,
//         ),
//         _workModeOption(
//           value: 'remote',
//           title: 'Field Employee',
//           description:
//           'On-the-go / Field work. Continuous GPS tracking every 10 mins with live map tracking.',
//           icon: Icons.location_on_outlined,
//         ),
//         _dropdown(
//           label: 'Admin Role & Access Level',
//           value: _adminRole,
//           items: const [
//             'none',
//             'hr_admin',
//             'accountant',
//             'manager',
//           ],
//           required: false,
//           helper:
//           'Maximum 1 HR Admin, 1 Accountant and 1 Manager per company.',
//           onChanged: (value) {
//             setState(() {
//               _adminRole = value;
//             });
//           },
//         ),
//       ]),
//     );
//   }
//
//   // ==========================================================
//   // PERSONAL SECTION
//   // ==========================================================
//
//   Widget _buildPersonalSection() {
//     return _section(
//       title: 'Personal Details',
//       child: _grid([
//         _dateField(
//           label: 'Date of Birth',
//           hint: 'dd-mm-yyyy',
//           value: _dateOfBirth,
//           onTap: _selectDateOfBirth,
//         ),
//         _dropdown(
//           label: 'Gender',
//           value: _gender,
//           items: const [
//             'Male',
//             'Female',
//             'Other',
//           ],
//           required: false,
//           onChanged: (value) {
//             if (value == null) {
//               return;
//             }
//
//             setState(() {
//               _gender = value;
//             });
//           },
//         ),
//         _textField(
//           label: 'Residential Address',
//           hint: 'City, State, Country',
//           controller: _addressController,
//         ),
//         _textField(
//           label: 'Emergency Contact Name',
//           hint: 'Parent / Spouse name',
//           controller: _emergencyNameController,
//         ),
//         _textField(
//           label: 'Emergency Contact Phone',
//           hint: 'Parent / Spouse phone',
//           controller: _emergencyPhoneController,
//           keyboardType: TextInputType.phone,
//         ),
//         _textField(
//           label: 'Emergency Relationship',
//           hint: 'e.g. Parent, Spouse, Brother',
//           controller: _emergencyRelationshipController,
//         ),
//       ]),
//     );
//   }
//
//   // ==========================================================
//   // BANK SECTION
//   // ==========================================================
//
//   Widget _buildBankSection() {
//     return _section(
//       title: 'Bank Details',
//       last: true,
//       child: _grid([
//         _textField(
//           label: 'Account Number',
//           hint: 'Bank account number',
//           controller: _accountNumberController,
//           keyboardType: TextInputType.number,
//         ),
//         _textField(
//           label: 'IFSC Code',
//           hint: 'e.g. SBIN0001234',
//           controller: _ifscController,
//         ),
//         _textField(
//           label: 'Bank Name',
//           hint: 'e.g. State Bank of India',
//           controller: _bankNameController,
//         ),
//         _textField(
//           label: 'UPI ID',
//           hint: 'e.g. employee@upi',
//           controller: _upiController,
//         ),
//       ]),
//     );
//   }
//
//   // ==========================================================
//   // ACTION BUTTONS (end of form)
//   // ==========================================================
//
//   Widget _buildActionButtons() {
//     return Padding(
//       padding: const EdgeInsets.only(top: 28),
//       child: Column(
//         children: [
//           const Divider(height: 1, color: divider),
//           const SizedBox(height: 18),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               OutlinedButton(
//                 onPressed: _isSaving
//                     ? null
//                     : () {
//                   Navigator.pop(context);
//                 },
//                 style: OutlinedButton.styleFrom(
//                   foregroundColor: textDark,
//                   side: const BorderSide(color: border),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 28,
//                     vertical: 17,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 child: const Text(
//                   'Cancel',
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               FilledButton.icon(
//                 onPressed: _isSaving ? null : _saveEmployee,
//                 icon: _isSaving
//                     ? const SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.white,
//                   ),
//                 )
//                     : const Icon(
//                   Icons.person_add_alt_1_rounded,
//                   size: 19,
//                 ),
//                 label: Text(
//                   _isSaving ? 'Saving Employee...' : 'Save Employee',
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 style: FilledButton.styleFrom(
//                   backgroundColor: primary,
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor: primary.withOpacity(0.6),
//                   disabledForegroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 28,
//                     vertical: 17,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ==========================================================
//   // LOADING FIELD
//   // ==========================================================
//
//   Widget _loadingField(String label) {
//     return _labeled(
//       label: label,
//       required: true,
//       child: InputDecorator(
//         decoration: _inputDecoration(hint: 'Loading...'),
//         child: const Row(
//           children: [
//             SizedBox(
//               width: 14,
//               height: 14,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: primary,
//               ),
//             ),
//             SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 'Loading...',
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: textLight,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // FORMAT VALUE
//   // ==========================================================
//
//   String _formatValue(String value) {
//     if (value == 'none') {
//       return 'None (Standard Employee)';
//     }
//
//     return value.replaceAll('_', ' ').split(' ').map((word) {
//       if (word.isEmpty) {
//         return word;
//       }
//
//       return word[0].toUpperCase() + word.substring(1);
//     }).join(' ');
//   }
//
//   // ==========================================================
//   // MESSAGE
//   // ==========================================================
//
//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: const Color(0xFF323A46),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }
//
//   // ==========================================================
//   // DISPOSE
//   // ==========================================================
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _passwordController.dispose();
//     _designationController.dispose();
//     _salaryController.dispose();
//     _addressController.dispose();
//     _emergencyPhoneController.dispose();
//     _emergencyNameController.dispose();
//     _emergencyRelationshipController.dispose();
//     _accountNumberController.dispose();
//     _ifscController.dispose();
//     _bankNameController.dispose();
//     _upiController.dispose();
//
//     super.dispose();
//   }
// }




import 'package:flutter/material.dart';

import '../../../../data/services/employee_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({
    super.key,
  });

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final EmployeeService _employeeService = EmployeeService();

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFF1EB);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFD9DEE5);
  static const Color divider = Color(0xFFE9ECF0);
  static const Color pageBackground = Color(0xFFF7F8FA);
  static const Color errorColor = Color(0xFFD32F2F);

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyPhoneController =
  TextEditingController();
  final TextEditingController _emergencyNameController =
  TextEditingController();
  final TextEditingController _emergencyRelationshipController =
  TextEditingController();
  final TextEditingController _accountNumberController =
  TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  // ==========================================================
  // DROPDOWNS
  // ==========================================================

  String? _department;
  String? _employmentType;
  String? _workMode;
  String? _adminRole;
  String _gender = 'Male';

  // ==========================================================
  // DATES
  // ==========================================================

  DateTime? _dateOfJoining;
  DateTime? _dateOfBirth;

  // ==========================================================
  // DEPARTMENTS
  // ==========================================================

  List<String> _departments = [];
  bool _isLoadingDepartments = true;

  // ==========================================================
  // PASSWORD
  // ==========================================================

  bool _obscurePassword = true;

  // ==========================================================
  // SAVE STATE
  // ==========================================================

  bool _isSaving = false;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadDepartments();
  }

  // ==========================================================
  // LOAD DEPARTMENTS
  // ==========================================================

  Future<void> _loadDepartments() async {
    try {
      final response = await _employeeService.getDepartments();

      final departments = <String>[];

      if (response is List) {
        for (final item in response) {
          if (item is Map) {
            final name = item['name']?.toString().trim() ?? '';

            if (name.isNotEmpty && !departments.contains(name)) {
              departments.add(name);
            }
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _departments = departments;
        _isLoadingDepartments = false;
      });
    } catch (e) {
      debugPrint('DEPARTMENT LOAD ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingDepartments = false;
      });

      _showMessage('Unable to load departments.');
    }
  }

  // ==========================================================
  // SAVE EMPLOYEE
  // ==========================================================

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_department == null || _department!.isEmpty) {
      _showMessage('Please select department.');
      return;
    }

    if (_employmentType == null || _employmentType!.isEmpty) {
      _showMessage('Please select employment type.');
      return;
    }

    if (_workMode == null || _workMode!.isEmpty) {
      _showMessage('Please select work mode.');
      return;
    }

    if (_dateOfJoining == null) {
      _showMessage('Please select date of joining.');
      return;
    }

    final salary = double.tryParse(
      _salaryController.text.trim(),
    );

    if (salary == null) {
      _showMessage('Please enter a valid monthly salary.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // ======================================================
      // DOCUMENTED POST /employees PAYLOAD
      // ======================================================

      final response = await _employeeService.createEmployee(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        designation: _designationController.text.trim(),
        department: _department!,
        monthlySalary: salary,
        employmentType: _employmentType!,
        workMode: _workMode!,
        dateOfJoining: _dateOfJoining!,
        adminRole: _adminRole,
        accountNumber: _accountNumberController.text.trim(),
        ifsc: _ifscController.text.trim(),
        bankName: _bankNameController.text.trim(),
        upiId: _upiController.text.trim(),
      );

      // ======================================================
      // EMPLOYEE CREATED
      // ======================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      final employee = response['employee'];

      final tempPassword = response['tempPassword']?.toString();

      await _showSuccessDialog(
        employee: employee,
        tempPassword: tempPassword,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ==========================================================
  // SUCCESS DIALOG
  // ==========================================================

  Future<void> _showSuccessDialog({
    dynamic employee,
    String? tempPassword,
  }) async {
    String employeeName = '';
    String employeeEmail = '';

    if (employee is Map) {
      employeeName = employee['name']?.toString() ?? '';
      employeeEmail = employee['email']?.toString() ?? '';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF18864B),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Employee Created',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (employeeName.isNotEmpty)
                  Text(
                    employeeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                if (employeeEmail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      employeeEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textMedium,
                      ),
                    ),
                  ),
                if (tempPassword != null && tempPassword.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'TEMPORARY PASSWORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pageBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                    ),
                    child: SelectableText(
                      tempPassword,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DATE PICKERS
  // ==========================================================

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: primary,
        ),
      ),
      child: child!,
    );
  }

  Future<void> _selectDateOfJoining() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfJoining ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _pickerTheme,
    );

    if (selected != null) {
      setState(() {
        _dateOfJoining = selected;
      });
    }
  }

  Future<void> _selectDateOfBirth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: _pickerTheme,
    );

    if (selected != null) {
      setState(() {
        _dateOfBirth = selected;
      });
    }
  }

  // ==========================================================
  // DATE FORMAT
  // ==========================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  // ==========================================================
  // INPUT DECORATION
  // ==========================================================

  OutlineInputBorder _outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: textLight,
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        height: 1.1,
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 36,
        minHeight: 30,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: _outline(border),
      enabledBorder: _outline(border),
      focusedBorder: _outline(primary, 1.4),
      errorBorder: _outline(errorColor),
      focusedErrorBorder: _outline(errorColor, 1.4),
    );
  }

  // ==========================================================
  // LABEL ABOVE FIELD
  // ==========================================================

  Widget _labeled({
    required String label,
    required Widget child,
    bool required = false,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: errorColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(
            helper,
            style: const TextStyle(
              fontSize: 12.5,
              color: textLight,
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================================
  // TEXT FIELD
  // ==========================================================

  Widget _textField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool required = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return _labeled(
      label: label,
      required: required,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 15.5,
          color: textDark,
        ),
        decoration: _inputDecoration(
          hint: hint,
          suffixIcon: suffixIcon,
        ),
        validator: required
            ? (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }

          return null;
        }
            : null,
      ),
    );
  }

  // ==========================================================
  // DROPDOWN
  // ==========================================================

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = true,
    String? helper,
  }) {
    return _labeled(
      label: label,
      required: required,
      helper: helper,
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: textMedium,
        ),
        style: const TextStyle(
          fontSize: 15.5,
          color: textDark,
        ),
        hint: const Text(
          'Select',
          style: TextStyle(
            fontSize: 14,
            color: textLight,
          ),
        ),
        decoration: _inputDecoration(hint: 'Select'),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              _formatValue(item),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: required
            ? (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }

          return null;
        }
            : null,
      ),
    );
  }

  // ==========================================================
  // DATE FIELD
  // ==========================================================

  Widget _dateField({
    required String label,
    required String hint,
    required DateTime? value,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return FormField<DateTime>(
      validator: required
          ? (_) {
        if (value == null) {
          return '$label is required';
        }

        return null;
      }
          : null,
      builder: (field) {
        return _labeled(
          label: label,
          required: required,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: _inputDecoration(
                hint: hint,
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: textMedium,
                ),
              ).copyWith(
                errorText: field.hasError ? field.errorText : null,
              ),
              child: Text(
                value == null ? hint : _formatDate(value),
                style: TextStyle(
                  fontSize: 15.5,
                  color: value == null ? textLight : textDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // LAYOUT HELPERS
  // ==========================================================

  /// Responsive grid: 4 / 3 / 2 / 1 columns depending on width.
  Widget _grid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;
        if (width >= 1300) {
          columns = 4;
        } else if (width >= 900) {
          columns = 3;
        } else if (width >= 560) {
          columns = 2;
        } else {
          columns = 1;
        }

        const double gap = 20;

        final itemWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: item,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _section({
    required String title,
    required Widget child,
    bool last = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 15,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: divider),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ==========================================================
  // WORK MODE OPTION
  // ==========================================================

  Widget _workModeOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final selected = _workMode == value;

    return InkWell(
      onTap: () {
        setState(() {
          _workMode = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? primary : border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: selected ? primary : const Color(0xFFB6BDC8),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildPageHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccountSection(),
                        _buildJobSection(),
                        _buildWorkModeSection(),
                        _buildPersonalSection(),
                        _buildBankSection(),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PAGE HEADER
  // ==========================================================

  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: _isSaving
                  ? null
                  : () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 21,
                color: textDark,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Employee',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Create an employee profile and assign work details.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: textLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: pageBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 15,
                    color: textMedium,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textMedium,
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

  // ==========================================================
  // ACCOUNT SECTION
  // ==========================================================

  Widget _buildAccountSection() {
    return _section(
      title: 'Account & Basic Info',
      child: _grid([
        _textField(
          label: 'Full Name',
          hint: 'e.g. Rahul Sharma',
          controller: _nameController,
          required: true,
        ),
        _textField(
          label: 'Work Email',
          hint: 'rahul@company.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          required: true,
        ),
        _textField(
          label: 'Phone Number',
          hint: '+91 9876543210',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          required: true,
        ),
        _textField(
          label: 'Password',
          hint: 'Create login password',
          controller: _passwordController,
          obscureText: _obscurePassword,
          required: true,
          suffixIcon: IconButton(
            splashRadius: 18,
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: textMedium,
            ),
          ),
        ),
      ]),
    );
  }

  // ==========================================================
  // JOB SECTION
  // ==========================================================

  Widget _buildJobSection() {
    return _section(
      title: 'Job Role & Salary',
      child: _grid([
        _textField(
          label: 'Designation',
          hint: 'e.g. Software Engineer',
          controller: _designationController,
          required: true,
        ),
        _isLoadingDepartments
            ? _loadingField('Department')
            : _dropdown(
          label: 'Department',
          value: _department,
          items: _departments,
          onChanged: (value) {
            setState(() {
              _department = value;
            });
          },
        ),
        _dropdown(
          label: 'Employment Type',
          value: _employmentType,
          items: const [
            'full_time',
            'part_time',
            'contract',
            'intern',
          ],
          onChanged: (value) {
            setState(() {
              _employmentType = value;
            });
          },
        ),
        _textField(
          label: 'Monthly Salary (₹)',
          hint: 'e.g. 45000',
          controller: _salaryController,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          required: true,
        ),
        _dateField(
          label: 'Date of Joining',
          hint: 'dd-mm-yyyy',
          value: _dateOfJoining,
          onTap: _selectDateOfJoining,
          required: true,
        ),
      ]),
    );
  }

  // ==========================================================
  // WORK MODE SECTION
  // ==========================================================

  Widget _buildWorkModeSection() {
    return _section(
      title: 'Work Mode & Location Tracking',
      child: _grid([
        _workModeOption(
          value: 'in_house',
          title: 'In-House Employee',
          description:
          'Office / Stationed. Location tracked ONLY during Check-In & Check-Out.',
          icon: Icons.business_outlined,
        ),
        _workModeOption(
          value: 'remote',
          title: 'Field Employee',
          description:
          'On-the-go / Field work. Continuous GPS tracking every 10 mins with live map tracking.',
          icon: Icons.location_on_outlined,
        ),
        _dropdown(
          label: 'Admin Role & Access Level',
          value: _adminRole,
          items: const [
            'none',
            'hr_admin',
            'accountant',
            'manager',
          ],
          required: false,
          helper:
          'Maximum 1 HR Admin, 1 Accountant and 1 Manager per company.',
          onChanged: (value) {
            setState(() {
              _adminRole = value;
            });
          },
        ),
      ]),
    );
  }

  // ==========================================================
  // PERSONAL SECTION
  // ==========================================================

  Widget _buildPersonalSection() {
    return _section(
      title: 'Personal Details',
      child: _grid([
        _dateField(
          label: 'Date of Birth',
          hint: 'dd-mm-yyyy',
          value: _dateOfBirth,
          onTap: _selectDateOfBirth,
        ),
        _dropdown(
          label: 'Gender',
          value: _gender,
          items: const [
            'Male',
            'Female',
            'Other',
          ],
          required: false,
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _gender = value;
            });
          },
        ),
        _textField(
          label: 'Residential Address',
          hint: 'City, State, Country',
          controller: _addressController,
        ),
        _textField(
          label: 'Emergency Contact Name',
          hint: 'Parent / Spouse name',
          controller: _emergencyNameController,
        ),
        _textField(
          label: 'Emergency Contact Phone',
          hint: 'Parent / Spouse phone',
          controller: _emergencyPhoneController,
          keyboardType: TextInputType.phone,
        ),
        _textField(
          label: 'Emergency Relationship',
          hint: 'e.g. Parent, Spouse, Brother',
          controller: _emergencyRelationshipController,
        ),
      ]),
    );
  }

  // ==========================================================
  // BANK SECTION
  // ==========================================================

  Widget _buildBankSection() {
    return _section(
      title: 'Bank Details',
      last: true,
      child: _grid([
        _textField(
          label: 'Account Number',
          hint: 'Bank account number',
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
        ),
        _textField(
          label: 'IFSC Code',
          hint: 'e.g. SBIN0001234',
          controller: _ifscController,
        ),
        _textField(
          label: 'Bank Name',
          hint: 'e.g. State Bank of India',
          controller: _bankNameController,
        ),
        _textField(
          label: 'UPI ID',
          hint: 'e.g. employee@upi',
          controller: _upiController,
        ),
      ]),
    );
  }

  // ==========================================================
  // ACTION BUTTONS (end of form)
  // ==========================================================

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          const Divider(height: 1, color: divider),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: textDark,
                  side: const BorderSide(color: border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 17,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveEmployee,
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 19,
                ),
                label: Text(
                  _isSaving ? 'Saving Employee...' : 'Save Employee',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primary.withOpacity(0.6),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 17,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LOADING FIELD
  // ==========================================================

  Widget _loadingField(String label) {
    return _labeled(
      label: label,
      required: true,
      child: InputDecorator(
        decoration: _inputDecoration(hint: 'Loading...'),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primary,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Loading...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // FORMAT VALUE
  // ==========================================================

  String _formatValue(String value) {
    if (value == 'none') {
      return 'None (Standard Employee)';
    }

    return value.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) {
        return word;
      }

      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323A46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _designationController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _upiController.dispose();

    super.dispose();
  }
}