class StudentModel {
  final String docId;
  final String id; // Roll No, e.g. CS2021045
  final String name;
  final String email;
  final String password;
  final String department;
  final String year; // e.g. 1st Year, 2nd Year, 3rd Year, 4th Year
  final String hostelBlock;
  final String roomNo;
  final String assignedWardenId;
  final String assignedWardenName;
  final String assignedCcId;
  final String assignedCcName;
  final String assignedHodId;
  final String assignedHodName;
  final bool active;

  String get rollNo => id;
  String get yearBatch => year;

  StudentModel({
    required this.docId,
    required this.id,
    required this.name,
    required this.email,
    this.password = '',
    this.department = '',
    this.year = '1st Year',
    this.hostelBlock = '',
    this.roomNo = '',
    this.assignedWardenId = '',
    this.assignedWardenName = '',
    this.assignedCcId = '',
    this.assignedCcName = '',
    this.assignedHodId = '',
    this.assignedHodName = '',
    this.active = true,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentModel(
      docId: documentId,
      id: map['id'] ?? documentId,
      name: map['name'] ?? '',
      email: (map['email'] ?? '').toString().trim().toLowerCase(),
      password: map['password'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? map['yearBatch'] ?? map['year_batch'] ?? '1st Year',
      hostelBlock: map['hostelBlock'] ?? '',
      roomNo: map['roomNo'] ?? '',
      assignedWardenId: map['assignedWardenId'] ?? '',
      assignedWardenName: map['assignedWardenName'] ?? map['assignedWarden'] ?? '',
      assignedCcId: map['assignedCcId'] ?? '',
      assignedCcName: map['assignedCcName'] ?? map['assignedCc'] ?? '',
      assignedHodId: map['assignedHodId'] ?? '',
      assignedHodName: map['assignedHodName'] ?? map['assignedHod'] ?? '',
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email.trim().toLowerCase(),
      'password': password,
      'department': department,
      'year': year,
      'yearBatch': year,
      'hostelBlock': hostelBlock,
      'roomNo': roomNo,
      'assignedWardenId': assignedWardenId,
      'assignedWardenName': assignedWardenName,
      'assignedCcId': assignedCcId,
      'assignedCcName': assignedCcName,
      'assignedHodId': assignedHodId,
      'assignedHodName': assignedHodName,
      'active': active,
    };
  }

  StudentModel copyWith({
    String? docId,
    String? id,
    String? name,
    String? email,
    String? password,
    String? department,
    String? year,
    String? hostelBlock,
    String? roomNo,
    String? assignedWardenId,
    String? assignedWardenName,
    String? assignedCcId,
    String? assignedCcName,
    String? assignedHodId,
    String? assignedHodName,
    bool? active,
  }) {
    return StudentModel(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      department: department ?? this.department,
      year: year ?? this.year,
      hostelBlock: hostelBlock ?? this.hostelBlock,
      roomNo: roomNo ?? this.roomNo,
      assignedWardenId: assignedWardenId ?? this.assignedWardenId,
      assignedWardenName: assignedWardenName ?? this.assignedWardenName,
      assignedCcId: assignedCcId ?? this.assignedCcId,
      assignedCcName: assignedCcName ?? this.assignedCcName,
      assignedHodId: assignedHodId ?? this.assignedHodId,
      assignedHodName: assignedHodName ?? this.assignedHodName,
      active: active ?? this.active,
    );
  }
}
