class CcModel {
  final String docId;
  final String id; // e.g. CM001 / CC001
  final String name;
  final String email;
  final String password;
  final String phone;
  final String section; // e.g. Section A, Section B
  final String yearBatch; // e.g. 3rd Year / 2022-2026
  final bool active;

  // Getter for backward compatibility
  String get department => section;

  CcModel({
    required this.docId,
    required this.id,
    required this.name,
    required this.email,
    this.password = 'cc123',
    this.phone = '',
    this.section = 'Section A',
    this.yearBatch = '',
    this.active = true,
  });

  factory CcModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CcModel(
      docId: documentId,
      id: map['id'] ?? documentId,
      name: map['name'] ?? '',
      email: (map['email'] ?? '').toString().trim().toLowerCase(),
      password: map['password'] ?? 'cc123',
      phone: map['phone'] ?? '',
      section: map['section'] ?? map['department'] ?? 'Section A',
      yearBatch: (map['yearBatch'] ?? map['year_batch'] ?? map['year'] ?? '3rd Year').toString(),
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
      'section': section,
      'department': section, // Keep for query compatibility
      'yearBatch': yearBatch,
      'year': yearBatch, // Include year for query compatibility
      'year_batch': yearBatch,
      'active': active,
    };
  }

  CcModel copyWith({
    String? docId,
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? section,
    String? yearBatch,
    bool? active,
  }) {
    return CcModel(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      section: section ?? this.section,
      yearBatch: yearBatch ?? this.yearBatch,
      active: active ?? this.active,
    );
  }
}
