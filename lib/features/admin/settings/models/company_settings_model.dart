import 'dart:convert';

import 'company_profile_model.dart';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  final d = double.tryParse(v.toString());
  return d?.toInt();
}

String _text(dynamic v, [String fallback = '']) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? fallback : s;
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> _asList(dynamic v) => v is List ? v : const [];

const List<String> kWeekDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// weekOffRule.type values (documented: fixed_days | nth_weekday | both).
class WeekOffType {
  WeekOffType._();

  static const String fixedDays = 'fixed_days';
  static const String nthWeekday = 'nth_weekday';
  static const String both = 'both';

  static const List<String> all = [fixedDays, nthWeekday, both];

  static String label(String type) {
    switch (type) {
      case nthWeekday:
        return 'Nth Weekday (e.g. 2nd Friday)';
      case both:
        return 'Fixed Days + Nth Weekday';
      case fixedDays:
      default:
        return 'Fixed Days (e.g. Sat & Sun)';
    }
  }
}

/// missedCheckOutRule values.
///   half_day : documented in the API reference.
///   full_day : NOT documented; the stored value for "Count as Full Day
///              (Present)" is a guess. Check it with the web app's payload.
class MissedCheckOutRule {
  MissedCheckOutRule._();

  static const String halfDay = 'half_day';
  static const String fullDay = 'full_day';
}

class NthWeekdayRule {
  NthWeekdayRule({required this.nth, required this.day});

  int nth; // 1..5
  String day;

  factory NthWeekdayRule.fromJson(Map<String, dynamic> json) => NthWeekdayRule(
    nth: _toInt(json['nth']) ?? 1,
    day: _text(json['day'], 'Monday'),
  );

  NthWeekdayRule copy() => NthWeekdayRule(nth: nth, day: day);
}

class PtSlab {
  PtSlab({
    required this.minSalary,
    required this.maxSalary,
    required this.ptAmount,
    this.febAmount,
  });

  double minSalary;
  double maxSalary;
  double ptAmount;

  /// February-only amount; null means "use the monthly amount".
  double? febAmount;

  factory PtSlab.fromJson(Map<String, dynamic> json) => PtSlab(
    minSalary: _toDouble(json['minSalary']) ?? 0,
    maxSalary: _toDouble(json['maxSalary']) ?? 0,
    ptAmount: _toDouble(json['ptAmount']) ?? 0,
    febAmount: _toDouble(json['febAmount']),
  );

  PtSlab copy() => PtSlab(
    minSalary: minSalary,
    maxSalary: maxSalary,
    ptAmount: ptAmount,
    febAmount: febAmount,
  );
}

class LeaveTypeRule {
  LeaveTypeRule({
    required this.name,
    required this.daysPerYear,
    required this.isPaid,
  });

  String name;
  double daysPerYear;
  bool isPaid;

  factory LeaveTypeRule.fromJson(Map<String, dynamic> json) => LeaveTypeRule(
    name: _text(json['name']),
    daysPerYear: _toDouble(json['daysPerYear']) ?? 0,
    isPaid: json['isPaid'] != false,
  );

  LeaveTypeRule copy() =>
      LeaveTypeRule(name: name, daysPerYear: daysPerYear, isPaid: isPaid);
}

/// Editable company settings (the six tabs).
///
/// [raw] is the settings object exactly as the server sent it. When saving,
/// the edits are applied on top of a copy of [raw] (see settings_request.dart)
/// so keys this screen doesn't edit are sent back unchanged.
class CompanySettings {
  CompanySettings({
    required this.raw,
    required this.startTime,
    required this.endTime,
    required this.graceMinutes,
    required this.minFullDayHours,
    required this.minHalfDayHours,
    required this.missedCheckOutRule,
    required this.allowMultipleCheckIn,
    required this.requirePhotoOnCheckIn,
    required this.requirePhotoOnCheckOut,
    required this.weekOffType,
    required this.fixedDays,
    required this.nthRules,
    required this.lateEnabled,
    required this.lateThreshold,
    required this.lateDeductionDays,
    required this.ptEnabled,
    required this.ptSlabs,
    required this.maxPaidLeavesPerMonth,
    required this.maxConsecutiveLeaveDays,
    required this.enforceSandwichRule,
    required this.autoApproveLeave,
    required this.leaveTypes,
    required this.enforce2FA,
  });

  final Map<String, dynamic> raw;

  // Shift & Work Timings
  String startTime; // HH:mm
  String endTime; // HH:mm
  int graceMinutes;
  double minFullDayHours;
  double minHalfDayHours;
  String missedCheckOutRule;
  bool allowMultipleCheckIn;
  bool requirePhotoOnCheckIn;
  bool requirePhotoOnCheckOut;
  String weekOffType;
  List<String> fixedDays;
  List<NthWeekdayRule> nthRules;

  // Late Attendance Rules
  bool lateEnabled;
  int lateThreshold;
  double lateDeductionDays;

  // Professional Tax
  bool ptEnabled;
  List<PtSlab> ptSlabs;

  // Leave Types & Quotas
  int maxPaidLeavesPerMonth;
  int maxConsecutiveLeaveDays;
  bool enforceSandwichRule;
  bool autoApproveLeave;
  List<LeaveTypeRule> leaveTypes;

  // Security & 2FA
  bool enforce2FA;

  /// Parses the `settings` object of GET /companies/me.
  factory CompanySettings.fromResponse(dynamic body) {
    final root = _asMap(body);
    final json = root['settings'] is Map ? _asMap(root['settings']) : root;
    return CompanySettings.fromJson(json);
  }

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    final hours = _asMap(json['workingHours']);
    final weekOff = _asMap(json['weekOffRule']);
    final late = _asMap(json['lateSettings']);
    final pt = _asMap(json['ptSettings']);
    final paid = _asMap(json['paidLeaveRules']);
    final security = _asMap(json['securitySettings']);

