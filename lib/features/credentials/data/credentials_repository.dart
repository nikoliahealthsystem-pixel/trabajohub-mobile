import 'models/credential_model.dart';

abstract class CredentialsRepository {
  Future<List<CredentialModel>> getMine();
  Future<CredentialModel> getOne(String id);
  Future<CredentialModel> upload({
    required String filePath,
    required String fileName,
    required CredentialType type,
    String? customLabel,
    DateTime? issuedAt,
    DateTime? expiresAt,
  });
  Future<void> delete(String id);
}