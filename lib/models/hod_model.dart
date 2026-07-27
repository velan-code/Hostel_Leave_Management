class HodModel {
  final String docId;
  final String id; // e.g. H001
  final String name;
  final String email;
  final String password;
  final String phone;
  final String department; // e.g. CSE, ECE, ME
  final bool active;

  HodModel({
    required this.docId,
    required this.id,
    required this.name,
    required this.email,
    this.password = 'hod123',
    this.phone = '',
    this.department = '',
    this.active = true,
  });

  factory HodModel.fromMap(Map<String, dynamic> map, String documentId) {
    return HodModel(
      docId: documentId,
      id: map['id'] ?? documentId,
      name: map['name'] ?? '',
      email: (map['email'] ?? '').toString().trim().toLowerCase(),
      password: map['password'] ?? 'hod123',
      phone: map['phone'] ?? '',
      department: map['department'] ?? '',
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email.trim().toLowerCase(),
      'password': password,
      'phone': phone,
      'department': department,
      'active': active,
    };
  }

  HodModel copyWith({
    String? docId,
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? department,
    bool? active,
  }) {
    return HodModel(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      active: active ?? this.active,
    );
  }
}
