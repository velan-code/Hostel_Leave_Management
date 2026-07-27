import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String complainantName;
  final String complainantId; // ERP No / Email / Roll No
  final String complainantRole; // Student / Member
  final String category; // 'Food', 'Water Facility', 'Room', 'Abnormal Smell', 'Other'
  final String description;
  final String status; // 'pending', 'in_progress', 'resolved'
  final DateTime createdAt;
  final String? wardenRemarks;
  final String assignedWardenId;
  final String assignedWardenName;
  final bool clearedByWarden;
  final bool clearedByStudent;

  ComplaintModel({
    required this.id,
    required this.complainantName,
    required this.complainantId,
    required this.complainantRole,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.wardenRemarks,
    this.assignedWardenId = '',
    this.assignedWardenName = '',
    this.clearedByWarden = false,
    this.clearedByStudent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'complainantName': complainantName,
      'complainantId': complainantId,
      'complainantRole': complainantRole,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'wardenRemarks': wardenRemarks ?? '',
      'assignedWardenId': assignedWardenId,
      'assignedWardenName': assignedWardenName,
      'clearedByWarden': clearedByWarden,
      'clearedByStudent': clearedByStudent,
    };
  }

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic dateVal) {
      if (dateVal is Timestamp) return dateVal.toDate();
      if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
      return DateTime.now();
    }

    return ComplaintModel(
      id: docId,
      complainantName: map['complainantName'] ?? 'Anonymous Member',
      complainantId: map['complainantId'] ?? '',
      complainantRole: map['complainantRole'] ?? 'student',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: parseDate(map['createdAt']),
      wardenRemarks: map['wardenRemarks'] ?? '',
      assignedWardenId: map['assignedWardenId'] ?? '',
      assignedWardenName: map['assignedWardenName'] ?? '',
      clearedByWarden: map['clearedByWarden'] ?? false,
      clearedByStudent: map['clearedByStudent'] ?? false,
    );
  }
}
