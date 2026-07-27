class WardenModel {
  final String docId;
  final String id; // e.g. W001
  final String name;
  final String email;
  final String password;
  final String phone;
  final String hostelBlock; // e.g. Block A
  final bool active;

  WardenModel({
    required this.docId,
    required this.id,
    required this.name,
    required this.email,
    this.password = 'warden123',
    this.phone = '',
    this.hostelBlock = '',
    this.active = true,
  });

  factory WardenModel.fromMap(Map<String, dynamic> map, String documentId) {
    return WardenModel(
      docId: documentId,
      id: map['id'] ?? documentId,
      name: map['name'] ?? '',
      email: (map['email'] ?? '').toString().trim().toLowerCase(),
      password: map['password'] ?? 'warden123',
      phone: map['phone'] ?? '',
      hostelBlock: map['hostelBlock'] ?? '',
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
      'hostelBlock': hostelBlock,
      'active': active,
    };
  }

  WardenModel copyWith({
    String? docId,
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? hostelBlock,
    bool? active,
  }) {
    return WardenModel(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      hostelBlock: hostelBlock ?? this.hostelBlock,
      active: active ?? this.active,
    );
  }
}
