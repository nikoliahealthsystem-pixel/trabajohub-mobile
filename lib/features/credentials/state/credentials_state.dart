import '../data/models/credential_model.dart';

const _sentinel = Object();

enum CredentialsStatus { initial, loading, success, error }

class CredentialsState {
  final CredentialsStatus status;
  final List<CredentialModel> credentials;
  final bool isUploading;
  final String? uploadError;
  final String? deletingId;
  final String? errorMessage;

  const CredentialsState({
    this.status = CredentialsStatus.initial,
    this.credentials = const [],
    this.isUploading = false,
    this.uploadError,
    this.deletingId,
    this.errorMessage,
  });

  int get pendingCount =>
      credentials.where((c) => c.status == CredentialStatus.pending).length;
  int get approvedCount =>
      credentials.where((c) => c.status == CredentialStatus.approved).length;
  int get expiringCount =>
      credentials.where((c) => c.isExpiringSoon).length;

  CredentialsState copyWith({
    CredentialsStatus? status,
    List<CredentialModel>? credentials,
    bool? isUploading,
    Object? uploadError = _sentinel,
    Object? deletingId = _sentinel,
    Object? errorMessage = _sentinel,
  }) =>
      CredentialsState(
        status: status ?? this.status,
        credentials: credentials ?? this.credentials,
        isUploading: isUploading ?? this.isUploading,
        uploadError: uploadError == _sentinel
            ? this.uploadError
            : uploadError as String?,
        deletingId: deletingId == _sentinel
            ? this.deletingId
            : deletingId as String?,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}