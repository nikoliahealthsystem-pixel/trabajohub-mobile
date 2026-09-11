import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'models/visit_model.dart';
import 'visits_api.dart';
import 'visits_repository.dart';

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
      page: page,
      status: status,
      flaggedOnly: flaggedOnly,
    );

    final cached = _cache
        .get<({List<VisitModel> visits, int total, bool hasMore})>(key);

    if (cached != null && !cached.isStale) {
      return cached.data;
    }

    final raw = await _api.fetchVisits(
      page: page,
      limit: limit,
      status: status,
      flaggedOnly: flaggedOnly,
    );

    final data = raw['data'] as List? ?? [];

    final pagination =
        raw['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final visits = data
        .whereType<Map<String, dynamic>>()
        .map(VisitModel.fromJson)
        .toList();

    final result = (
      visits: visits,
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

    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    final raw = await _api.fetchVisit(id);

    final data = raw['data'];

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid visit response from server.');
    }

    final visit = VisitModel.fromJson(data);

    _cache.set(key, visit, CacheTtl.visitDetail);

    return visit;
  }

  @override
  Future<VisitModel> checkIn({
    required String visitId,
    required String verificationMethod,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? qrCode,
    String? pin,
    String? reason,
  }) async {
    final raw = await _api.checkIn(
      visitId: visitId,
      verificationMethod: verificationMethod,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      qrCode: qrCode,
      pin: pin,
      reason: reason,
    );

    final visit = _extractAttendanceVisit(raw, actionName: 'check-in');

    _invalidateVisitCaches(visitId);

    return visit;
  }

  @override
  Future<VisitModel> checkOut({
    required String visitId,
    required String verificationMethod,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? qrCode,
    String? pin,
    String? reason,
    String? notes,
  }) async {
    final raw = await _api.checkOut(
      visitId: visitId,
      verificationMethod: verificationMethod,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      qrCode: qrCode,
      pin: pin,
      reason: reason,
      notes: notes,
    );

    final visit = _extractAttendanceVisit(raw, actionName: 'check-out');

    _invalidateVisitCaches(visitId);

    _cache.invalidatePrefix(CacheKeys.prefixMyShifts);

    return visit;
  }

  VisitModel _extractAttendanceVisit(
    Map<String, dynamic> raw, {
    required String actionName,
  }) {
    final data = raw['data'];

    if (data is! Map<String, dynamic>) {
      throw FormatException('Invalid $actionName response: data is missing.');
    }

    final visitJson = data['visit'];

    if (visitJson is! Map<String, dynamic>) {
      throw FormatException(
        'Invalid $actionName response: visit data is missing.',
      );
    }

    return VisitModel.fromJson(visitJson);
  }

  void _invalidateVisitCaches(String visitId) {
    _cache.invalidatePrefix(CacheKeys.prefixVisits);

    _cache.invalidate(CacheKeys.visitDetail(visitId));

    _cache.invalidatePrefix(CacheKeys.prefixCalendar);
  }
}
