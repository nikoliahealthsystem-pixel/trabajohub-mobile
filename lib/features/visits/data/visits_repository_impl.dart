import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'visits_api.dart';
import 'visits_repository.dart';
import 'models/visit_model.dart';

class VisitsRepositoryImpl implements VisitsRepository {
  final VisitsApi _api;
  final AppCache _cache;

  VisitsRepositoryImpl(this._api, this._cache);

  @override
  Future<({List<VisitModel> visits, int total, bool hasMore})> getVisits({
    int page = 1,
    int limit = 20,
    String? status,
    bool flaggedOnly = false,
  }) async {
    final key = CacheKeys.visits(
        page: page, status: status, flaggedOnly: flaggedOnly);
    final cached =
    _cache.get<({List<VisitModel> visits, int total, bool hasMore})>(key);
    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchVisits(
        page: page, limit: limit, status: status, flaggedOnly: flaggedOnly);
    final data = raw['data'] as List? ?? [];
    final pagination = raw['pagination'] as Map<String, dynamic>? ?? {};
    final result = (
    visits: data.map((j) => VisitModel.fromJson(j)).toList(),
    total: pagination['total'] as int? ?? 0,
    hasMore: pagination['hasNext'] as bool? ?? false,
    );
    _cache.set(key, result, CacheTtl.visits);
    return result;
  }
  @override
  Future<VisitModel> getVisit(String id) async {
    final key = CacheKeys.visitDetail(id);
    final cached = _cache.get<VisitModel>(key);
    if (cached != null && !cached.isExpired) return cached.data;

    final raw = await _api.fetchVisit(id);
    final visit = VisitModel.fromJson(raw['data']);
    _cache.set(key, visit, CacheTtl.visitDetail);
    return visit;
  }

  @override
  Future<VisitModel> checkIn({
    required String visitId,
    required double latitude,
    required double longitude,
    String? qrCode,
  }) async {
    final raw = await _api.checkIn(
        visitId: visitId, latitude: latitude,
        longitude: longitude, qrCode: qrCode);
    // Bust visit caches after state change
    _cache.invalidatePrefix(CacheKeys.prefixVisits);
    _cache.invalidate(CacheKeys.visitDetail(visitId));
    _cache.invalidatePrefix(CacheKeys.prefixCalendar);
    return VisitModel.fromJson(raw['data']);
  }

  @override
  Future<VisitModel> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    final raw = await _api.checkOut(
        visitId: visitId, latitude: latitude,
        longitude: longitude, notes: notes);
    _cache.invalidatePrefix(CacheKeys.prefixVisits);
    _cache.invalidate(CacheKeys.visitDetail(visitId));
    _cache.invalidatePrefix(CacheKeys.prefixMyShifts);
    _cache.invalidatePrefix(CacheKeys.prefixCalendar);
    return VisitModel.fromJson(raw['data']);
  }
}