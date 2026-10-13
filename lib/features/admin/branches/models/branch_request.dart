// !!! UNVERIFIED REQUEST BODY !!!
// ANDROID_API_REFERENCE does not document the body of
//   POST /companies/branches   and   PUT /companies/branches/:branchId
//
// Evidence for the key names:
//   - name, address, location {lat,lng}, checkInRadiusMeters:
//       taken from the branch "company" object returned by GET.
//   - workShiftStart, workShiftEnd, gracePeriodMinutes, weekOffDay:
//       legacy aliases the API reference says the settings endpoint accepts.
//   - code, adminName, adminEmail, adminPhone, adminPassword:
//       pure guesses.

class BranchRequest {
  final String name;
  final String code;
  final String address;
  final String adminName;
  final String adminEmail;
  final String adminPhone;
  final String password;
  final String latitude;
  final String longitude;
  final String radius;
  final String shiftStart;
  final String shiftEnd;
  final String grace;
  final String weeklyOff;

  const BranchRequest({
    required this.name,
    required this.code,
    required this.address,
    required this.adminName,
    required this.adminEmail,
    required this.adminPhone,
    required this.password,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.shiftStart,
    required this.shiftEnd,
    required this.grace,
    required this.weeklyOff,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'name': name.trim(),
      'code': code.trim(), // GUESS: could be branchCode
    };

    void put(String key, Object? value) {
      if (value != null) body[key] = value;
    }

    String? clean(String v) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    put('address', clean(address));

    // GUESS: flat admin* keys (could be a nested `admin: {...}` object).
    put('adminName', clean(adminName));
    put('adminEmail', clean(adminEmail));
    put('adminPhone', clean(adminPhone));

    // Never trimmed, and not sent when blank, so editing a branch
    // keeps the stored password.
    put('adminPassword', password.isEmpty ? null : password);

    final lat = double.tryParse(latitude.trim());
    final lng = double.tryParse(longitude.trim());

    if (lat != null && lng != null) {
      body['location'] = {'lat': lat, 'lng': lng};
    }

    put('checkInRadiusMeters', int.tryParse(radius.trim()));
    put('workShiftStart', clean(shiftStart));
    put('workShiftEnd', clean(shiftEnd));
    put('gracePeriodMinutes', int.tryParse(grace.trim()));
    put('weekOffDay', clean(weeklyOff));

    return body;
  }
}