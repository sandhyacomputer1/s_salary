// !!! UNVERIFIED REQUEST BODIES !!!
// ANDROID_API_REFERENCE documents the body of PUT /companies/:id/settings
// (working hours, minimum hours, radius, check-in options, missed check-out
// rule, week-off rule, leave types, securitySettings) but NOT:
//   - PUT /companies/:id   (company name / address / timezone / pin / active)
//   - the extra settings keys that exist in the real settings object:
//     ptSettings, lateSettings, paidLeaveRules, autoApproveLeaveIfBalanceAvailable
//   - the stored value for "Count as Full Day (Present)" (full_day is a guess)
//
// This is the ONLY file that builds those bodies. If the backend rejects a
// key, its message is shown on screen; fix it here.

import 'dart:convert';

import 'company_profile_model.dart';
import 'company_settings_model.dart';

/// Body of PUT /companies/:id
///
/// GUESS: the keys mirror the company object returned by GET /companies/me
/// (name, address, timezone, location {lat,lng}, checkInRadiusMeters,
/// isActive). A pin cannot be removed once saved (null is not sent), so the
/// profile validator requires a pin.
class CompanyProfileRequest {
  const CompanyProfileRequest(this.profile);

  final CompanyProfile profile;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'name': profile.name.trim(),
      'address': profile.address.trim(),
      'timezone': profile.timezone.trim(),
      'checkInRadiusMeters': profile.radiusMeters,
      'isActive': profile.isActive,
    };

    if (profile.hasPin) {
      body['location'] = {'lat': profile.latitude, 'lng': profile.longitude};
    }

    return body;
  }
}

/// Body of PUT /companies/:id/settings
///
/// Strategy: start from a copy of the settings object the server sent
/// ([CompanySettings.raw]), apply only the edited values, and drop
///   - server metadata:   _id, id, companyId, createdAt, updatedAt, __v
///   - runtime state:     dayControl
///   - legacy aliases:    workShiftStart, workShiftEnd, gracePeriodMinutes,
///                        weekOffDay, minWorkHoursFullDay, minWorkHoursHalfDay
/// (the API reference says aliases are mapped server-side, so sending stale
/// aliases next to the new values could overwrite an edit).
/// Everything else the screen does not edit (pfSettings, rolePermissions,
/// ...) is sent back unchanged, so a backend that replaces instead of merging
/// cannot wipe it.
class SettingsPayload {
  SettingsPayload._();

  static const List<String> removedKeys = [
    '_id',
    'id',
    'companyId',
    'createdAt',
    'updatedAt',
    '__v',
    'dayControl',
    'workShiftStart',
    'workShiftEnd',
    'gracePeriodMinutes',
    'weekOffDay',
    'minWorkHoursFullDay',
    'minWorkHoursHalfDay',
  ];

  static Map<String, dynamic> _copy(dynamic value) {
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  }

  /// 8.0 -> 8 so whole numbers are sent as integers.
  static num _num(double value) =>
      value == value.roundToDouble() ? value.toInt() : value;

  static Map<String, dynamic> build(
    CompanySettings s, {
    required int radiusMeters,
  }) {
    final body = _copy(s.raw);

    for (final key in removedKeys) {
      body.remove(key);
    }

    // ---- documented keys ----------------------------------------------
    body['workingHours'] = {
      ..._copy(body['workingHours']),
      'start': s.startTime.trim(),
      'end': s.endTime.trim(),
      'graceMinutes': s.graceMinutes,
    };

    body['minimumFullDayHours'] = _num(s.minFullDayHours);
    body['minimumHalfDayHours'] = _num(s.minHalfDayHours);
    body['checkInRadiusMeters'] = radiusMeters;

    body['allowMultipleCheckInPerDay'] = s.allowMultipleCheckIn;
    body['requirePhotoOnCheckIn'] = s.requirePhotoOnCheckIn;
    body['requirePhotoOnCheckOut'] = s.requirePhotoOnCheckOut;
    body['missedCheckOutRule'] = s.missedCheckOutRule;

    final usesFixed = s.weekOffType != WeekOffType.nthWeekday;
    final usesNth = s.weekOffType != WeekOffType.fixedDays;

    body['weekOffRule'] = {
      ..._copy(body['weekOffRule']),
      'type': s.weekOffType,
      'fixedDays': usesFixed ? s.fixedDays : <String>[],
      'nthWeekdayRules': usesNth
          ? s.nthRules.map((r) => {'nth': r.nth, 'day': r.day}).toList()
          : <Map<String, dynamic>>[],
    };

    body['leaveTypes'] = s.leaveTypes
        .map(
          (l) => {
            'name': l.name.trim(),
            'daysPerYear': _num(l.daysPerYear),
            'isPaid': l.isPaid,
          },
        )
        .toList();

    body['securitySettings'] = {
      ..._copy(body['securitySettings']),
      'enforce2FA': s.enforce2FA,
    };

    // ---- keys present in the real settings object, not in the docs -----
    body['lateSettings'] = {
      ..._copy(body['lateSettings']),
      'enabled': s.lateEnabled,
      'lateThreshold': s.lateThreshold,
      'deductionDays': _num(s.lateDeductionDays),
    };

    body['ptSettings'] = {
      ..._copy(body['ptSettings']),
      'enabled': s.ptEnabled,
      'slabs': s.ptSlabs.map((slab) {
        final item = <String, dynamic>{
          'minSalary': _num(slab.minSalary),
          'maxSalary': _num(slab.maxSalary),
          'ptAmount': _num(slab.ptAmount),
        };
        if (slab.febAmount != null) item['febAmount'] = _num(slab.febAmount!);
        return item;
      }).toList(),
    };

    body['paidLeaveRules'] = {
      ..._copy(body['paidLeaveRules']),
      'maxPaidLeavesPerMonth': s.maxPaidLeavesPerMonth,
      'maxConsecutiveLeaveDays': s.maxConsecutiveLeaveDays,
      'enforceSandwichRule': s.enforceSandwichRule,
    };

    body['autoApproveLeaveIfBalanceAvailable'] = s.autoApproveLeave;

    return body;
  }
}

