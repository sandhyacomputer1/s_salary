String _text(dynamic v) => v?.toString().trim() ?? '';

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

int? _firstInt(List<Map<String, dynamic>> sources, List<String> keys) {
  for (final source in sources) {
    for (final key in keys) {
      final value = _toInt(source[key]);
      if (value != null) return value;
    }
  }
  return null;
}

/// Filter option lists.
/// - Statuses: documented in ANDROID_API_REFERENCE (data dictionary).
/// - Actions: the five values shown in the web app's dropdown. The backend may
///   support more; the reference does not list them.
/// The strings are sent to the backend exactly as written here.
class AuditOptions {
  AuditOptions._();

  static const List<String> actions = [
    'LOGIN',
    '2FA_CHALLENGE',
    '2FA_VERIFIED',
    'PASSWORD_RESET',
    'LICENSE_CHANGE',
  ];

  static const List<String> statuses = ['SUCCESS', 'FAILED', 'WARNING'];

  /// The web app shows 15 rows per page (302 events = 21 pages).
  static const int pageSize = 15;
}

/// The filters + page that make up one GET /audit-logs request.
class AuditQuery {
  final String search;
  final String action; // empty = all
  final String status; // empty = all
  final int page;
  final int limit;

  const AuditQuery({
    this.search = '',
    this.action = '',
    this.status = '',
    this.page = 1,
    this.limit = AuditOptions.pageSize,
  });

  bool get hasFilters =>
      search.trim().isNotEmpty || action.isNotEmpty || status.isNotEmpty;

  AuditQuery copyWith({
    String? search,
    String? action,
    String? status,
    int? page,
    int? limit,
  }) {
    return AuditQuery(
      search: search ?? this.search,
      action: action ?? this.action,
      status: status ?? this.status,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  /// Only filters that are set are sent. Values are URL-encoded by Uri.
  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };

    final q = search.trim();
    if (q.isNotEmpty) params['search'] = q;
    if (action.isNotEmpty) params['action'] = action;
    if (status.isNotEmpty) params['status'] = status;

    return params;
  }
}

/// One audit event.
///
/// !!! The record fields are NOT documented in the API reference. Each value is
/// read from the most likely key names; a missing value stays empty and is
/// shown as a neutral fallback, never invented.
class AuditLog {
  final String id;
  final DateTime? timestamp; // UTC from the API; convert with toLocal()
  final String email;
  final String role;
  final String action;
  final String status;
  final String ipAddress;

  const AuditLog({
    required this.id,
    required this.timestamp,
    required this.email,
    required this.role,
    required this.action,
    required this.status,
    required this.ipAddress,
  });

  /// "ADMIN", "EMPLOYEE", "SUPER ADMIN" ... or empty.
  String get roleLabel =>
      role.isEmpty ? '' : role.replaceAll('_', ' ').toUpperCase();

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    // The user may be a nested object (populated) or flat keys.
    final user = _asMap(json['user'] ?? json['userId']);

    return AuditLog(
      id: _text(json['_id'] ?? json['id']),
      timestamp: DateTime.tryParse(
        _text(json['timestamp'] ?? json['createdAt'] ?? json['date']),
      ),
      email: _text(json['userEmail'] ?? json['email'] ?? user['email']),
      role: _text(json['userRole'] ?? json['role'] ?? user['role']),
      action: _text(json['action'] ?? json['event']),
      status: _text(json['status']),
      ipAddress: _text(json['ipAddress'] ?? json['ip']),
    );
  }
}

/// One page of results plus the paging numbers.
///
/// !!! The response structure of GET /audit-logs is NOT documented. Accepted:
///   [ {...}, {...} ]                                    (bare array)
///   { logs|auditLogs|data|items|results|docs: [...],
///     total|totalCount|totalDocs|totalRecords|count,
///     page|currentPage, totalPages|pages|pageCount,
///     limit|pageSize|perPage }                          (top level)
///   the same numbers inside "pagination" or "meta".
class AuditPage {
  final List<AuditLog> logs;
  final int page;
  final int limit;

  /// null when the response carries no total.
  final int? total;

  /// From the response, or calculated from [total] and [limit].
  final int? totalPages;

  const AuditPage({
    required this.logs,
    required this.page,
    required this.limit,
    this.total,
    this.totalPages,
  });

  bool get hasPrevious => page > 1;

  /// Without a page count we can only guess from a full page.
  bool get hasNext =>
      totalPages != null ? page < totalPages! : logs.length >= limit;

  static const List<String> _listKeys = [
    'logs',
    'auditLogs',
    'data',
    'items',
    'results',
    'docs',
  ];

  static List<dynamic>? _findList(Map<String, dynamic> map) {
    for (final key in _listKeys) {
      final value = map[key];
      if (value is List) return value;
    }

    // One level deeper, e.g. { data: { logs: [...] } }.
    for (final key in _listKeys) {
      final value = map[key];
      if (value is Map) {
        final inner = _findList(Map<String, dynamic>.from(value));
        if (inner != null) return inner;
      }
    }

    return null;
  }

  factory AuditPage.fromResponse(
      dynamic body, {
        required int requestedPage,
        required int limit,
      }) {
    List<dynamic> rawList = const [];
    final sources = <Map<String, dynamic>>[];

    if (body is List) {
      rawList = body;
    } else if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      rawList = _findList(map) ?? const [];

      sources
        ..add(_asMap(map['pagination']))
        ..add(_asMap(map['meta']))
        ..add(map);

      final data = _asMap(map['data']);
      if (data.isNotEmpty) {
        sources
          ..add(_asMap(data['pagination']))
          ..add(data);
      }
    }

    final logs = rawList
        .whereType<Map>()
        .map((e) => AuditLog.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final total = _firstInt(
      sources,
      ['total', 'totalCount', 'totalDocs', 'totalRecords', 'count'],
    );

    var pages = _firstInt(sources, ['totalPages', 'pages', 'pageCount']);

    final effectiveLimit =
        _firstInt(sources, ['limit', 'pageSize', 'perPage']) ?? limit;

    if (pages == null && total != null && effectiveLimit > 0) {
      pages = (total / effectiveLimit).ceil();
    }

    final page = _firstInt(sources, ['page', 'currentPage']) ?? requestedPage;

    return AuditPage(
      logs: logs,
      page: page,
      limit: effectiveLimit,
      total: total,
      totalPages: pages,
    );
  }
}