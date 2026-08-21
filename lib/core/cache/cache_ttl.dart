class CacheTtl {
  CacheTtl._();

  /// User profile — changes rarely, but must be fresh after edits
  static const me = Duration(minutes: 5);

  /// Open shifts — change frequently (bookings, new posts)
  static const marketplace = Duration(minutes: 2);

  /// Nurse's own assignments — moderate change rate
  static const myShifts = Duration(minutes: 3);

  /// Shift detail page — low churn once booked
  static const shiftDetail = Duration(minutes: 10);

  /// Calendar events — aggregated, relatively stable within a session
  static const calendar = Duration(minutes: 5);

  /// Conversations list — needs to feel live; short TTL + background refresh
  static const conversations = Duration(seconds: 45);

  /// Individual messages — very fresh; polling supplements cache
  static const messages = Duration(seconds: 30);

  /// Notifications list
  static const notifications = Duration(seconds: 45);

  /// Unread count badge — keep very fresh
  static const unreadCount = Duration(seconds: 30);

  /// Credentials — change only on upload/review
  static const credentials = Duration(minutes: 15);

  /// Cases — low churn
  static const cases = Duration(minutes: 10);

  /// Case detail
  static const caseDetail = Duration(minutes: 10);

  /// Visits — moderate churn (check-in/out updates)
  static const visits = Duration(minutes: 3);

  /// Visit detail
  static const visitDetail = Duration(minutes: 3);

  static const survey = Duration(minutes: 30);

  static const tickets = Duration(minutes: 15);

  static const ticketDetail = Duration(minutes: 10);
}