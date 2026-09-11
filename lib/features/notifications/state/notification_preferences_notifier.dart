import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/notifications_repository.dart';
import 'notification_preferences_state.dart';

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferencesState> {
  final NotificationsRepository _repository;

  NotificationPreferencesNotifier(this._repository)
    : super(const NotificationPreferencesState());

  Future<void> load() async {
    if (state.status == NotificationPreferencesStatus.loading) {
      return;
    }

    state = state.copyWith(
      status: NotificationPreferencesStatus.loading,
      errorMessage: null,
    );

    try {
      final preferences = await _repository.getPreferences();

      state = state.copyWith(
        status: NotificationPreferencesStatus.success,
        preferences: preferences,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        status: NotificationPreferencesStatus.error,
        errorMessage: _message(error),
      );
    }
  }

  Future<bool> updateField(String field, bool value) async {
    final current = state.preferences;

    if (current == null || state.savingField != null) {
      return false;
    }

    final optimistic = _applyLocal(current, field, value);

    state = state.copyWith(
      preferences: optimistic,
      savingField: field,
      errorMessage: null,
    );

    try {
      final saved = await _repository.updatePreferences({field: value});

      state = state.copyWith(
        status: NotificationPreferencesStatus.success,
        preferences: saved,
        savingField: null,
        errorMessage: null,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        preferences: current,
        savingField: null,
        errorMessage: _message(error),
      );

      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'];

        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }

      return error.message ?? 'Unable to update notification preferences.';
    }

    return error.toString();
  }

  dynamic _applyLocal(dynamic current, String field, bool value) {
    switch (field) {
      case 'pushEnabled':
        return current.copyWith(pushEnabled: value);

      case 'emailEnabled':
        return current.copyWith(emailEnabled: value);

      case 'shiftOffersEnabled':
        return current.copyWith(shiftOffersEnabled: value);

      case 'assignmentUpdatesEnabled':
        return current.copyWith(assignmentUpdatesEnabled: value);

      case 'shiftRemindersEnabled':
        return current.copyWith(shiftRemindersEnabled: value);

      case 'shiftCancellationsEnabled':
        return current.copyWith(shiftCancellationsEnabled: value);

      case 'urgentShiftsEnabled':
        return current.copyWith(urgentShiftsEnabled: value);

      case 'evvExceptionsEnabled':
        return current.copyWith(evvExceptionsEnabled: value);

      case 'visitUpdatesEnabled':
        return current.copyWith(visitUpdatesEnabled: value);

      case 'earningsEnabled':
        return current.copyWith(earningsEnabled: value);

      case 'payoutsEnabled':
        return current.copyWith(payoutsEnabled: value);

      case 'credentialUpdatesEnabled':
        return current.copyWith(credentialUpdatesEnabled: value);

      case 'credentialExpiryEnabled':
        return current.copyWith(credentialExpiryEnabled: value);

      case 'messagesEnabled':
        return current.copyWith(messagesEnabled: value);

      default:
        return current;
    }
  }
}
