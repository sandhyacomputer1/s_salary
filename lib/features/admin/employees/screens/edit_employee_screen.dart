// import 'package:flutter/material.dart';
//
// import '../../../../core/network/api_client.dart';
// import '../../../../data/models/employee.dart';
// import '../../../../data/services/employee_service.dart';
//
// class EditEmployeeScreen extends StatefulWidget {
//   final Employee employee;
//   final Map<String, dynamic> employeeData;
//   final Map<String, dynamic> userData;
//   final Map<String, dynamic> personalDetails;
//
//   const EditEmployeeScreen({
//     super.key,
//     required this.employee,
//     required this.employeeData,
//     required this.userData,
//     required this.personalDetails,
//   });
//
//   @override
//   State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
// }
//
// class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final EmployeeService _employeeService = EmployeeService();
//
//   final ApiClient _apiClient = ApiClient();
//
//   // ============================================================
//   // COLORS
//   // ============================================================
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
//   // ============================================================
//   // CONTROLLERS
//   // ============================================================
//
//   late final TextEditingController _nameController;
//   late final TextEditingController _emailController;
//   late final TextEditingController _employeeCodeController;
//   late final TextEditingController _phoneController;
//   late final TextEditingController _designationController;
//   late final TextEditingController _addressController;
//
//   late final TextEditingController _emergencyNameController;
//   late final TextEditingController _emergencyRelationshipController;
//   late final TextEditingController _emergencyPhoneController;
//
//   late final TextEditingController _accountNumberController;
//
//   late final TextEditingController _ifscController;
//   late final TextEditingController _bankNameController;
//   late final TextEditingController _upiController;
//
//   // ============================================================
//   // DROPDOWN VALUES
//   // ============================================================
//
//   String? _department;
//   String? _employmentType;
//   String? _workMode;
//   String? _gender;
//
//   // Department values are loaded from API.
//   List<String> _departments = [];
//
//   bool _isLoadingDepartments = false;
//
//   // ============================================================
//   // DATES
//   // ============================================================
//
//   DateTime? _dateOfJoining;
//   DateTime? _dateOfBirth;
//
//   // ============================================================
//   // STATUS
//   // ============================================================
//
//   bool _isActive = true;
//   bool _isSaving = false;
//
//   // ============================================================
//   // INIT
//   // ============================================================
//
//   @override
//   void initState() {
//     super.initState();
//
//     final bank = widget.employeeData['bankDetails'] is Map
//         ? Map<String, dynamic>.from(
//       widget.employeeData['bankDetails'],
//     )
//         : <String, dynamic>{};
//
//     // ----------------------------------------------------------
//     // Emergency Contact
//     // ----------------------------------------------------------
//
//     final emergency = widget.personalDetails['emergencyContact'];
//
//     String emergencyName = '';
//     String emergencyRelationship = '';
//     String emergencyPhone = '';
//
//     if (emergency is Map) {
//       emergencyName = emergency['name']?.toString() ?? '';
//
//       emergencyRelationship = emergency['relationship']?.toString() ?? '';
//
//       emergencyPhone = emergency['phone']?.toString() ?? '';
//     } else if (emergency != null) {
//       emergencyPhone = emergency.toString();
//     }
//
//     // ----------------------------------------------------------
//     // Basic Information
//     // ----------------------------------------------------------
//
//     _nameController = TextEditingController(
//       text: widget.userData['name']?.toString() ??
//           widget.employeeData['name']?.toString() ??
//           widget.employee.name,
//     );
//
//     _emailController = TextEditingController(
//       text: widget.userData['email']?.toString() ??
//           widget.employeeData['email']?.toString() ??
//           widget.employee.email,
//     );
//
//     _employeeCodeController = TextEditingController(
//       text: widget.employeeData['employeeCode']?.toString() ??
//           widget.employee.employeeCode,
//     );
//
//     _phoneController = TextEditingController(
//       text: widget.userData['phone']?.toString() ??
//           widget.employeeData['phone']?.toString() ??
//           widget.personalDetails['phone']?.toString() ??
//           '',
//     );
//
//     _designationController = TextEditingController(
//       text: widget.employeeData['designation']?.toString() ??
//           widget.employee.designation,
//     );
//
//     _addressController = TextEditingController(
//       text: widget.personalDetails['address']?.toString() ?? '',
//     );
//
//     // ----------------------------------------------------------
//     // Emergency
//     // ----------------------------------------------------------
//
//     _emergencyNameController = TextEditingController(
//       text: emergencyName,
//     );
//
//     _emergencyRelationshipController = TextEditingController(
//       text: emergencyRelationship,
//     );
//
//     _emergencyPhoneController = TextEditingController(
//       text: emergencyPhone,
//     );
//
//     // ----------------------------------------------------------
//     // Bank
//     // ----------------------------------------------------------
//
//     _accountNumberController = TextEditingController(
//       text: bank['accountNumber']?.toString() ?? '',
//     );
//
//     _ifscController = TextEditingController(
//       text: bank['ifsc']?.toString() ?? '',
//     );
//
//     _bankNameController = TextEditingController(
//       text: bank['bankName']?.toString() ?? '',
//     );
//
//     _upiController = TextEditingController(
//       text: bank['upiId']?.toString() ?? '',
//     );
//
//     // ----------------------------------------------------------
//     // Existing values
//     // ----------------------------------------------------------
//
//     _department = widget.employeeData['department']?.toString();
//
//     _employmentType = widget.employeeData['employmentType']?.toString();
//
//     _workMode = widget.employeeData['workMode']?.toString();
//
//     _gender = widget.personalDetails['gender']?.toString();
//
//     _dateOfJoining = _parseDate(
//       widget.employeeData['dateOfJoining'],
//     );
//
//     _dateOfBirth = _parseDate(
//       widget.personalDetails['dob'],
//     );
//
//     _isActive =
//         (widget.employeeData['status']?.toString().toLowerCase() ?? 'active') ==
//             'active';
//
//     // Load departments from API.
//     _loadDepartments();
//   }
//
//   // ============================================================
//   // LOAD DEPARTMENTS
//   // ============================================================
//
//   Future<void> _loadDepartments() async {
//     if (!mounted) return;
//
//     setState(() {
//       _isLoadingDepartments = true;
//     });
//
//     try {
//       final response = await _apiClient.get('/departments');
//
//       final List<String> apiDepartments = [];
//
//       if (response is List) {
//         for (final item in response) {
//           if (item is Map) {
//             final name = item['name']?.toString().trim() ?? '';
//
//             if (name.isNotEmpty && !apiDepartments.contains(name)) {
//               apiDepartments.add(name);
//             }
//           }
//         }
//       }
//
//       // --------------------------------------------------------
//       // Keep the employee's current department even if the
//       // /departments API does not return it.
//       // --------------------------------------------------------
//
//       final currentDepartment =
//           widget.employeeData['department']?.toString().trim() ?? '';
//
//       if (currentDepartment.isNotEmpty &&
//           !apiDepartments.contains(currentDepartment)) {
//         apiDepartments.add(currentDepartment);
//       }
//
//       if (!mounted) return;
//
//       setState(() {
//         _departments = apiDepartments;
//
//         if (_departments.contains(_department)) {
//           // Keep selected value.
//         } else if (_departments.isNotEmpty) {
//           _department = _departments.first;
//         } else {
//           _department = null;
//         }
//
//         _isLoadingDepartments = false;
//       });
//     } catch (e) {
//       debugPrint('DEPARTMENT API ERROR: $e');
//
//       // --------------------------------------------------------
//       // If API fails, don't create fake departments.
//       // Keep only the employee's current API value.
//       // --------------------------------------------------------
//
//       final currentDepartment =
//           widget.employeeData['department']?.toString().trim() ?? '';
//
//       if (!mounted) return;
//
//       setState(() {
//         _departments = currentDepartment.isNotEmpty ? [currentDepartment] : [];
//
//         _department = currentDepartment.isNotEmpty ? currentDepartment : null;
//
//         _isLoadingDepartments = false;
//       });
//     }
//   }
//
//   // ============================================================
//   // DATE PARSER
//   // ============================================================
//
//   DateTime? _parseDate(dynamic value) {
//     if (value == null) {
//       return null;
//     }
//
//     return DateTime.tryParse(
//       value.toString(),
//     );
//   }
//
//   // ============================================================
//   // DISPOSE
//   // ============================================================
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _employeeCodeController.dispose();
//     _phoneController.dispose();
//     _designationController.dispose();
//     _addressController.dispose();
//
//     _emergencyNameController.dispose();
//     _emergencyRelationshipController.dispose();
//     _emergencyPhoneController.dispose();
//
//     _accountNumberController.dispose();
//     _ifscController.dispose();
//     _bankNameController.dispose();
//     _upiController.dispose();
//
//     super.dispose();
//   }
//
//   // ============================================================
//   // DATE PICKER
//   // ============================================================
//
//   Future<void> _selectDate({
//     required bool joiningDate,
//   }) async {
//     final initialDate = joiningDate ? _dateOfJoining : _dateOfBirth;
//
//     final selected = await showDatePicker(
//       context: context,
//       initialDate: initialDate ?? DateTime.now(),
//       firstDate: DateTime(1950),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: Theme.of(context).colorScheme.copyWith(
//               primary: primary,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (selected == null) {
//       return;
//     }
//
//     if (!mounted) {
//       return;
//     }
//
//     setState(() {
//       if (joiningDate) {
//         _dateOfJoining = selected;
//       } else {
//         _dateOfBirth = selected;
//       }
//     });
//   }
//
//   // ============================================================
//   // DATE TEXT
//   // ============================================================
//
//   String _dateText(DateTime? date) {
//     if (date == null) {
//       return 'Select date';
//     }
//
//     return '${date.day.toString().padLeft(2, '0')}/'
//         '${date.month.toString().padLeft(2, '0')}/'
//         '${date.year}';
//   }
//
//   // ============================================================
//   // SAVE
//   // ============================================================
//
//   Future<void> _saveChanges() async {
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
//     setState(() {
//       _isSaving = true;
//     });
//
//     try {
//       // ========================================================
//       // DOCUMENTED API
//       //
//       // PUT /employees/:id/personal-details
//       //
//       // Supported fields:
//       // phone
//       // address
//       // emergencyContact
//       // ========================================================
//
//       await _employeeService.updatePersonalDetails(
//         employeeId: widget.employee.id,
//         phone: _phoneController.text.trim(),
//         address: _addressController.text.trim(),
//         emergencyName: _emergencyNameController.text.trim(),
//         emergencyRelationship: _emergencyRelationshipController.text.trim(),
//         emergencyPhone: _emergencyPhoneController.text.trim(),
//       );
//
//       if (!mounted) {
//         return;
//       }
//
//       setState(() {
//         _isSaving = false;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Personal and contact details updated successfully.',
//           ),
//         ),
//       );
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
//   // ============================================================
//   // MESSAGE
//   // ============================================================
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
//   // ============================================================
//   // INPUT DECORATION
//   // ============================================================
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
//     IconData? icon,
//     Widget? suffixIcon,
//   }) {
//     return InputDecoration(
//       isDense: true,
//       hintText: hint,
//       hintStyle: const TextStyle(
//         fontSize: 14.5,
//         color: textLight,
//       ),
//       errorStyle: const TextStyle(
//         fontSize: 12,
//         height: 1.1,
//       ),
//       prefixIcon: icon == null
//           ? null
//           : Icon(
//         icon,
//         size: 19,
//         color: textLight,
//       ),
//       prefixIconConstraints: const BoxConstraints(
//         minWidth: 44,
//         minHeight: 30,
//       ),
//       suffixIcon: suffixIcon,
//       suffixIconConstraints: const BoxConstraints(
//         minWidth: 40,
//         minHeight: 30,
//       ),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: EdgeInsets.symmetric(
//         horizontal: icon == null ? 14 : 4,
//         vertical: 16,
//       ),
//       border: _outline(border),
//       enabledBorder: _outline(border),
//       focusedBorder: _outline(primary, 1.5),
//       errorBorder: _outline(errorColor),
//       focusedErrorBorder: _outline(errorColor, 1.5),
//     );
//   }
//
//   // ============================================================
//   // LABEL ABOVE FIELD
//   // ============================================================
//
//   Widget _labeled({
//     required String label,
//     required Widget child,
//     bool required = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RichText(
//           text: TextSpan(
//             text: label,
//             style: const TextStyle(
//               fontSize: 13.5,
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
//         const SizedBox(height: 7),
//         child,
//       ],
//     );
//   }
//
//   // ============================================================
//   // TEXT FIELD
//   // ============================================================
//
//   Widget _textField({
//     required String label,
//     required TextEditingController controller,
//     required IconData icon,
//     TextInputType? keyboardType,
//     bool readOnly = false,
//     int maxLines = 1,
//   }) {
//     return _labeled(
//       label: label,
//       required: true,
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         readOnly: readOnly,
//         maxLines: maxLines,
//         style: const TextStyle(
//           fontSize: 15.5,
//           color: textDark,
//         ),
//         decoration: _inputDecoration(
//           hint: label,
//           icon: icon,
//         ),
//         validator: (value) {
//           if (value == null || value.trim().isEmpty) {
//             return '$label is required';
//           }
//
//           return null;
//         },
//       ),
//     );
//   }
//
//   // ============================================================
//   // DROPDOWN
//   // ============================================================
//
//   Widget _dropdown({
//     required String label,
//     required String? value,
//     required List<String> items,
//     required ValueChanged<String?> onChanged,
//     required IconData icon,
//   }) {
//     // ----------------------------------------------------------
//     // Protection against:
//     //
//     // "There should be exactly one item with DropdownButton's
//     // value..."
//     // ----------------------------------------------------------
//
//     final safeValue = items.contains(value) ? value : null;
//
//     return _labeled(
//       label: label,
//       required: true,
//       child: DropdownButtonFormField<String>(
//         value: safeValue,
//         isExpanded: true,
//         icon: const Icon(
//           Icons.keyboard_arrow_down_rounded,
//           size: 22,
//           color: textMedium,
//         ),
//         style: const TextStyle(
//           fontSize: 15.5,
//           color: textDark,
//         ),
//         hint: const Text(
//           'Select',
//           style: TextStyle(
//             fontSize: 14.5,
//             color: textLight,
//           ),
//         ),
//         decoration: _inputDecoration(
//           hint: 'Select',
//           icon: icon,
//         ),
//         items: items.map((item) {
//           return DropdownMenuItem<String>(
//             value: item,
//             child: Text(
//               _formatDropdownText(item),
//               overflow: TextOverflow.ellipsis,
//             ),
//           );
//         }).toList(),
//         onChanged: onChanged,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please select $label';
//           }
//
//           return null;
//         },
//       ),
//     );
//   }
//
//   // ============================================================
//   // DROPDOWN TEXT FORMAT
//   // ============================================================
//
//   String _formatDropdownText(String value) {
//     return value.replaceAll('_', ' ').split(' ').map((word) {
//       if (word.isEmpty) {
//         return word;
//       }
//
//       return '${word[0].toUpperCase()}'
//           '${word.substring(1)}';
//     }).join(' ');
//   }
//
//   // ============================================================
//   // DATE FIELD
//   // ============================================================
//
//   Widget _dateField({
//     required String label,
//     required DateTime? value,
//     required VoidCallback onTap,
//     required IconData icon,
//   }) {
//     return _labeled(
//       label: label,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(6),
//         child: InputDecorator(
//           decoration: _inputDecoration(
//             hint: 'Select date',
//             icon: icon,
//             suffixIcon: const Icon(
//               Icons.calendar_today_outlined,
//               size: 17,
//               color: textMedium,
//             ),
//           ),
//           child: Text(
//             _dateText(value),
//             style: TextStyle(
//               fontSize: 15.5,
//               color: value == null ? textLight : textDark,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // LOADING FIELD
//   // ============================================================
//
//   Widget _loadingField(String label) {
//     return _labeled(
//       label: label,
//       required: true,
//       child: InputDecorator(
//         decoration: _inputDecoration(
//           hint: 'Loading...',
//           icon: Icons.account_tree_outlined,
//         ),
//         child: const Row(
//           children: [
//             SizedBox(
//               height: 16,
//               width: 16,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: primary,
//               ),
//             ),
//             SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 'Loading departments...',
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize: 14.5,
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
//   // ============================================================
//   // LAYOUT HELPERS
//   // ============================================================
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
//           runSpacing: 18,
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
//       padding: EdgeInsets.only(bottom: last ? 0 : 28),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 3,
//                 height: 17,
//                 decoration: BoxDecoration(
//                   color: primary,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16.5,
//                     fontWeight: FontWeight.w700,
//                     color: textDark,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           const Divider(height: 1, color: divider),
//           const SizedBox(height: 16),
//           child,
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // BUILD
//   // ============================================================
//
//   @override
//   Widget build(BuildContext context) {
//     final mobile = MediaQuery.of(context).size.width < 700;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildPageHeader(mobile),
//             Expanded(
//               child: Form(
//                 key: _formKey,
//                 child: SingleChildScrollView(
//                   padding: EdgeInsets.fromLTRB(
//                     mobile ? 14 : 24,
//                     22,
//                     mobile ? 14 : 24,
//                     30,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildBasicSection(),
//                       _buildEmploymentSection(),
//                       _buildPersonalSection(),
//                       _buildEmergencySection(),
//                       _buildBankSection(),
//                       _buildStatusSection(),
//                       _buildActionButtons(),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // PAGE HEADER
//   // ============================================================
//
//   Widget _buildPageHeader(bool mobile) {
//     final subtitle = [
//       if (widget.employee.name.trim().isNotEmpty) widget.employee.name,
//       if (widget.employee.employeeCode.trim().isNotEmpty)
//         widget.employee.employeeCode,
//     ].join('  •  ');
//
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
//         padding: EdgeInsets.symmetric(horizontal: mobile ? 6 : 16),
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
//             const SizedBox(width: 2),
//             Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: primaryLight,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(
//                 Icons.edit_outlined,
//                 color: primary,
//                 size: 19,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Edit Employee',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                       color: textDark,
//                     ),
//                   ),
//                   const SizedBox(height: 1),
//                   Text(
//                     subtitle.isEmpty
//                         ? 'Update employee profile and contact details.'
//                         : subtitle,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: textLight,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (!mobile)
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: pageBackground,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: border),
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       Icons.admin_panel_settings_outlined,
//                       size: 16,
//                       color: textMedium,
//                     ),
//                     SizedBox(width: 6),
//                     Text(
//                       'Admin',
//                       style: TextStyle(
//                         fontSize: 12.5,
//                         fontWeight: FontWeight.w600,
//                         color: textMedium,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // BASIC INFORMATION
//   // ============================================================
//
//   Widget _buildBasicSection() {
//     return _section(
//       title: 'Basic Information',
//       child: _grid([
//         _textField(
//           label: 'Full Name',
//           controller: _nameController,
//           icon: Icons.person_outline,
//         ),
//         _textField(
//           label: 'Email',
//           controller: _emailController,
//           icon: Icons.email_outlined,
//           keyboardType: TextInputType.emailAddress,
//         ),
//         _textField(
//           label: 'Employee Code',
//           controller: _employeeCodeController,
//           icon: Icons.badge_outlined,
//         ),
//         _textField(
//           label: 'Phone Number',
//           controller: _phoneController,
//           icon: Icons.phone_outlined,
//           keyboardType: TextInputType.phone,
//         ),
//       ]),
//     );
//   }
//
//   // ============================================================
//   // EMPLOYMENT
//   // ============================================================
//
//   Widget _buildEmploymentSection() {
//     return _section(
//       title: 'Employment Information',
//       child: _grid([
//         _textField(
//           label: 'Designation',
//           controller: _designationController,
//           icon: Icons.workspace_premium_outlined,
//         ),
//
//         // ------------------------------------------------------
//         // DEPARTMENT FROM API
//         // ------------------------------------------------------
//
//         if (_isLoadingDepartments)
//           _loadingField('Department')
//         else
//           _dropdown(
//             label: 'Department',
//             value: _department,
//             items: _departments,
//             onChanged: (value) {
//               setState(() {
//                 _department = value;
//               });
//             },
//             icon: Icons.account_tree_outlined,
//           ),
//
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
//           icon: Icons.business_center_outlined,
//         ),
//
//         _dropdown(
//           label: 'Work Mode',
//           value: _workMode,
//           items: const [
//             'in_house',
//             'remote',
//             'hybrid',
//           ],
//           onChanged: (value) {
//             setState(() {
//               _workMode = value;
//             });
//           },
//           icon: Icons.location_on_outlined,
//         ),
//
//         _dateField(
//           label: 'Date of Joining',
//           value: _dateOfJoining,
//           onTap: () => _selectDate(joiningDate: true),
//           icon: Icons.calendar_month_outlined,
//         ),
//       ]),
//     );
//   }
//
//   // ============================================================
//   // PERSONAL
//   // ============================================================
//
//   Widget _buildPersonalSection() {
//     return _section(
//       title: 'Personal Information',
//       child: _grid([
//         _dropdown(
//           label: 'Gender',
//           value: _gender,
//           items: const [
//             'male',
//             'female',
//             'other',
//           ],
//           onChanged: (value) {
//             setState(() {
//               _gender = value;
//             });
//           },
//           icon: Icons.person_outline,
//         ),
//         _dateField(
//           label: 'Date of Birth',
//           value: _dateOfBirth,
//           onTap: () => _selectDate(joiningDate: false),
//           icon: Icons.cake_outlined,
//         ),
//         _textField(
//           label: 'Address',
//           controller: _addressController,
//           icon: Icons.home_outlined,
//           maxLines: 2,
//         ),
//       ]),
//     );
//   }
//
//   // ============================================================
//   // EMERGENCY CONTACT
//   // ============================================================
//
//   Widget _buildEmergencySection() {
//     return _section(
//       title: 'Emergency Contact',
//       child: _grid([
//         _textField(
//           label: 'Emergency Contact Name',
//           controller: _emergencyNameController,
//           icon: Icons.person_outline,
//         ),
//         _textField(
//           label: 'Relationship',
//           controller: _emergencyRelationshipController,
//           icon: Icons.family_restroom_outlined,
//         ),
//         _textField(
//           label: 'Emergency Phone',
//           controller: _emergencyPhoneController,
//           icon: Icons.phone_outlined,
//           keyboardType: TextInputType.phone,
//         ),
//       ]),
//     );
//   }
//
//   // ============================================================
//   // BANK DETAILS
//   // ============================================================
//
//   Widget _buildBankSection() {
//     return _section(
//       title: 'Bank Details',
//       child: _grid([
//         _textField(
//           label: 'Account Number',
//           controller: _accountNumberController,
//           icon: Icons.account_balance,
//           keyboardType: TextInputType.number,
//         ),
//         _textField(
//           label: 'IFSC Code',
//           controller: _ifscController,
//           icon: Icons.numbers,
//         ),
//         _textField(
//           label: 'Bank Name',
//           controller: _bankNameController,
//           icon: Icons.account_balance_outlined,
//         ),
//         _textField(
//           label: 'UPI ID',
//           controller: _upiController,
//           icon: Icons.payment_outlined,
//         ),
//       ]),
//     );
//   }
//
//   // ============================================================
//   // ACCOUNT STATUS
//   // ============================================================
//
//   Widget _buildStatusSection() {
//     return _section(
//       title: 'Account Status',
//       last: true,
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 12,
//         ),
//         decoration: BoxDecoration(
//           color: _isActive ? const Color(0xFFF3FBF6) : pageBackground,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: _isActive ? const Color(0xFFBFE5CC) : border,
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: _isActive ? const Color(0xFFE9F8EF) : Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 border: Border.all(
//                   color: _isActive ? const Color(0xFFBFE5CC) : border,
//                 ),
//               ),
//               child: Icon(
//                 _isActive
//                     ? Icons.check_circle_outline_rounded
//                     : Icons.pause_circle_outline_rounded,
//                 size: 22,
//                 color: _isActive ? const Color(0xFF18864B) : textMedium,
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     _isActive ? 'Active Employee' : 'Inactive Employee',
//                     style: const TextStyle(
//                       fontSize: 15.5,
//                       fontWeight: FontWeight.w700,
//                       color: textDark,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     _isActive
//                         ? 'Employee can use the system.'
//                         : 'Employee account is inactive.',
//                     style: const TextStyle(
//                       fontSize: 13,
//                       color: textMedium,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Switch(
//               value: _isActive,
//               activeColor: primary,
//               onChanged: (value) {
//                 setState(() {
//                   _isActive = value;
//                 });
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // ACTION BUTTONS (end of form)
//   // ============================================================
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
//                 onPressed: _isSaving ? null : _saveChanges,
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
//                   Icons.save_outlined,
//                   size: 19,
//                 ),
//                 label: Text(
//                   _isSaving ? 'Saving...' : 'Save Changes',
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
// }



import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Employee employee;
  final Map<String, dynamic> employeeData;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> personalDetails;

  const EditEmployeeScreen({
    super.key,
    required this.employee,
    required this.employeeData,
    required this.userData,
    required this.personalDetails,
  });

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final EmployeeService _employeeService = EmployeeService();

  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFF1EB);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFD9DEE5);
  static const Color divider = Color(0xFFE9ECF0);
  static const Color pageBackground = Color(0xFFF7F8FA);
  static const Color errorColor = Color(0xFFD32F2F);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _employeeCodeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _designationController;
  late final TextEditingController _addressController;

  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyRelationshipController;
  late final TextEditingController _emergencyPhoneController;

  late final TextEditingController _accountNumberController;

  late final TextEditingController _ifscController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _upiController;

  // ============================================================
  // DROPDOWN VALUES
  // ============================================================

  String? _department;
  String? _employmentType;
  String? _workMode;
  String? _gender;

  // Department values are loaded from API.
  List<String> _departments = [];

  bool _isLoadingDepartments = false;

  // ============================================================
  // DATES
  // ============================================================

  DateTime? _dateOfJoining;
  DateTime? _dateOfBirth;

  // ============================================================
  // STATUS
  // ============================================================

  bool _isActive = true;
  bool _isSaving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final bank = widget.employeeData['bankDetails'] is Map
        ? Map<String, dynamic>.from(
      widget.employeeData['bankDetails'],
    )
        : <String, dynamic>{};

    // ----------------------------------------------------------
    // Emergency Contact
    // ----------------------------------------------------------

    final emergency = widget.personalDetails['emergencyContact'];

    String emergencyName = '';
    String emergencyRelationship = '';
    String emergencyPhone = '';

    if (emergency is Map) {
      emergencyName = emergency['name']?.toString() ?? '';

      emergencyRelationship = emergency['relationship']?.toString() ?? '';

      emergencyPhone = emergency['phone']?.toString() ?? '';
    } else if (emergency != null) {
      emergencyPhone = emergency.toString();
    }

    // ----------------------------------------------------------
    // Basic Information
    // ----------------------------------------------------------

    _nameController = TextEditingController(
      text: widget.userData['name']?.toString() ??
          widget.employeeData['name']?.toString() ??
          widget.employee.name,
    );

    _emailController = TextEditingController(
      text: widget.userData['email']?.toString() ??
          widget.employeeData['email']?.toString() ??
          widget.employee.email,
    );

    _employeeCodeController = TextEditingController(
      text: widget.employeeData['employeeCode']?.toString() ??
          widget.employee.employeeCode,
    );

    _phoneController = TextEditingController(
      text: widget.userData['phone']?.toString() ??
          widget.employeeData['phone']?.toString() ??
          widget.personalDetails['phone']?.toString() ??
          '',
    );

    _designationController = TextEditingController(
      text: widget.employeeData['designation']?.toString() ??
          widget.employee.designation,
    );

    _addressController = TextEditingController(
      text: widget.personalDetails['address']?.toString() ?? '',
    );

    // ----------------------------------------------------------
    // Emergency
    // ----------------------------------------------------------

    _emergencyNameController = TextEditingController(
      text: emergencyName,
    );

    _emergencyRelationshipController = TextEditingController(
      text: emergencyRelationship,
    );

    _emergencyPhoneController = TextEditingController(
      text: emergencyPhone,
    );

    // ----------------------------------------------------------
    // Bank
    // ----------------------------------------------------------

    _accountNumberController = TextEditingController(
      text: bank['accountNumber']?.toString() ?? '',
    );

    _ifscController = TextEditingController(
      text: bank['ifsc']?.toString() ?? '',
    );

    _bankNameController = TextEditingController(
      text: bank['bankName']?.toString() ?? '',
    );

    _upiController = TextEditingController(
      text: bank['upiId']?.toString() ?? '',
    );

    // ----------------------------------------------------------
    // Existing values
    // ----------------------------------------------------------

    _department = widget.employeeData['department']?.toString();

    _employmentType = widget.employeeData['employmentType']?.toString();

    _workMode = widget.employeeData['workMode']?.toString();

    _gender = widget.personalDetails['gender']?.toString();

    _dateOfJoining = _parseDate(
      widget.employeeData['dateOfJoining'],
    );

    _dateOfBirth = _parseDate(
      widget.personalDetails['dob'],
    );

    _isActive =
        (widget.employeeData['status']?.toString().toLowerCase() ?? 'active') ==
            'active';

    // Load departments from API.
    _loadDepartments();
  }

  // ============================================================
  // LOAD DEPARTMENTS
  // ============================================================

  Future<void> _loadDepartments() async {
    if (!mounted) return;

    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      final response = await _apiClient.get('/departments');

      final List<String> apiDepartments = [];

      if (response is List) {
        for (final item in response) {
          if (item is Map) {
            final name = item['name']?.toString().trim() ?? '';

            if (name.isNotEmpty && !apiDepartments.contains(name)) {
              apiDepartments.add(name);
            }
          }
        }
      }

      // --------------------------------------------------------
      // Keep the employee's current department even if the
      // /departments API does not return it.
      // --------------------------------------------------------

      final currentDepartment =
          widget.employeeData['department']?.toString().trim() ?? '';

      if (currentDepartment.isNotEmpty &&
          !apiDepartments.contains(currentDepartment)) {
        apiDepartments.add(currentDepartment);
      }

      if (!mounted) return;

      setState(() {
        _departments = apiDepartments;

        if (_departments.contains(_department)) {
          // Keep selected value.
        } else if (_departments.isNotEmpty) {
          _department = _departments.first;
        } else {
          _department = null;
        }

        _isLoadingDepartments = false;
      });
    } catch (e) {
      debugPrint('DEPARTMENT API ERROR: $e');

      // --------------------------------------------------------
      // If API fails, don't create fake departments.
      // Keep only the employee's current API value.
      // --------------------------------------------------------

      final currentDepartment =
          widget.employeeData['department']?.toString().trim() ?? '';

      if (!mounted) return;

      setState(() {
        _departments = currentDepartment.isNotEmpty ? [currentDepartment] : [];

        _department = currentDepartment.isNotEmpty ? currentDepartment : null;

        _isLoadingDepartments = false;
      });
    }
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _employeeCodeController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _addressController.dispose();

    _emergencyNameController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyPhoneController.dispose();

    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _upiController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate({
    required bool joiningDate,
  }) async {
    final initialDate = joiningDate ? _dateOfJoining : _dateOfBirth;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (joiningDate) {
        _dateOfJoining = selected;
      } else {
        _dateOfBirth = selected;
      }
    });
  }

  // ============================================================
  // DATE TEXT
  // ============================================================

  String _dateText(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveChanges() async {
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

    setState(() {
      _isSaving = true;
    });

    try {
      // ========================================================
      // 1. JOB / EMPLOYMENT / BANK / STATUS FIELDS
      //
      // PUT /employees/:id
      //
      // This is the endpoint that was previously never called,
      // so department, designation, employment type, work mode,
      // date of joining, bank details and status changes were
      // silently discarded.
      // ========================================================

      await _employeeService.updateEmployee(
        employeeId: widget.employee.id,
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'employeeCode': _employeeCodeController.text.trim(),
          'designation': _designationController.text.trim(),
          'department': _department,
          'employmentType': _employmentType,
          'workMode': _workMode,
          if (_dateOfJoining != null)
            'dateOfJoining':
            _dateOfJoining!.toIso8601String().split('T').first,
          'status': _isActive ? 'active' : 'inactive',
          'bankDetails': {
            'accountNumber': _accountNumberController.text.trim(),
            'ifsc': _ifscController.text.trim(),
            'bankName': _bankNameController.text.trim(),
            'upiId': _upiController.text.trim(),
          },
          'personalDetails': {
            'gender': _gender,
            if (_dateOfBirth != null)
              'dob': _dateOfBirth!.toIso8601String().split('T').first,
          },
        },
      );

      // ========================================================
      // 2. PERSONAL / CONTACT FIELDS
      //
      // PUT /employees/:id/personal-details
      //
      // Supported fields:
      // phone
      // address
      // emergencyContact
      // ========================================================

      await _employeeService.updatePersonalDetails(
        employeeId: widget.employee.id,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        emergencyName: _emergencyNameController.text.trim(),
        emergencyRelationship: _emergencyRelationshipController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Employee details updated successfully.',
          ),
        ),
      );

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

  // ============================================================
  // MESSAGE
  // ============================================================

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

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  OutlineInputBorder _outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 14.5,
        color: textLight,
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        height: 1.1,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(
        icon,
        size: 19,
        color: textLight,
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 30,
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 30,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: icon == null ? 14 : 4,
        vertical: 16,
      ),
      border: _outline(border),
      enabledBorder: _outline(border),
      focusedBorder: _outline(primary, 1.5),
      errorBorder: _outline(errorColor),
      focusedErrorBorder: _outline(errorColor, 1.5),
    );
  }

  // ============================================================
  // LABEL ABOVE FIELD
  // ============================================================

  Widget _labeled({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13.5,
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
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return _labeled(
      label: label,
      required: true,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 15.5,
          color: textDark,
        ),
        decoration: _inputDecoration(
          hint: label,
          icon: icon,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    // ----------------------------------------------------------
    // Protection against:
    //
    // "There should be exactly one item with DropdownButton's
    // value..."
    // ----------------------------------------------------------

    final safeValue = items.contains(value) ? value : null;

    return _labeled(
      label: label,
      required: true,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 22,
          color: textMedium,
        ),
        style: const TextStyle(
          fontSize: 15.5,
          color: textDark,
        ),
        hint: const Text(
          'Select',
          style: TextStyle(
            fontSize: 14.5,
            color: textLight,
          ),
        ),
        decoration: _inputDecoration(
          hint: 'Select',
          icon: icon,
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              _formatDropdownText(item),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // DROPDOWN TEXT FORMAT
  // ============================================================

  String _formatDropdownText(String value) {
    return value.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) {
        return word;
      }

      return '${word[0].toUpperCase()}'
          '${word.substring(1)}';
    }).join(' ');
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return _labeled(
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: InputDecorator(
          decoration: _inputDecoration(
            hint: 'Select date',
            icon: icon,
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              size: 17,
              color: textMedium,
            ),
          ),
          child: Text(
            _dateText(value),
            style: TextStyle(
              fontSize: 15.5,
              color: value == null ? textLight : textDark,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING FIELD
  // ============================================================

  Widget _loadingField(String label) {
    return _labeled(
      label: label,
      required: true,
      child: InputDecorator(
        decoration: _inputDecoration(
          hint: 'Loading...',
          icon: Icons.account_tree_outlined,
        ),
        child: const Row(
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading departments...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  color: textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LAYOUT HELPERS
  // ============================================================

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
          runSpacing: 18,
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
      padding: EdgeInsets.only(bottom: last ? 0 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 17,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: divider),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildPageHeader(mobile),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 14 : 24,
                    22,
                    mobile ? 14 : 24,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicSection(),
                      _buildEmploymentSection(),
                      _buildPersonalSection(),
                      _buildEmergencySection(),
                      _buildBankSection(),
                      _buildStatusSection(),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(bool mobile) {
    final subtitle = [
      if (widget.employee.name.trim().isNotEmpty) widget.employee.name,
      if (widget.employee.employeeCode.trim().isNotEmpty)
        widget.employee.employeeCode,
    ].join('  •  ');

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
        padding: EdgeInsets.symmetric(horizontal: mobile ? 6 : 16),
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
            const SizedBox(width: 2),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Employee',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle.isEmpty
                        ? 'Update employee profile and contact details.'
                        : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!mobile)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
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
                      size: 16,
                      color: textMedium,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 12.5,
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

  // ============================================================
  // BASIC INFORMATION
  // ============================================================

  Widget _buildBasicSection() {
    return _section(
      title: 'Basic Information',
      child: _grid([
        _textField(
          label: 'Full Name',
          controller: _nameController,
          icon: Icons.person_outline,
        ),
        _textField(
          label: 'Email',
          controller: _emailController,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        _textField(
          label: 'Employee Code',
          controller: _employeeCodeController,
          icon: Icons.badge_outlined,
        ),
        _textField(
          label: 'Phone Number',
          controller: _phoneController,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ]),
    );
  }

  // ============================================================
  // EMPLOYMENT
  // ============================================================

  Widget _buildEmploymentSection() {
    return _section(
      title: 'Employment Information',
      child: _grid([
        _textField(
          label: 'Designation',
          controller: _designationController,
          icon: Icons.workspace_premium_outlined,
        ),

        // ------------------------------------------------------
        // DEPARTMENT FROM API
        // ------------------------------------------------------

        if (_isLoadingDepartments)
          _loadingField('Department')
        else
          _dropdown(
            label: 'Department',
            value: _department,
            items: _departments,
            onChanged: (value) {
              setState(() {
                _department = value;
              });
            },
            icon: Icons.account_tree_outlined,
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
          icon: Icons.business_center_outlined,
        ),

        _dropdown(
          label: 'Work Mode',
          value: _workMode,
          items: const [
            'in_house',
            'remote',
            'hybrid',
          ],
          onChanged: (value) {
            setState(() {
              _workMode = value;
            });
          },
          icon: Icons.location_on_outlined,
        ),

        _dateField(
          label: 'Date of Joining',
          value: _dateOfJoining,
          onTap: () => _selectDate(joiningDate: true),
          icon: Icons.calendar_month_outlined,
        ),
      ]),
    );
  }

  // ============================================================
  // PERSONAL
  // ============================================================

  Widget _buildPersonalSection() {
    return _section(
      title: 'Personal Information',
      child: _grid([
        _dropdown(
          label: 'Gender',
          value: _gender,
          items: const [
            'male',
            'female',
            'other',
          ],
          onChanged: (value) {
            setState(() {
              _gender = value;
            });
          },
          icon: Icons.person_outline,
        ),
        _dateField(
          label: 'Date of Birth',
          value: _dateOfBirth,
          onTap: () => _selectDate(joiningDate: false),
          icon: Icons.cake_outlined,
        ),
        _textField(
          label: 'Address',
          controller: _addressController,
          icon: Icons.home_outlined,
          maxLines: 2,
        ),
      ]),
    );
  }

  // ============================================================
  // EMERGENCY CONTACT
  // ============================================================

  Widget _buildEmergencySection() {
    return _section(
      title: 'Emergency Contact',
      child: _grid([
        _textField(
          label: 'Emergency Contact Name',
          controller: _emergencyNameController,
          icon: Icons.person_outline,
        ),
        _textField(
          label: 'Relationship',
          controller: _emergencyRelationshipController,
          icon: Icons.family_restroom_outlined,
        ),
        _textField(
          label: 'Emergency Phone',
          controller: _emergencyPhoneController,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ]),
    );
  }

  // ============================================================
  // BANK DETAILS
  // ============================================================

  Widget _buildBankSection() {
    return _section(
      title: 'Bank Details',
      child: _grid([
        _textField(
          label: 'Account Number',
          controller: _accountNumberController,
          icon: Icons.account_balance,
          keyboardType: TextInputType.number,
        ),
        _textField(
          label: 'IFSC Code',
          controller: _ifscController,
          icon: Icons.numbers,
        ),
        _textField(
          label: 'Bank Name',
          controller: _bankNameController,
          icon: Icons.account_balance_outlined,
        ),
        _textField(
          label: 'UPI ID',
          controller: _upiController,
          icon: Icons.payment_outlined,
        ),
      ]),
    );
  }

  // ============================================================
  // ACCOUNT STATUS
  // ============================================================

  Widget _buildStatusSection() {
    return _section(
      title: 'Account Status',
      last: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _isActive ? const Color(0xFFF3FBF6) : pageBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isActive ? const Color(0xFFBFE5CC) : border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isActive ? const Color(0xFFE9F8EF) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isActive ? const Color(0xFFBFE5CC) : border,
                ),
              ),
              child: Icon(
                _isActive
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                size: 22,
                color: _isActive ? const Color(0xFF18864B) : textMedium,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isActive ? 'Active Employee' : 'Inactive Employee',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isActive
                        ? 'Employee can use the system.'
                        : 'Employee account is inactive.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isActive,
              activeColor: primary,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS (end of form)
  // ============================================================

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
                onPressed: _isSaving ? null : _saveChanges,
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
                  Icons.save_outlined,
                  size: 19,
                ),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
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
}