import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/routes/app_routes.dart';
import '../models/branch_model.dart';
import '../models/branch_request.dart';
import '../services/branch_location_service.dart';
import '../services/branch_service.dart';
import 'branch_validators.dart';

class BranchForm extends StatefulWidget {
  const BranchForm({super.key, this.branch, this.showHeader = true});

  /// null => create mode, otherwise edit mode.
  final BranchModel? branch;

  /// The dialog shows its own title row; the full-screen page uses an AppBar.
  final bool showHeader;

  static const double _wideBreakpoint = 700;

  static Future<bool?> show(BuildContext context, {BranchModel? branch}) {
    final isEdit = branch != null;
    final wide = MediaQuery.of(context).size.width >= _wideBreakpoint;

    if (wide) {
      return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: BranchForm(branch: branch),
          ),
        ),
      );
    }

    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Text(
              isEdit ? 'Edit Branch' : 'Create Company Sub-Branch',
              style: const TextStyle(
                color: Color(0xFF18212F),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: SafeArea(
            child: BranchForm(branch: branch, showHeader: false),
          ),
        ),
      ),
    );
  }

  @override
  State<BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends State<BranchForm> {
  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _fieldBorder = Color(0xFFD9DEE7);
  static const Color _danger = Color(0xFFDC2626);

  final _formKey = GlobalKey<FormState>();
  final BranchAdminService _service = BranchAdminService();

  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _address;
  late final TextEditingController _adminName;
  late final TextEditingController _adminEmail;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _radius;
  late final TextEditingController _shiftStart;
  late final TextEditingController _shiftEnd;
  late final TextEditingController _grace;
  late String _weekOff;

  bool _saving = false;
  bool _detecting = false;
  bool _obscure = true;

  String? _error; // backend / save error banner
  String? _gpsError;
  LocationFailure? _gpsFailure;

  bool get _isEdit => widget.branch != null;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;

    String t(String? v) => v ?? '';

    _name = TextEditingController(text: t(b?.name));
    _code = TextEditingController(text: t(b?.code));
    _address = TextEditingController(text: t(b?.address));
    _adminName = TextEditingController(text: t(b?.admin?.name));
    _adminEmail = TextEditingController(text: t(b?.admin?.email));
    _phone = TextEditingController(text: t(b?.admin?.phone));
    _password = TextEditingController(); // never pre-filled
    _lat = TextEditingController(
      text: b?.latitude != null
          ? BranchLocationService.format(b!.latitude!)
          : '',
    );
    _lng = TextEditingController(
      text: b?.longitude != null
          ? BranchLocationService.format(b!.longitude!)
          : '',
    );
    _radius = TextEditingController(
      text: b?.checkInRadiusMeters?.toString() ?? '100',
    );
    _shiftStart = TextEditingController(text: b?.settings.shiftStart ?? '09:00');
    _shiftEnd = TextEditingController(text: b?.settings.shiftEnd ?? '18:00');
    _grace = TextEditingController(
      text: b?.settings.graceMinutes?.toString() ?? '15',
    );

    final w = b?.settings.weekOffDay;
    _weekOff = (w != null && BranchValidators.weekDays.contains(w))
        ? w
        : 'Sunday';
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _code,
      _address,
      _adminName,
      _adminEmail,
      _phone,
      _password,
      _lat,
      _lng,
      _radius,
      _shiftStart,
      _shiftEnd,
      _grace,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Future<void> _pickTime(TextEditingController c) async {
    var initial = const TimeOfDay(hour: 9, minute: 0);
    final text = c.text.trim();
    if (BranchValidators.time(text, 'Time') == null && text.isNotEmpty) {
      final p = text.split(':');
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

    c.text = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _detectGps() async {
    if (_detecting || _saving) return;

    setState(() {
      _detecting = true;
      _gpsError = null;
      _gpsFailure = null;
    });

    try {
      final pos = await BranchLocationService.detect();
      if (!mounted) return;
      _lat.text = BranchLocationService.format(pos.latitude);
      _lng.text = BranchLocationService.format(pos.longitude);
    } on LocationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _gpsError = e.message;
        _gpsFailure = e;
      });
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return; // prevent duplicate submissions
    FocusScope.of(context).unfocus();

    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = BranchRequest(
      name: _name.text,
      code: _code.text,
      address: _address.text,
      adminName: _adminName.text,
      adminEmail: _adminEmail.text,
      adminPhone: _phone.text,
      password: _password.text,
      latitude: _lat.text,
      longitude: _lng.text,
      radius: _radius.text,
      shiftStart: _shiftStart.text,
      shiftEnd: _shiftEnd.text,
      grace: _grace.text,
      weeklyOff: _weekOff,
    ).toJson();

    setState(() => _saving = true);

    try {
      if (_isEdit) {
        await _service.updateBranch(widget.branch!.id, payload);
      } else {
        await _service.createBranch(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on BranchException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
              (route) => false,
        );
        return;
      }
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the branch. Please try again.';
      });
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, c) => _formBody(two: c.maxWidth >= 520),
        ),
      ),
    );

    return Column(
      mainAxisSize: widget.showHeader ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (widget.showHeader) _header(),
        widget.showHeader ? Flexible(child: scroll) : Expanded(child: scroll),
        _footer(),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEdit ? 'Edit Branch' : 'Create Company Sub-Branch',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final cancel = OutlinedButton(
      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: _fieldBorder),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Cancel'),
    );

    final save = FilledButton(
      onPressed: _saving ? null : _save,
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _saving
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
          : Text(_isEdit ? 'Save Changes' : 'Save Sub-Branch'),
    );

    final stretch = !widget.showHeader;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (stretch) Expanded(child: cancel) else cancel,
          const SizedBox(width: 10),
          if (stretch) Expanded(child: save) else save,
        ],
      ),
    );
  }

  Widget _formBody({required bool two}) {
    const gap = SizedBox(height: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) _errorBanner(_error!),

        // ---------------- A. BRANCH IDENTITY ----------------
        _section('Branch Identity'),
        _row(
          two,
          _labeled(
            'Branch Name *',
            TextFormField(
              controller: _name,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: _dec(hint: 'e.g. Mumbai Regional Office'),
              validator: (v) => BranchValidators.required(v, 'Branch name'),
            ),
          ),
          _labeled(
            'Branch Code *',
            TextFormField(
              controller: _code,
              enabled: !_saving,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: _dec(hint: 'e.g. MUM-01'),
              validator: (v) => BranchValidators.required(v, 'Branch code'),
            ),
          ),
        ),
        gap,
        _labeled(
          'Branch Address',
          TextFormField(
            controller: _address,
            enabled: !_saving,
            textInputAction: TextInputAction.next,
            decoration: _dec(hint: 'Building, Street, City, State'),
          ),
        ),

        // ---------------- B. ADMIN CREDENTIALS ----------------
        _section('Sub-Branch Admin Credentials (Portal Login)'),
        _row(
          two,
          _labeled(
            _isEdit ? 'Branch Admin Name' : 'Branch Admin Name *',
            TextFormField(
              controller: _adminName,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: _dec(hint: 'e.g. Rajesh Kumar'),
              validator: (v) => _isEdit
                  ? null
                  : BranchValidators.required(v, 'Admin name'),
            ),
          ),
          _labeled(
            _isEdit ? 'Login Email' : 'Login Email *',
            TextFormField(
              controller: _adminEmail,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _dec(hint: 'e.g. mumbai.admin@company.com'),
              validator: (v) =>
                  BranchValidators.email(v, isRequired: !_isEdit),
            ),
          ),
        ),
        gap,
        _row(
          two,
          _labeled(
            'Phone Number',
            TextFormField(
              controller: _phone,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: _dec(hint: 'e.g. 9876543210'),
              validator: BranchValidators.phone,
            ),
          ),
          _labeled(
            _isEdit ? 'New Password (optional)' : 'Login Password *',
            TextFormField(
              controller: _password,
              enabled: !_saving,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: _dec(
                hint: _isEdit
                    ? 'Leave blank to keep current password'
                    : 'Min 6 characters',
                suffix: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  BranchValidators.password(v, isRequired: !_isEdit),
            ),
          ),
        ),

        // ---------------- C. GPS & GEOFENCING ----------------
        _section(
          'GPS & Geofencing Settings',
          trailing: OutlinedButton.icon(
            onPressed: (_detecting || _saving) ? null : _detectGps,
            icon: _detecting
                ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.my_location_rounded, size: 17),
            label: const Text('Detect Live GPS Location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _fieldBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (_gpsError != null) ...[
          _gpsMessage(),
          gap,
        ],
        _row(
          two,
          _labeled(
            'Latitude',
            TextFormField(
              controller: _lat,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: _dec(hint: 'e.g. 19.0760'),
              validator: (v) =>
              BranchValidators.latitude(v) ??
                  BranchValidators.latLngPair(_lat.text, _lng.text),
            ),
          ),
          _labeled(
            'Longitude',
            TextFormField(
              controller: _lng,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: _dec(hint: 'e.g. 72.8777'),
              validator: BranchValidators.longitude,
            ),
          ),
        ),
        gap,
        _labeled(
          'Check-in Radius (Meters)',
          TextFormField(
            controller: _radius,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            decoration: _dec(hint: 'e.g. 100'),
            validator: BranchValidators.radius,
          ),
        ),

        // ---------------- D. FEATURES & RULES ----------------
        _section('Branch Specific Features & Rules'),
        _row(
          two,
          _labeled(
            'Shift Start Time',
            _timeField(
              _shiftStart,
                  (v) => BranchValidators.time(v, 'Shift start'),
            ),
          ),
          _labeled(
            'Shift End Time',
            _timeField(
              _shiftEnd,
                  (v) =>
              BranchValidators.time(v, 'Shift end') ??
                  BranchValidators.shiftOrder(_shiftStart.text, v),
            ),
          ),
        ),
        gap,
        _row(
          two,
          _labeled(
            'Grace Period (Minutes)',
            TextFormField(
              controller: _grace,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              decoration: _dec(hint: 'e.g. 15'),
              validator: BranchValidators.grace,
            ),
          ),
          _labeled(
            'Weekly Off Day',
            DropdownButtonFormField<String>(
              initialValue: _weekOff,
              isExpanded: true,
              decoration: _dec(),
              items: [
                for (final d in BranchValidators.weekDays)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                if (v != null) setState(() => _weekOff = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SMALL BUILDERS
  // ==========================================================

  Widget _timeField(
      TextEditingController c,
      String? Function(String?) validator,
      ) {
    return TextFormField(
      controller: c,
      enabled: !_saving,
      readOnly: true,
      onTap: _saving ? null : () => _pickTime(c),
      decoration: _dec(
        hint: 'HH:mm',
        suffix: const Icon(Icons.access_time_rounded, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _row(bool two, Widget a, Widget b) {
    if (two) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 16),
          Expanded(child: b),
        ],
      );
    }
    return Column(children: [a, const SizedBox(height: 14), b]);
  }

  Widget _labeled(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _section(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              spacing: 10,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade700,
                  ),
                ),
                ?trailing,              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: _danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9B1C1C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gpsMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.location_off_outlined, size: 17, color: _danger),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _gpsError!,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF9B1C1C)),
          ),
        ),
        if (_gpsFailure?.needsSettings ?? false)
          TextButton(
            onPressed: () => BranchLocationService.openSettings(_gpsFailure!),
            child: const Text('Open settings'),
          ),
      ],
    );
  }

  InputDecoration _dec({String? hint, Widget? suffix}) {
    OutlineInputBorder outline(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: outline(_fieldBorder),
      enabledBorder: outline(_fieldBorder),
      disabledBorder: outline(const Color(0xFFEDEFF3)),
      focusedBorder: outline(_primary),
      errorBorder: outline(_danger),
      focusedErrorBorder: outline(_danger),
    );
  }
}