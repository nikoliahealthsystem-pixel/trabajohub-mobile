class CacheKeys {
  CacheKeys._();

  // ── Auth / Profile ──────────────────────────────────────
  static const String me = 'user:me';

  // ── Notifications ───────────────────────────────────────
  static String notifications({int page = 1, bool unreadOnly = false}) =>
      'notifications:p$page:unread=$unreadOnly';
  static const String unreadCount = 'notifications:unread_count';

  // ── Marketplace ─────────────────────────────────────────
  static String marketplace({
    int page = 1,
    String? visitType,
    bool? isUrgent,
    String? searchQuery,
  }) =>
      'marketplace:p$page:vt=${visitType ?? ''}:urgent=${isUrgent ?? ''}:q=${searchQuery ?? ''}';

  // ── My Shifts ────────────────────────────────────────────
  static String myShifts({int page = 1, String status = 'ACCEPTED'}) =>
      'my_shifts:p$page:s=$status';

  // ── Shift detail ─────────────────────────────────────────
  static String shiftDetail(String id) => 'shift:$id';

  // ── Calendar ─────────────────────────────────────────────
  static String calendarEvents({
    required String from,
    required String to,
    String? types,
  }) =>
      'calendar:$from:$to:t=${types ?? 'all'}';

  // ── Conversations ─────────────────────────────────────────
  static String conversations({int page = 1}) => 'conversations:p$page';

  // ── Messages ─────────────────────────────────────────────
  static String messages(String conversationId, {int page = 1}) =>
      'messages:$conversationId:p$page';

  // ── Credentials ──────────────────────────────────────────
  static const String credentials = 'credentials:mine';
  static String credentialDetail(String id) => 'credential:$id';

  // ── Cases ────────────────────────────────────────────────
  static String cases({
    int page = 1,
    String? visitType,
    String? search,
  }) =>
      'cases:p$page:vt=${visitType ?? ''}:q=${search ?? ''}';
  static String caseDetail(String id) => 'case:$id';

  // ── Visits ───────────────────────────────────────────────
  static String visits({
    int page = 1,
    String? status,
    bool flaggedOnly = false,
  }) =>
      'visits:p$page:s=${status ?? ''}:flagged=$flaggedOnly';
  static String visitDetail(String id) => 'visit:$id';

  static String survey(String shiftId) => 'survey_$shiftId';

  static String tickets({int page = 1, String? status, String? search}) =>
      'tickets_p${page}_s${status}_q${search}';

  static String ticketDetail(String id) => 'ticket_detail_$id';

  // ── Prefix helpers (for bulk invalidation) ───────────────
  static const String prefixMarketplace = 'marketplace:';
  static const String prefixMyShifts = 'my_shifts:';
  static const String prefixCalendar = 'calendar:';
  static const String prefixConversations = 'conversations:';
  static const String prefixMessages = 'messages:';
  static const String prefixNotifications = 'notifications:';
  static const String prefixCases = 'cases:';
  static const String prefixVisits = 'visits:';
  static const String prefixSurvey = 'survey_';
}