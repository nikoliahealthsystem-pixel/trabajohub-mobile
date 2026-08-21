class SocketEvents {
  SocketEvents._();

  // ── Emitted by client ──────────────────────────────────────
  static const String joinConversation  = 'join_conversation';
  static const String leaveConversation = 'leave_conversation';
  static const String typing            = 'typing';

  // ── Emitted by server ──────────────────────────────────────
  static const String userTyping        = 'user_typing';
  static const String newMessage        = 'new_message';
  static const String messageRead       = 'message_read';
  static const String messageDeleted    = 'message_deleted';

  // ── Personal room events (user:userId) ────────────────────
  static const String newNotification   = 'new_notification';
  static const String shiftUpdate       = 'shift_update';
  static const String bookingUpdate     = 'booking_update';
}