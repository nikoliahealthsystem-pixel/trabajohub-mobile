import '../data/models/credential_history_model.dart';
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

  /// Credential history keyed by credential ID.
  final Map<String, CredentialHistoryResult> historyByCredentialId;

  /// Credential IDs whose history is currently loading.
  final Set<String> loadingHistoryIds;

  /// Credential-specific history errors.
  final Map<String, String> historyErrors;

  const CredentialsState({
    this.status = CredentialsStatus.initial,
    this.credentials = const [],
    this.isUploading = false,
    this.uploadError,
    this.deletingId,
    this.errorMessage,
    this.historyByCredentialId = const {},
    this.loadingHistoryIds = const {},
    this.historyErrors = const {},
  });

  int get pendingCount => credentials
      .where((credential) => credential.status == CredentialStatus.pending)
      .length;

  int get approvedCount => credentials
      .where(
        (credential) =>
            credential.status == CredentialStatus.approved &&
            !credential.isExpired,
      )
      .length;

  int get expiringCount =>
      credentials.where((credential) => credential.isExpiringSoon).length;

  int get attentionCount =>
      credentials.where((credential) => credential.needsAttention).length;

  CredentialHistoryResult? historyFor(String credentialId) {
    return historyByCredentialId[credentialId];
  }

  bool isHistoryLoading(String credentialId) {
    return loadingHistoryIds.contains(credentialId);
  }

  String? historyErrorFor(String credentialId) {
    return historyErrors[credentialId];
  }

  CredentialsState copyWith({
    CredentialsStatus? status,
    List<CredentialModel>? credentials,
    bool? isUploading,
    Object? uploadError = _sentinel,
    Object? deletingId = _sentinel,
    Object? errorMessage = _sentinel,
    Map<String, CredentialHistoryResult>? historyByCredentialId,
    Set<String>? loadingHistoryIds,
    Map<String, String>? historyErrors,
  }) {
    return CredentialsState(
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
      historyByCredentialId:
          historyByCredentialId ?? this.historyByCredentialId,
      loadingHistoryIds: loadingHistoryIds ?? this.loadingHistoryIds,
      historyErrors: historyErrors ?? this.historyErrors,
    );
  }
}
