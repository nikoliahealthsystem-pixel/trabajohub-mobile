import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/credentials_repository.dart';
import '../data/models/credential_history_model.dart';
import '../data/models/credential_model.dart';
import 'credentials_state.dart';

class CredentialsNotifier extends StateNotifier<CredentialsState> {
  final CredentialsRepository _repo;

  CredentialsNotifier(this._repo) : super(const CredentialsState());

  Future<void> load() async {
    state = state.copyWith(
      status: CredentialsStatus.loading,
      errorMessage: null,
    );

    try {
      final items = await _repo.getMine();

      state = state.copyWith(
        status: CredentialsStatus.success,
        credentials: items,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: CredentialsStatus.error,
        errorMessage: _errorMessage(e),
      );
    }
  }

  Future<CredentialHistoryResult?> loadHistory(
    String credentialId, {
    bool forceRefresh = false,
  }) async {
    if (credentialId.trim().isEmpty) {
      return null;
    }

    if (!forceRefresh) {
      final existing = state.historyByCredentialId[credentialId];

      if (existing != null) {
        return existing;
      }
    }

    final loading = <String>{...state.loadingHistoryIds, credentialId};

    final errors = <String, String>{...state.historyErrors}
      ..remove(credentialId);

    state = state.copyWith(loadingHistoryIds: loading, historyErrors: errors);

    try {
      final history = await _repo.getHistory(
        credentialId,
        forceRefresh: forceRefresh,
      );

      final updatedHistory = <String, CredentialHistoryResult>{
        ...state.historyByCredentialId,
        credentialId: history,
      };

      final updatedLoading = <String>{...state.loadingHistoryIds}
        ..remove(credentialId);

      state = state.copyWith(
        historyByCredentialId: updatedHistory,
        loadingHistoryIds: updatedLoading,
      );

      return history;
    } catch (e) {
      final updatedLoading = <String>{...state.loadingHistoryIds}
        ..remove(credentialId);

      final updatedErrors = <String, String>{
        ...state.historyErrors,
        credentialId: _errorMessage(e),
      };

      state = state.copyWith(
        loadingHistoryIds: updatedLoading,
        historyErrors: updatedErrors,
      );

      return null;
    }
  }

  Future<bool> upload({
    required String filePath,
    required String fileName,
    required CredentialType type,
    String? customLabel,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    state = state.copyWith(isUploading: true, uploadError: null);

    try {
      final credential = await _repo.upload(
        filePath: filePath,
        fileName: fileName,
        type: type,
        customLabel: customLabel,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
      );

      state = state.copyWith(
        isUploading: false,
        credentials: [credential, ...state.credentials],
        uploadError: null,
      );

      return true;
    } on DioException catch (e) {
      state = state.copyWith(isUploading: false, uploadError: _dioMessage(e));

      return false;
    } catch (e) {
      state = state.copyWith(isUploading: false, uploadError: e.toString());

      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(deletingId: id, errorMessage: null);

    try {
      await _repo.delete(id);

      final history = <String, CredentialHistoryResult>{
        ...state.historyByCredentialId,
      }..remove(id);

      final historyErrors = <String, String>{...state.historyErrors}
        ..remove(id);

      final loadingHistoryIds = <String>{...state.loadingHistoryIds}
        ..remove(id);

      state = state.copyWith(
        deletingId: null,
        credentials: state.credentials
            .where((credential) => credential.id != id)
            .toList(),
        historyByCredentialId: history,
        historyErrors: historyErrors,
        loadingHistoryIds: loadingHistoryIds,
      );

      return true;
    } catch (e) {
      state = state.copyWith(deletingId: null, errorMessage: _errorMessage(e));

      return false;
    }
  }

  void clearHistoryError(String credentialId) {
    final errors = <String, String>{...state.historyErrors}
      ..remove(credentialId);

    state = state.copyWith(historyErrors: errors);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null, uploadError: null);
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      return _dioMessage(error);
    }

    return error.toString();
  }

  String _dioMessage(DioException error) {
    final responseMessage = error.response?.data is Map
        ? (error.response?.data['message']?.toString())
        : null;

    if (responseMessage != null && responseMessage.trim().isNotEmpty) {
      return responseMessage;
    }

    final inner = error.error?.toString();

    if (inner != null && inner.trim().isNotEmpty) {
      return inner;
    }

    return 'Something went wrong';
  }
}
