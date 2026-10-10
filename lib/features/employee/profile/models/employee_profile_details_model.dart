// lib/features/employee/profile/models/employee_profile_details_model.dart

class PersonalDetails {
  final String dob;             // "YYYY-MM-DD"
  final String gender;          // male | female | other    (lowercase required)
  final String maritalStatus;   // single | married | other (lowercase required)
  final String bloodGroup;
  final String address;
  final String emergencyContact;

  const PersonalDetails({
    required this.dob,
    required this.gender,
    required this.maritalStatus,
    required this.bloodGroup,
    required this.address,
    required this.emergencyContact,
  });

  static const PersonalDetails empty = PersonalDetails(
    dob: '',
    gender: '',
    maritalStatus: '',
    bloodGroup: '',
    address: '',
    emergencyContact: '',
  );

  factory PersonalDetails.fromJson(Map<String, dynamic> j) {
    return PersonalDetails(
      dob: (j['dob'] ?? '').toString(),
      gender: (j['gender'] ?? '').toString(),
      maritalStatus: (j['maritalStatus'] ?? '').toString(),
      bloodGroup: (j['bloodGroup'] ?? '').toString(),
      address: (j['address'] ?? '').toString(),
      emergencyContact: (j['emergencyContact'] ?? '').toString(),
    );
  }

  /// Sends only non-empty fields. Enum values are lower-cased.
  Map<String, dynamic> toUpdateJson() {
    return {
      if (dob.isNotEmpty) 'dob': dob,
      if (gender.isNotEmpty) 'gender': gender.toLowerCase(),
      if (maritalStatus.isNotEmpty)
        'maritalStatus': maritalStatus.toLowerCase(),
      if (bloodGroup.isNotEmpty) 'bloodGroup': bloodGroup,
      if (address.isNotEmpty) 'address': address,
      if (emergencyContact.isNotEmpty)
        'emergencyContact': emergencyContact,
    };
  }
}

class BankDetails {
  final String accountNumber;
  final String ifsc;
  final String bankName;
  final String upiId;

  const BankDetails({
    required this.accountNumber,
    required this.ifsc,
    required this.bankName,
    required this.upiId,
  });

  static const BankDetails empty = BankDetails(
    accountNumber: '',
    ifsc: '',
    bankName: '',
    upiId: '',
  );

  factory BankDetails.fromJson(Map<String, dynamic> j) {
    return BankDetails(
      accountNumber: (j['accountNumber'] ?? '').toString(),
      ifsc: (j['ifsc'] ?? '').toString(),
      bankName: (j['bankName'] ?? '').toString(),
      upiId: (j['upiId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (accountNumber.isNotEmpty) 'accountNumber': accountNumber,
      if (ifsc.isNotEmpty) 'ifsc': ifsc,
      if (bankName.isNotEmpty) 'bankName': bankName,
      if (upiId.isNotEmpty) 'upiId': upiId,
    };
  }
}