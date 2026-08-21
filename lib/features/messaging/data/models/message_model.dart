class MessageSender {
  final String id;
  final String role;
  final Map<String, dynamic>? adminProfile;
  final Map<String, dynamic>? nurseProfile;

  const MessageSender({
    required this.id,
    required this.role,
    this.adminProfile,
    this.nurseProfile,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) => MessageSender(
    id: json['id'],
    role: json['role'],
    adminProfile: json['adminProfile'] as Map<String, dynamic>?,
    nurseProfile: json['nurseProfile'] as Map<String, dynamic>?,
  );

  String get displayName {
    if (adminProfile != null) {
      return '${adminProfile!['firstName']} ${adminProfile!['lastName']}';
    }
    if (nurseProfile != null) {
      return '${nurseProfile!['firstName']} ${nurseProfile!['lastName']}';
    }
    return role;
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final String? attachmentUrl;
  final String? attachmentKey;
  final String? attachmentSignedUrl;
  final String? attachmentType;
  final String status; // SENT | DELIVERED | READ
  final DateTime? readAt;
  final DateTime createdAt;
  final MessageSender? sender;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    this.attachmentUrl,
    this.attachmentKey,
    this.attachmentSignedUrl,
    this.attachmentType,
    required this.status,
    this.readAt,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'],
    conversationId: json['conversationId'],
    senderId: json['senderId'],
    content: json['content'],
    attachmentUrl: json['attachmentUrl'],
    attachmentKey: json['attachmentKey'],
    attachmentSignedUrl: json['attachmentSignedUrl'],
    attachmentType: json['attachmentType'],
    status: json['status'] ?? 'SENT',
    readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
    createdAt: DateTime.parse(json['createdAt']),
    sender: json['sender'] != null ? MessageSender.fromJson(json['sender']) : null,
  );

  bool get isDeleted =>
      content == null && attachmentKey == null && attachmentSignedUrl == null;

  bool get isImage => attachmentType?.startsWith('image/') ?? false;

  MessageModel copyWith({
    String? status,
    String? readAt,
    String? content,
    String? attachmentUrl,
    String? attachmentKey,
    String? attachmentSignedUrl,
  }) =>
      MessageModel(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        content: content ?? this.content,
        attachmentUrl: attachmentUrl ?? this.attachmentUrl,
        attachmentKey: attachmentKey ?? this.attachmentKey,
        attachmentSignedUrl: attachmentSignedUrl ?? this.attachmentSignedUrl,
        attachmentType: attachmentType,
        status: status ?? this.status,
        readAt: readAt != null ? DateTime.parse(readAt) : this.readAt,
        createdAt: createdAt,
        sender: sender,
      );
}