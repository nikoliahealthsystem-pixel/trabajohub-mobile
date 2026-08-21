
class SubmitTicketResult {
  final String ticketNumber;
  final String id;

  SubmitTicketResult({required this.ticketNumber, required this.id});

  factory SubmitTicketResult.fromJson(Map<String, dynamic> json) {
    return SubmitTicketResult(
      ticketNumber: json['ticketNumber'],
      id: json['id'],
    );
  }
}

class TicketListResponse {
  final List<TicketListItem> tickets;
  final int total;
  final int page;
  final bool hasMore;

  TicketListResponse({
    required this.tickets,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  factory TicketListResponse.fromJson(Map<String, dynamic> json) {
    return TicketListResponse(
      tickets: (json['data'] as List)
          .map((e) => TicketListItem.fromJson(e))
          .toList(),
      total: json['pagination']['total'] ?? 0,
      page: json['pagination']['page'] ?? 1,
      hasMore: json['pagination']['hasNext'] ?? false,
    );
  }
}

class TicketListItem {
  final String id;
  final String ticketNumber;
  final String subject;
  final String status;
  final String priority;
  final String category;
  final String? guestName;
  final String? guestEmail;
  final DateTime createdAt;
  final int replyCount;

  TicketListItem({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.status,
    required this.priority,
    required this.category,
    this.guestName,
    this.guestEmail,
    required this.createdAt,
    required this.replyCount,
  });

  factory TicketListItem.fromJson(Map<String, dynamic> json) {
    return TicketListItem(
      id: json['id'],
      ticketNumber: json['ticketNumber'],
      subject: json['subject'],
      status: json['status'],
      priority: json['priority'],
      category: json['category'],
      guestName: json['guestName'],
      guestEmail: json['guestEmail'],
      createdAt: DateTime.parse(json['createdAt']),
      replyCount: json['_count']?['replies'] ?? 0,
    );
  }
}

class TicketDetail extends TicketListItem {
  final String? description;
  final String? resolution;
  final List<String> tags;
  final List<TicketReply> replies;

  TicketDetail({
    required super.id,
    required super.ticketNumber,
    required super.subject,
    required super.status,
    required super.priority,
    required super.category,
    super.guestName,
    super.guestEmail,
    required super.createdAt,
    required super.replyCount,
    this.description,
    this.resolution,
    this.tags = const [],
    this.replies = const [],
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    return TicketDetail(
      id: json['id'],
      ticketNumber: json['ticketNumber'],
      subject: json['subject'],
      status: json['status'],
      priority: json['priority'],
      category: json['category'],
      guestName: json['guestName'],
      guestEmail: json['guestEmail'],
      createdAt: DateTime.parse(json['createdAt']),
      replyCount: json['_count']?['replies'] ?? 0,
      description: json['description'],
      resolution: json['resolution'],
      tags: List<String>.from(json['tags'] ?? []),
      replies: (json['replies'] as List?)
          ?.map((r) => TicketReply.fromJson(r))
          .toList() ??
          [],
    );
  }
}

class TicketReply {
  final String id;
  final String body;
  final bool isInternal;
  final DateTime createdAt;
  final String? authorName;
  final bool isStaff;

  TicketReply({
    required this.id,
    required this.body,
    required this.isInternal,
    required this.createdAt,
    this.authorName,
    required this.isStaff,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    bool isStaff = false;
    String? authorName;

    // Check if there's an author object (staff or nurse)
    if (json['author'] != null) {
      final author = json['author'];
      if (author['adminProfile'] != null) {
        isStaff = true;
        authorName = "${author['adminProfile']['firstName'] ?? ''} ${author['adminProfile']['lastName'] ?? ''}".trim();
      } else if (author['nurseProfile'] != null) {
        authorName = "${author['nurseProfile']['firstName'] ?? ''} ${author['nurseProfile']['lastName'] ?? ''}".trim();
      }
    }
    // Fallbacks
    else if (json['authorEmail'] != null) {
      authorName = json['authorEmail'];
    }

    return TicketReply(
      id: json['id'],
      body: json['body'],
      isInternal: json['isInternal'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      authorName: authorName?.isNotEmpty == true ? authorName : null,
      isStaff: isStaff,
    );
  }
}