// =================================================================
// VALIDATION
// =================================================================

/// First problem found, plus the tab it belongs to so the screen can jump
/// there. Tab indexes: 0 profile, 1 shift, 2 late, 3 pt, 4 leave, 5 security.
class SettingsIssue {
  const SettingsIssue(this.tab, this.message);

  final int tab;
  final String message;
}

class SettingsValidator {
  SettingsValidator._();

  static final RegExp _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  static int _minutes(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static SettingsIssue? profile(CompanyProfile p) {
    if (p.name.trim().isEmpty) {
      return const SettingsIssue(0, 'Company name is required.');
    }
    if (p.timezone.trim().isEmpty) {
      return const SettingsIssue(0, 'Timezone is required.');
    }
    if (p.radiusMeters < 10 || p.radiusMeters > 5000) {
      return const SettingsIssue(
        0,
        'Geofence radius must be between 10 and 5000 meters.',
      );
    }
    if (!CompanyProfile.isValidPoint(p.latitude, p.longitude)) {
      return const SettingsIssue(
        0,
        'Set the office location on the map before saving.',
      );
    }
    return null;
  }

  static SettingsIssue? settings(CompanySettings s) {
    // ---- shift ----
    if (!_time.hasMatch(s.startTime) || !_time.hasMatch(s.endTime)) {
      return const SettingsIssue(1, 'Shift times must be in HH:mm format.');
    }
    if (_minutes(s.endTime) <= _minutes(s.startTime)) {
      return const SettingsIssue(1, 'Shift end must be after shift start.');
    }
    if (s.graceMinutes < 0 || s.graceMinutes > 240) {
      return const SettingsIssue(1, 'Grace minutes must be between 0 and 240.');
    }
    if (s.minHalfDayHours <= 0 || s.minFullDayHours > 24) {
      return const SettingsIssue(1, 'Minimum hours must be between 0 and 24.');
    }
    if (s.minHalfDayHours >= s.minFullDayHours) {
      return const SettingsIssue(
        1,
        'Half-day hours must be less than full-day hours.',
      );
    }
    if (s.weekOffType != WeekOffType.nthWeekday && s.fixedDays.isEmpty) {
      return const SettingsIssue(1, 'Select at least one weekly off day.');
    }
    if (s.weekOffType != WeekOffType.fixedDays && s.nthRules.isEmpty) {
      return const SettingsIssue(1, 'Add at least one nth-weekday rule.');
    }

    // ---- late rules ----
    if (s.lateEnabled) {
      if (s.lateThreshold < 1) {
        return const SettingsIssue(2, 'Late threshold must be at least 1.');
      }
      if (s.lateDeductionDays < 0) {
        return const SettingsIssue(2, 'Deduction days cannot be negative.');
      }
    }

    // ---- PT slabs ----
    if (s.ptEnabled) {
      if (s.ptSlabs.isEmpty) {
        return const SettingsIssue(3, 'Add at least one PT slab.');
      }

      final slabs = [...s.ptSlabs]
        ..sort((a, b) => a.minSalary.compareTo(b.minSalary));

      for (var i = 0; i < slabs.length; i++) {
        final slab = slabs[i];

        if (slab.minSalary < 0 ||
            slab.maxSalary < slab.minSalary ||
            slab.ptAmount < 0 ||
            (slab.febAmount != null && slab.febAmount! < 0)) {
          return SettingsIssue(
            3,
            'PT slab ${i + 1}: check the salary range and amounts.',
          );
        }

        if (i > 0 && slab.minSalary <= slabs[i - 1].maxSalary) {
          return SettingsIssue(
            3,
            'PT slabs $i and ${i + 1} overlap. Each slab must start above '
            'the previous maximum.',
          );
        }
      }
    }

    // ---- leave ----
    if (s.maxPaidLeavesPerMonth < 0 || s.maxConsecutiveLeaveDays < 0) {
      return const SettingsIssue(4, 'Leave limits cannot be negative.');
    }

    final seen = <String>{};
    for (final type in s.leaveTypes) {
      final name = type.name.trim();

      if (name.isEmpty) {
        return const SettingsIssue(4, 'Every leave type needs a name.');
      }
      if (type.daysPerYear < 0) {
        return SettingsIssue(4, '"$name": days per year cannot be negative.');
      }
      if (!seen.add(name.toLowerCase())) {
        return SettingsIssue(4, 'Leave type "$name" is listed twice.');
      }
    }

    return null;
  }
}
