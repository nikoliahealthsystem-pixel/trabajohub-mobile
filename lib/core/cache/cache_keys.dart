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
      'marketplace:'
      'p$page:'
      'vt=${visitType ?? ''}:'
      'urgent=${isUrgent ?? ''}:'
      'q=${searchQuery ?? ''}';

  // ── My Shifts ───────────────────────────────────────────
  //
  // v2 intentionally separates the new category-based
  // My Shifts API from the old assignment-status cache.
  //
  // Supported categories:
  // UPCOMING
  // IN_PROGRESS
  // COMPLETED
  // CANCELLED
  static String myShifts({int page = 1, String category = 'UPCOMING'}) =>
      'my_shifts:v2:'
      'p$page:'
      'category=${category.trim().toUpperCase()}';

  // ── Shift Detail ────────────────────────────────────────
  static String shiftDetail(String id) => 'shift:$id';

  // ── Calendar ────────────────────────────────────────────
  static String calendarEvents({
    required String from,
    required String to,
    String? types,
  }) =>
      'calendar:'
      '$from:'
      '$to:'
      't=${types ?? 'all'}';

  // ── Conversations ───────────────────────────────────────
  static String conversations({int page = 1}) => 'conversations:p$page';

  // ── Messages ────────────────────────────────────────────
  static String messages(String conversationId, {int page = 1}) =>
      'messages:$conversationId:p$page';

  // ── Credentials ─────────────────────────────────────────
  static const String credentials = 'credentials:mine';

  static String credentialDetail(String id) => 'credential:$id';

  // ── Cases ───────────────────────────────────────────────
  static String cases({int page = 1, String? visitType, String? search}) =>
      'cases:'
      'p$page:'
      'vt=${visitType ?? ''}:'
      'q=${search ?? ''}';

  static String caseDetail(String id) => 'case:$id';

  // ── Visits ──────────────────────────────────────────────
  static String visits({
    int page = 1,
    String? status,
    bool flaggedOnly = false,
  }) =>
      'visits:'
      'p$page:'
      's=${status ?? ''}:'
      'flagged=$flaggedOnly';

  static String visitDetail(String id) => 'visit:$id';

  // ── Surveys ─────────────────────────────────────────────
  static String survey(String shiftId) => 'survey_$shiftId';

  // ── Support Tickets ─────────────────────────────────────
  static String tickets({int page = 1, String? status, String? search}) =>
      'tickets_'
      'p${page}_'
      's${status ?? ''}_'
      'q${search ?? ''}';

  static String ticketDetail(String id) => 'ticket_detail_$id';

  // ── Prefix Helpers ──────────────────────────────────────
  //
  // Used for bulk cache invalidation after create/update/
  // booking/cancellation/read-state changes.
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
