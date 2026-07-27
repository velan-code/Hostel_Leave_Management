class LeaveRequestModel {
  final String docId;
  final String id;
  final String studentName;
  final String rollNo;
  final String type; // Home Visit, Medical, Emergency, Festival, Other
  final String fromDate;
  final String toDate;
  final String departureTime;
  final String arrivalTime;
  final String reason;
  final String status; // pending_cc, pending_hod, pending_warden, approved, declined_cc, declined_hod, declined_warden
  final bool classMamSigned;
  final bool hodSigned;
  final bool wardenSigned;
  final String submittedOn;
  final int createdAt;
  final String assignedCcId;
  final String assignedCcName;
  final String assignedHodId;
  final String assignedHodName;
  final String assignedWardenId;
  final String assignedWardenName;
  final String? declineReason;

  LeaveRequestModel({
    required this.docId,
    required this.id,
    required this.studentName,
    required this.rollNo,
    required this.type,
    required this.fromDate,
    required this.toDate,
    this.departureTime = '09:00 AM',
    this.arrivalTime = '06:00 PM',
    required this.reason,
    required this.status,
    required this.classMamSigned,
    required this.hodSigned,
    required this.wardenSigned,
    required this.submittedOn,
    int? createdAt,
    this.assignedCcId = '',
    this.assignedCcName = '',
    this.assignedHodId = '',
    this.assignedHodName = '',
    this.assignedWardenId = '',
    this.assignedWardenName = '',
    this.declineReason,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LeaveRequestModel(
      docId: documentId,
      id: map['id'] ?? documentId,
      studentName: map['studentName'] ?? '',
      rollNo: map['rollNo'] ?? map['erp_no'] ?? '',
      type: map['type'] ?? 'Home Visit',
      fromDate: map['fromDate'] ?? '',
      toDate: map['toDate'] ?? '',
      departureTime: map['departureTime'] ?? '09:00 AM',
      arrivalTime: map['arrivalTime'] ?? '06:00 PM',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending_cc',
      classMamSigned: map['classMamSigned'] ?? false,
      hodSigned: map['hodSigned'] ?? false,
      wardenSigned: map['wardenSigned'] ?? false,
      submittedOn: map['submittedOn'] ?? '',
      createdAt: map['createdAt'] is int ? map['createdAt'] : DateTime.now().millisecondsSinceEpoch,
      assignedCcId: map['assignedCcId'] ?? '',
      assignedCcName: map['assignedCcName'] ?? map['assignedCc'] ?? '',
      assignedHodId: map['assignedHodId'] ?? '',
      assignedHodName: map['assignedHodName'] ?? map['assignedHod'] ?? '',
      assignedWardenId: map['assignedWardenId'] ?? '',
      assignedWardenName: map['assignedWardenName'] ?? map['assignedWarden'] ?? '',
      declineReason: map['declineReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'rollNo': rollNo,
      'erp_no': rollNo,
      'type': type,
      'fromDate': fromDate,
      'toDate': toDate,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'reason': reason,
      'status': status,
      'classMamSigned': classMamSigned,
      'hodSigned': hodSigned,
      'wardenSigned': wardenSigned,
      'submittedOn': submittedOn,
      'createdAt': createdAt,
      'assignedCcId': assignedCcId,
      'assignedCcName': assignedCcName,
      'assignedHodId': assignedHodId,
      'assignedHodName': assignedHodName,
      'assignedWardenId': assignedWardenId,
      'assignedWardenName': assignedWardenName,
      if (declineReason != null) 'declineReason': declineReason,
    };
  }
}
