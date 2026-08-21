import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'credentials_api.dart';
import 'credentials_repository.dart';
import 'models/credential_model.dart';

class CredentialsRepositoryImpl implements CredentialsRepository {
  final CredentialsApi _api;
  final AppCache _cache;

  CredentialsRepositoryImpl(this._api, this._cache);

  @override
  Future<List<CredentialModel>> getMine() async {
    final cached = _cache.get<List<CredentialModel>>(CacheKeys.credentials);
    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchMine();
    final data = raw['data'] as List? ?? [];
    final credentials =
    data.map((j) => CredentialModel.fromJson(j)).toList();
    _cache.set(CacheKeys.credentials, credentials, CacheTtl.credentials);
    return credentials;
  }

  @override
  Future<CredentialModel> getOne(String id) async {
    final key = CacheKeys.credentialDetail(id);
    final cached = _cache.get<CredentialModel>(key);
    if (cached != null && !cached.isExpired) return cached.data;

    final raw = await _api.fetchOne(id);
    final credential = CredentialModel.fromJson(raw['data']);
    _cache.set(key, credential, CacheTtl.credentials);
    return credential;
  }

  @override
  Future<CredentialModel> upload({
    required String filePath,
    required String fileName,
    required CredentialType type,
    String? customLabel,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) async {
    final raw = await _api.uploadCredential(
      filePath: filePath,
      fileName: fileName,
      type: type.toApiString(),
      customLabel: customLabel,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );

    _cache.invalidate(CacheKeys.credentials);
    _cache.invalidate(CacheKeys.me);

    return CredentialModel.fromJson(raw['data']);
  }

  @override
  Future<void> delete(String id) async {
    await _api.deleteCredential(id);
    _cache.invalidate(CacheKeys.credentials);
    _cache.invalidate(CacheKeys.credentialDetail(id));
    _cache.invalidate(CacheKeys.me);
  }
}