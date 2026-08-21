import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'cases_api.dart';
import 'cases_repository.dart';
import 'models/case_model.dart';

class CasesRepositoryImpl implements CasesRepository {
  final CasesApi _api;
  final AppCache _cache;

  CasesRepositoryImpl(this._api, this._cache);

  @override
  Future<({List<CaseModel> cases, int total, bool hasMore})> getCases({
    int page = 1,
    int limit = 20,
    String? visitType,
    bool? isActive,
    String? search,
  }) async {
    final key = CacheKeys.cases(page: page, visitType: visitType, search: search);
    final cached =
    _cache.get<({List<CaseModel> cases, int total, bool hasMore})>(key);
    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchCases(
        page: page, limit: limit,
        visitType: visitType, isActive: isActive, search: search);
    final data = raw['data'] as List? ?? [];
    final pagination = raw['pagination'] as Map<String, dynamic>? ?? {};
    final result = (
    cases: data.map((j) => CaseModel.fromJson(j)).toList(),
    total: pagination['total'] as int? ?? 0,
    hasMore: pagination['hasNext'] as bool? ?? false,
    );
    _cache.set(key, result, CacheTtl.cases);
    return result;
  }

  @override
  Future<CaseModel> getCase(String id) async {
    final key = CacheKeys.caseDetail(id);
    final cached = _cache.get<CaseModel>(key);
    if (cached != null && !cached.isExpired) return cached.data;

    final raw = await _api.fetchCase(id);
    final caseModel = CaseModel.fromJson(raw['data']);
    _cache.set(key, caseModel, CacheTtl.caseDetail);
    return caseModel;
  }
}