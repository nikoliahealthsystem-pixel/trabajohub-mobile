import '../data/models/notification_preferences_model.dart';

enum NotificationPreferencesStatus { initial, loading, success, error }

class NotificationPreferencesState {
  final NotificationPreferencesStatus status;
  final NotificationPreferencesModel? preferences;
  final String? savingField;
  final String? errorMessage;

  const NotificationPreferencesState({
    this.status = NotificationPreferencesStatus.initial,
    this.preferences,
    this.savingField,
    this.errorMessage,
  });

  bool get isLoading => status == NotificationPreferencesStatus.loading;

  bool get isSaving => savingField != null;

  NotificationPreferencesState copyWith({
    NotificationPreferencesStatus? status,
    NotificationPreferencesModel? preferences,
    Object? savingField = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return NotificationPreferencesState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      savingField: savingField == _sentinel
          ? this.savingField
          : savingField as String?,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const _sentinel = Object();
}
