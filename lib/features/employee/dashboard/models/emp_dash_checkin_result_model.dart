class EmpDashCheckInResult {
  final String message;
  final DateTime? date;
  final String? checkIn;
  final String status;
  final bool isLate;

  const EmpDashCheckInResult({
    required this.message,
    required this.date,
    required this.checkIn,
    required this.status,
    required this.isLate,
  });

  factory EmpDashCheckInResult.fromJson(Map<String, dynamic> json) {
    final attendanceJson = json['attendance'];
    final attendance = attendanceJson is Map
        ? Map<String, dynamic>.from(attendanceJson)
        : <String, dynamic>{};

    return EmpDashCheckInResult(
      message: json['message']?.toString() ?? 'Checked in successfully',
      date: attendance['date'] != null
          ? DateTime.tryParse(attendance['date'].toString())
          : null,
      checkIn: attendance['checkIn']?.toString(),
      status: attendance['status']?.toString().toLowerCase() ?? '',
      isLate: attendance['isLate'] == true,
    );
  }
}

class EmpDashCheckOutResult {
  final String message;
  final String? checkOut;
  final double totalHours;

  const EmpDashCheckOutResult({
    required this.message,
    required this.checkOut,
    required this.totalHours,
  });

  factory EmpDashCheckOutResult.fromJson(Map<String, dynamic> json) {
    return EmpDashCheckOutResult(
      message: json['message']?.toString() ?? 'Checked out successfully',
      checkOut: json['checkOut']?.toString(),
      totalHours: _toDouble(json['totalHours']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}