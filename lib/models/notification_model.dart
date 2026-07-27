class AppNotificationModel {
  final String id;
  final String recipientId; // e.g. student ERP/email, CC email, HOD email, Warden block/email
  final String recipientRole; // student, cc, hod, warden, admin
  final String title;
  final String message;
  final String leaveRequestId;
  final DateTime createdAt;
  final bool isRead;
  final String type; // approval, rejection, new_request, info

  AppNotificationModel({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.title,
    required this.message,
    required this.leaveRequestId,
    required this.createdAt,
    this.isRead = false,
    this.type = 'info',
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
      } else if (map['createdAt'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(map['createdAt']);
      } else {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return AppNotificationModel(
      id: docId,
      recipientId: map['recipientId'] ?? '',
      recipientRole: (map['recipientRole'] ?? '').toString().toLowerCase(),
      title: map['title'] ?? 'Notification',
      message: map['message'] ?? '',
      leaveRequestId: map['leaveRequestId'] ?? '',
      createdAt: parsedDate,
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'recipientRole': recipientRole.toLowerCase(),
      'title': title,
      'message': message,
      'leaveRequestId': leaveRequestId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  AppNotificationModel copyWith({
    String? id,
    String? recipientId,
    String? recipientRole,
    String? title,
    String? message,
    String? leaveRequestId,
    DateTime? createdAt,
    bool? isRead,
    String? type,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      title: title ?? this.title,
      message: message ?? this.message,
      leaveRequestId: leaveRequestId ?? this.leaveRequestId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