    // Fixed days: the rule first, the legacy single weekOffDay as a fallback.
    var fixed = _asList(weekOff['fixedDays']).map((e) => e.toString()).toList();
    if (fixed.isEmpty && weekOff.isEmpty) {
      final legacy = _text(json['weekOffDay']);
      if (legacy.isNotEmpty) fixed = [legacy];
    }

    return CompanySettings(
      raw: Map<String, dynamic>.from(json),
      startTime: _text(hours['start'] ?? json['workShiftStart'], '09:00'),
      endTime: _text(hours['end'] ?? json['workShiftEnd'], '18:00'),
      graceMinutes:
          _toInt(hours['graceMinutes'] ?? json['gracePeriodMinutes']) ?? 15,
      minFullDayHours:
          _toDouble(
            json['minimumFullDayHours'] ?? json['minWorkHoursFullDay'],
          ) ??
          8,
      minHalfDayHours:
          _toDouble(
            json['minimumHalfDayHours'] ?? json['minWorkHoursHalfDay'],
          ) ??
          4,
      missedCheckOutRule: _text(
        json['missedCheckOutRule'],
        MissedCheckOutRule.halfDay,
      ),
      allowMultipleCheckIn: json['allowMultipleCheckInPerDay'] == true,
      requirePhotoOnCheckIn: json['requirePhotoOnCheckIn'] == true,
      requirePhotoOnCheckOut: json['requirePhotoOnCheckOut'] == true,
      weekOffType: _text(weekOff['type'], WeekOffType.fixedDays),
      fixedDays: fixed,
      nthRules: _asList(weekOff['nthWeekdayRules'])
          .whereType<Map>()
          .map((e) => NthWeekdayRule.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      lateEnabled: late['enabled'] == true,
      lateThreshold: _toInt(late['lateThreshold']) ?? 3,
      lateDeductionDays: _toDouble(late['deductionDays']) ?? 1,
      ptEnabled: pt['enabled'] == true,
      ptSlabs: _asList(pt['slabs'])
          .whereType<Map>()
          .map((e) => PtSlab.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      maxPaidLeavesPerMonth: _toInt(paid['maxPaidLeavesPerMonth']) ?? 2,
      maxConsecutiveLeaveDays: _toInt(paid['maxConsecutiveLeaveDays']) ?? 2,
      enforceSandwichRule: paid['enforceSandwichRule'] == true,
      autoApproveLeave: json['autoApproveLeaveIfBalanceAvailable'] == true,
      leaveTypes: _asList(json['leaveTypes'])
          .whereType<Map>()
          .map((e) => LeaveTypeRule.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      enforce2FA: security['enforce2FA'] == true,
    );
  }

  /// Deep working copy (raw is shared; it is never modified).
  CompanySettings copy() => CompanySettings(
    raw: raw,
    startTime: startTime,
    endTime: endTime,
    graceMinutes: graceMinutes,
    minFullDayHours: minFullDayHours,
    minHalfDayHours: minHalfDayHours,
    missedCheckOutRule: missedCheckOutRule,
    allowMultipleCheckIn: allowMultipleCheckIn,
    requirePhotoOnCheckIn: requirePhotoOnCheckIn,
    requirePhotoOnCheckOut: requirePhotoOnCheckOut,
    weekOffType: weekOffType,
    fixedDays: List<String>.from(fixedDays),
    nthRules: nthRules.map((e) => e.copy()).toList(),
    lateEnabled: lateEnabled,
    lateThreshold: lateThreshold,
    lateDeductionDays: lateDeductionDays,
    ptEnabled: ptEnabled,
    ptSlabs: ptSlabs.map((e) => e.copy()).toList(),
    maxPaidLeavesPerMonth: maxPaidLeavesPerMonth,
    maxConsecutiveLeaveDays: maxConsecutiveLeaveDays,
    enforceSandwichRule: enforceSandwichRule,
    autoApproveLeave: autoApproveLeave,
    leaveTypes: leaveTypes.map((e) => e.copy()).toList(),
    enforce2FA: enforce2FA,
  );

  /// Changes whenever any editable value changes (used for "unsaved changes").
  String get fingerprint => jsonEncode({
    'start': startTime,
    'end': endTime,
    'grace': graceMinutes,
    'full': minFullDayHours,
    'half': minHalfDayHours,
    'missed': missedCheckOutRule,
    'multi': allowMultipleCheckIn,
    'photoIn': requirePhotoOnCheckIn,
    'photoOut': requirePhotoOnCheckOut,
    'weekType': weekOffType,
    'fixed': fixedDays,
    'nth': nthRules.map((e) => [e.nth, e.day]).toList(),
    'late': [lateEnabled, lateThreshold, lateDeductionDays],
    'pt': ptEnabled,
    'slabs': ptSlabs
        .map((e) => [e.minSalary, e.maxSalary, e.ptAmount, e.febAmount])
        .toList(),
    'paid': [
      maxPaidLeavesPerMonth,
      maxConsecutiveLeaveDays,
      enforceSandwichRule,
      autoApproveLeave,
    ],
    'leaveTypes': leaveTypes
        .map((e) => [e.name, e.daysPerYear, e.isPaid])
        .toList(),
    '2fa': enforce2FA,
  });
}

/// Everything GET /companies/me returns that this screen uses.
class CompanyBundle {
  const CompanyBundle({required this.profile, required this.settings});

  final CompanyProfile profile;
  final CompanySettings settings;

  factory CompanyBundle.fromResponse(dynamic body) => CompanyBundle(
    profile: CompanyProfile.fromResponse(body),
    settings: CompanySettings.fromResponse(body),
  );
}
