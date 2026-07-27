class UserModel {
  final String docId;
  final String name;
  final String role; // Student, Warden, HOD, CC, Admin
  final String erpNo; // ERP number / Roll No / ID
  final String department;
  final String year; // 1st Year, 2nd Year, 3rd Year, 4th Year, N/A
  final String email;
  final String password;
  final String assignedHod;
  final String assignedWarden;
  final String assignedCc;
  final bool active;

  // Getter for backward compatibility with references to user.id
  String get id => erpNo;

  UserModel({
    required this.docId,
    required this.name,
    required this.role,
    required this.erpNo,
    required this.department,
    required this.year,
    required this.email,
    required this.password,
    required this.assignedHod,
    required this.assignedWarden,
    required this.assignedCc,
    this.active = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      docId: documentId,
      name: map['name'] ?? '',
      role: map['role'] ?? 'Student',
      erpNo: map['erpNo'] ?? map['erp_no'] ?? map['id'] ?? documentId,
      department: map['department'] ?? '',
      year: map['year'] ?? map['yearBatch'] ?? map['year_batch'] ?? '',
      email: map['email'] ?? '',
      password: (map['password'] != null && map['password'].toString().isNotEmpty)
          ? map['password'].toString()
          : 'password123',
      assignedHod: map['assignedHod'] ?? '',
      assignedWarden: map['assignedWarden'] ?? '',
      assignedCc: map['assignedCc'] ?? map['assignedCcName'] ?? '',
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'name': name,
      'role': role,
      'erpNo': erpNo,
      'erp_no': erpNo,
      'id': erpNo, // Keep for backward compatibility
      'department': department,
      'year': year,
      'email': email.toLowerCase(),
      'password': password,
      'assignedHod': assignedHod,
      'assignedWarden': assignedWarden,
      'assignedCc': assignedCc,
      'active': active,
    };
  }

  UserModel copyWith({
    String? name,
    String? role,
    String? erpNo,
    String? department,
    String? year,
    String? email,
    String? password,
    String? assignedHod,
    String? assignedWarden,
    String? assignedCc,
    bool? active,
  }) {
    return UserModel(
      docId: docId,
      name: name ?? this.name,
      role: role ?? this.role,
      erpNo: erpNo ?? this.erpNo,
      department: department ?? this.department,
      year: year ?? this.year,
      email: email ?? this.email,
      password: password ?? this.password,
      assignedHod: assignedHod ?? this.assignedHod,
      assignedWarden: assignedWarden ?? this.assignedWarden,
      assignedCc: assignedCc ?? this.assignedCc,
      active: active ?? this.active,
    );
  }
}
