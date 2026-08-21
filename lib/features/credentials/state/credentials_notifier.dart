import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/credentials_repository.dart';
import '../data/models/credential_model.dart';
import 'credentials_state.dart';

class CredentialsNotifier extends StateNotifier<CredentialsState> {
  final CredentialsRepository _repo;
  CredentialsNotifier(this._repo) : super(const CredentialsState());

  Future<void> load() async {
    state = state.copyWith(status: CredentialsStatus.loading);
    try {
      final items = await _repo.getMine();
      state = state.copyWith(
          status: CredentialsStatus.success, credentials: items);
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(
          status: CredentialsStatus.error, errorMessage: message);
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
    state = state.copyWith(
      isUploading: true,
      uploadError: null,
    );

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
      );

      return true;
    } on DioException catch (e) {
      final message = e.error?.toString() ??
          e.response?.data?['message']?.toString() ??
          'Something went wrong';

      state = state.copyWith(
        isUploading: false,
        uploadError: message,
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadError: e.toString(),
      );

      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(deletingId: id);
    try {
      await _repo.delete(id);
      state = state.copyWith(
        deletingId: null,
        credentials:
        state.credentials.where((c) => c.id != id).toList(),
      );
      return true;
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(
          deletingId: null, errorMessage: message);
      return false;
    }
  }

  void clearError() =>
      state = state.copyWith(errorMessage: null, uploadError: null);
}