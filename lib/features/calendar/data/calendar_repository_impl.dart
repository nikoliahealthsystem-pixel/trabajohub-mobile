import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'calendar_api.dart';
import 'calendar_repository.dart';
import 'models/calendar_event_model.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarApi _api;
  final AppCache _cache;

  CalendarRepositoryImpl(this._api, this._cache);

  @override
  Future<List<CalendarEventModel>> getEvents({
    required DateTime from,
    required DateTime to,
    List<CalendarEventType>? types,
    String? facilityId,
    String? nurseProfileId,
  }) async {
    final typeStr = types?.map((t) => t.toApiString()).join(',');
    final key = CacheKeys.calendarEvents(
      from: from.toIso8601String().substring(0, 10),
      to: to.toIso8601String().substring(0, 10),
      types: typeStr,
    );

    final cached = _cache.get<List<CalendarEventModel>>(key);
    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchEvents(
      from: from.toUtc().toIso8601String(),
      to: to.toUtc().toIso8601String(),
      types: types?.map((t) => t.toApiString()).toList(),
      facilityId: facilityId,
      nurseProfileId: nurseProfileId,
    );
    final events = (raw['data']?['events'] as List? ?? [])
        .map((j) => CalendarEventModel.fromJson(j))
        .toList();

    _cache.set(key, events, CacheTtl.calendar);
    return events;
  }

  @override
  Future<List<CalendarEventModel>> getUpcomingEvents({int limit = 10}) async {
    final key = 'calendar:upcoming:$limit';
    final cached = _cache.get<List<CalendarEventModel>>(key);
    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchUpcoming(limit: limit);
    final events = (raw['data']?['events'] as List? ?? [])
        .map((j) => CalendarEventModel.fromJson(j))
        .toList();
    _cache.set(key, events, CacheTtl.calendar);
    return events;
  }
}