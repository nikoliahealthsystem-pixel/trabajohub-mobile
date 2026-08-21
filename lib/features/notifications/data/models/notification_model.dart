enum NotificationType {
  shiftAlert,
  bookingConfirmation,
  credentialExpiry,
  assignmentUpdate,
  paymentAlert,
  systemAlert,
  credentialApproved,
  credentialRejected,
  shiftCancelled,
  newMessage;

  static NotificationType fromString(String raw) {
    switch (raw) {
      case 'SHIFT_ALERT': return shiftAlert;
      case 'BOOKING_CONFIRMATION': return bookingConfirmation;
      case 'CREDENTIAL_EXPIRY': return credentialExpiry;
      case 'ASSIGNMENT_UPDATE': return assignmentUpdate;
      case 'PAYMENT_ALERT': return paymentAlert;
      case 'CREDENTIAL_APPROVED': return credentialApproved;
      case 'CREDENTIAL_REJECTED': return credentialRejected;
      case 'SHIFT_CANCELLED': return shiftCancelled;
      case 'NEW_MESSAGE': return newMessage;
      default: return systemAlert;
    }
  }

  String get label {
    switch (this) {
      case shiftAlert: return 'Shift Alert';
      case bookingConfirmation: return 'Booking';
      case credentialExpiry: return 'Credential';
      case assignmentUpdate: return 'Assignment';
      case paymentAlert: return 'Payment';
      case credentialApproved: return 'Approved';
      case credentialRejected: return 'Rejected';
      case shiftCancelled: return 'Cancelled';
      case newMessage: return 'Message';
      default: return 'System';
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String channel;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.channel,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    this.readAt,
    this.sentAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'],
        userId: json['userId'],
        type: NotificationType.fromString(json['type'] ?? ''),
        channel: json['channel'] ?? 'PUSH',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        data: json['data'] as Map<String, dynamic>?,
        isRead: json['isRead'] ?? false,
        readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
        sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
        createdAt: DateTime.parse(json['createdAt']),
      );

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) =>
      NotificationModel(
        id: id,
        userId: userId,
        type: type,
        channel: channel,
        title: title,
        body: body,
        data: data,
        isRead: isRead ?? this.isRead,
        readAt: readAt ?? this.readAt,
        sentAt: sentAt,
        createdAt: createdAt,
      );
}