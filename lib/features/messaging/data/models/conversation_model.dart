class ConversationParticipant {
  final String id;
  final String email;
  final String role;
  final String? displayName;
  final String? avatarUrl;
  final String? avatarKey;
  final String? status;
  final String? verificationStatus;
  final DateTime? createdAt;

  final Map<String, dynamic>? adminProfile;
  final Map<String, dynamic>? nurseProfile;
  final Map<String, dynamic>? facilityMember;

  const ConversationParticipant({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.avatarUrl,
    this.avatarKey,
    this.status,
    this.verificationStatus,
    this.createdAt,
    this.adminProfile,
    this.nurseProfile,
    this.facilityMember,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      avatarKey: json['avatarKey']?.toString(),
      status: json['status']?.toString(),
      verificationStatus: json['verificationStatus']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      adminProfile: _mapOrNull(json['adminProfile']),
      nurseProfile: _mapOrNull(json['nurseProfile']),
      facilityMember: _mapOrNull(json['facilityMember']),
    );
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String get name {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }

    final profile = adminProfile ?? nurseProfile ?? facilityMember;

    final firstName = profile?['firstName']?.toString().trim() ?? '';
    final lastName = profile?['lastName']?.toString().trim() ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;

    return email;
  }

  String get subtitle {
    final parts = <String>[];

    if (role.isNotEmpty) {
      parts.add(role.replaceAll('_', ' '));
    }

    final designation = nurseProfile?['designation']?.toString();
    final jobTitle = facilityMember?['jobTitle']?.toString();

    if (designation != null && designation.isNotEmpty) {
      parts.add(designation);
    }

    if (jobTitle != null && jobTitle.isNotEmpty) {
      parts.add(jobTitle);
    }

    return parts.join(' · ');
  }

  String get initials {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return '?';

    final parts = cleanName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return cleanName[0].toUpperCase();
  }

  String get effectiveAvatarUrl {
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return avatarUrl!.trim();
    }

    final nurseAvatar = nurseProfile?['avatarUrl']?.toString();
    if (nurseAvatar != null && nurseAvatar.trim().isNotEmpty) {
      return nurseAvatar.trim();
    }

    final adminAvatar = adminProfile?['avatarUrl']?.toString();
    if (adminAvatar != null && adminAvatar.trim().isNotEmpty) {
      return adminAvatar.trim();
    }

    return '';
  }
}

class ConversationLastMessage {
  final String? id;
  final String? content;
  final String? senderId;
  final String? attachmentType;
  final DateTime? createdAt;

  const ConversationLastMessage({
    this.id,
    this.content,
    this.senderId,
    this.attachmentType,
    this.createdAt,
  });

  factory ConversationLastMessage.fromJson(Map<String, dynamic> json) {
    return ConversationLastMessage(
      id: json['id']?.toString(),
      content: json['content']?.toString(),
      senderId: json['senderId']?.toString(),
      attachmentType: json['attachmentType']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  String get preview {
    if (content != null && content!.trim().isNotEmpty) {
      return content!.trim();
    }

    if (attachmentType != null && attachmentType!.trim().isNotEmpty) {
      return '📎 Attachment';
    }

    return 'No messages yet';
  }
}

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final String? facilityId;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  final List<ConversationParticipant> participants;
  final List<ConversationParticipant> otherParticipants;
  final ConversationParticipant? otherParticipant;

  final ConversationLastMessage? lastMessage;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.participantIds,
    this.facilityId,
    this.lastMessageAt,
    this.createdAt,
    required this.participants,
    this.otherParticipants = const [],
    this.otherParticipant,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] as List? ?? [])
        .map((participant) => ConversationParticipant.fromJson(
      Map<String, dynamic>.from(participant as Map),
    ))
        .toList();

    final otherParticipants = (json['otherParticipants'] as List? ?? [])
        .map((participant) => ConversationParticipant.fromJson(
      Map<String, dynamic>.from(participant as Map),
    ))
        .toList();

    ConversationParticipant? parsedOtherParticipant;

    if (json['otherParticipant'] is Map) {
      parsedOtherParticipant = ConversationParticipant.fromJson(
        Map<String, dynamic>.from(json['otherParticipant'] as Map),
      );
    }

    ConversationLastMessage? parsedLastMessage;

    if (json['lastMessage'] is Map) {
      parsedLastMessage = ConversationLastMessage.fromJson(
        Map<String, dynamic>.from(json['lastMessage'] as Map),
      );
    } else if (json['messages'] is List && (json['messages'] as List).isNotEmpty) {
      parsedLastMessage = ConversationLastMessage.fromJson(
        Map<String, dynamic>.from((json['messages'] as List).first as Map),
      );
    }

    return ConversationModel(
      id: json['id']?.toString() ?? '',
      participantIds: List<String>.from(json['participantIds'] ?? []),
      facilityId: json['facilityId']?.toString(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      participants: participants,
      otherParticipants: otherParticipants,
      otherParticipant: parsedOtherParticipant,
      lastMessage: parsedLastMessage,
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount'] as int
          : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
    );
  }

  String otherParticipantName(String currentUserId) {
    if (otherParticipant != null) {
      return otherParticipant!.name;
    }

    final others = participants.where((p) => p.id != currentUserId).toList();

    if (others.isEmpty) return '';

    return others.map((p) => p.name).join(', ');
  }

  String otherParticipantInitials(String currentUserId) {
    if (otherParticipant != null) {
      return otherParticipant!.initials;
    }

    final others = participants.where((p) => p.id != currentUserId).toList();

    if (others.isEmpty) return '?';

    return others.first.initials;
  }

  String otherParticipantAvatarUrl(String currentUserId) {
    if (otherParticipant != null) {
      return otherParticipant!.effectiveAvatarUrl;
    }

    final others = participants.where((p) => p.id != currentUserId).toList();

    if (others.isEmpty) return '';

    return others.first.effectiveAvatarUrl;
  }

  String get lastMessagePreview {
    return lastMessage?.preview ?? 'No messages yet';
  }

  bool get hasUnreadMessages => unreadCount > 0;
}