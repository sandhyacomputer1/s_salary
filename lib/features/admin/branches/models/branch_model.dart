// Parses ONE element of the GET /companies/branches response array:
// { company: {...}, admin: {...}, settings: {...}, license: null, activeEmployees: 11 }

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

class BranchAdmin {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isActive;

  const BranchAdmin({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.isActive = true,
  });

  factory BranchAdmin.fromJson(Map<String, dynamic> j) => BranchAdmin(
    id: (j['_id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
    phone: j['phone']?.toString(),
    isActive: j['isActive'] != false,
  );
}

class BranchSettings {
  final String? shiftStart; // "HH:mm"
  final String? shiftEnd; // "HH:mm"
  final int? graceMinutes;
  final String? weekOffDay;

  const BranchSettings({
    this.shiftStart,
    this.shiftEnd,
    this.graceMinutes,
    this.weekOffDay,
  });

  factory BranchSettings.fromJson(Map<String, dynamic> j) {
    final wh = _asMap(j['workingHours']);
    return BranchSettings(
      shiftStart: (j['workShiftStart'] ?? wh['start'])?.toString(),
      shiftEnd: (j['workShiftEnd'] ?? wh['end'])?.toString(),
      graceMinutes: _toInt(j['gracePeriodMinutes'] ?? wh['graceMinutes']),
      weekOffDay: j['weekOffDay']?.toString(),
    );
  }
}

class BranchModel {
  final String id; // company._id
  final String name;
  final String? address;
  final bool isBranch; // false => Headquarters
  final String? parentCompanyId;
  final double? latitude;
  final double? longitude;
  final int? checkInRadiusMeters;
  final String? timezone;
  final bool isActive;

  /// Not present in the sample payload (the web UI shows "HQ" for HQ).
  final String? code;

  final BranchAdmin? admin;
  final BranchSettings settings;
  final int activeEmployees;

  const BranchModel({
    required this.id,
    required this.name,
    required this.isBranch,
    required this.isActive,
    required this.settings,
    this.address,
    this.parentCompanyId,
    this.latitude,
    this.longitude,
    this.checkInRadiusMeters,
    this.timezone,
    this.code,
    this.admin,
    this.activeEmployees = 0,
  });

  bool get isHeadquarters => !isBranch;
  bool get hasGps => latitude != null && longitude != null;

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final c = _asMap(json['company']);
    final loc = _asMap(c['location']);
    final adminJson = json['admin'];

    return BranchModel(
      id: (c['_id'] ?? '').toString(),
      name: (c['name'] ?? '').toString(),
      address: c['address']?.toString(),
      isBranch: c['isBranch'] == true,
      parentCompanyId: c['parentCompanyId']?.toString(),
      latitude: _toDouble(loc['lat']),
      longitude: _toDouble(loc['lng']),
      checkInRadiusMeters: _toInt(c['checkInRadiusMeters']),
      timezone: c['timezone']?.toString(),
      isActive: c['isActive'] != false,
      code: (c['code'] ?? c['branchCode'])?.toString(),
      admin: adminJson is Map
          ? BranchAdmin.fromJson(Map<String, dynamic>.from(adminJson))
          : null,
      settings: BranchSettings.fromJson(_asMap(json['settings'])),
      activeEmployees: _toInt(json['activeEmployees']) ?? 0,
    );
  }

  /// Turns the decoded response (a JSON array) into a list of branches.
  static List<BranchModel> listFromResponse(dynamic body) {
    if (body is! List) return const [];
    return body
        .whereType<Map>()
        .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}