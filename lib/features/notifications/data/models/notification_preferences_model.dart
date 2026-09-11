class NotificationPreferencesModel {
  final bool pushEnabled;
  final bool emailEnabled;

  final bool shiftOffersEnabled;
  final bool assignmentUpdatesEnabled;
  final bool shiftRemindersEnabled;
  final bool shiftCancellationsEnabled;
  final bool urgentShiftsEnabled;

  final bool evvExceptionsEnabled;
  final bool visitUpdatesEnabled;

  final bool earningsEnabled;
  final bool payoutsEnabled;

  final bool credentialUpdatesEnabled;
  final bool credentialExpiryEnabled;

  final bool messagesEnabled;

  const NotificationPreferencesModel({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.shiftOffersEnabled,
    required this.assignmentUpdatesEnabled,
    required this.shiftRemindersEnabled,
    required this.shiftCancellationsEnabled,
    required this.urgentShiftsEnabled,
    required this.evvExceptionsEnabled,
    required this.visitUpdatesEnabled,
    required this.earningsEnabled,
    required this.payoutsEnabled,
    required this.credentialUpdatesEnabled,
    required this.credentialExpiryEnabled,
    required this.messagesEnabled,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      pushEnabled: json['pushEnabled'] != false,
      emailEnabled: json['emailEnabled'] != false,
      shiftOffersEnabled: json['shiftOffersEnabled'] != false,
      assignmentUpdatesEnabled: json['assignmentUpdatesEnabled'] != false,
      shiftRemindersEnabled: json['shiftRemindersEnabled'] != false,
      shiftCancellationsEnabled: json['shiftCancellationsEnabled'] != false,
      urgentShiftsEnabled: json['urgentShiftsEnabled'] != false,
      evvExceptionsEnabled: json['evvExceptionsEnabled'] != false,
      visitUpdatesEnabled: json['visitUpdatesEnabled'] != false,
      earningsEnabled: json['earningsEnabled'] != false,
      payoutsEnabled: json['payoutsEnabled'] != false,
      credentialUpdatesEnabled: json['credentialUpdatesEnabled'] != false,
      credentialExpiryEnabled: json['credentialExpiryEnabled'] != false,
      messagesEnabled: json['messagesEnabled'] != false,
    );
  }

  NotificationPreferencesModel copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? shiftOffersEnabled,
    bool? assignmentUpdatesEnabled,
    bool? shiftRemindersEnabled,
    bool? shiftCancellationsEnabled,
    bool? urgentShiftsEnabled,
    bool? evvExceptionsEnabled,
    bool? visitUpdatesEnabled,
    bool? earningsEnabled,
    bool? payoutsEnabled,
    bool? credentialUpdatesEnabled,
    bool? credentialExpiryEnabled,
    bool? messagesEnabled,
  }) {
    return NotificationPreferencesModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      shiftOffersEnabled: shiftOffersEnabled ?? this.shiftOffersEnabled,
      assignmentUpdatesEnabled:
          assignmentUpdatesEnabled ?? this.assignmentUpdatesEnabled,
      shiftRemindersEnabled:
          shiftRemindersEnabled ?? this.shiftRemindersEnabled,
      shiftCancellationsEnabled:
          shiftCancellationsEnabled ?? this.shiftCancellationsEnabled,
      urgentShiftsEnabled: urgentShiftsEnabled ?? this.urgentShiftsEnabled,
      evvExceptionsEnabled: evvExceptionsEnabled ?? this.evvExceptionsEnabled,
      visitUpdatesEnabled: visitUpdatesEnabled ?? this.visitUpdatesEnabled,
      earningsEnabled: earningsEnabled ?? this.earningsEnabled,
      payoutsEnabled: payoutsEnabled ?? this.payoutsEnabled,
      credentialUpdatesEnabled:
          credentialUpdatesEnabled ?? this.credentialUpdatesEnabled,
      credentialExpiryEnabled:
          credentialExpiryEnabled ?? this.credentialExpiryEnabled,
      messagesEnabled: messagesEnabled ?? this.messagesEnabled,
    );
  }
}
