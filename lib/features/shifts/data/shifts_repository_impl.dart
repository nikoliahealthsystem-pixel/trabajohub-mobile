import 'package:flutter/cupertino.dart';

import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'shifts_api.dart';
import 'shifts_repository.dart';
import 'models/shift_model.dart';
import 'models/shift_assignment_model.dart';

class ShiftsRepositoryImpl implements ShiftsRepository {
  final ShiftsApi _api;
  final AppCache _cache;

  ShiftsRepositoryImpl(this._api, this._cache);

  @override
  Future<({List<ShiftModel> shifts, int total, int page})> getMarketplace({
    int page = 1,
    int limit = 20,
    String? visitType,
    bool? isUrgent,
    double? minPay,
    double? maxPay,
    String? date,
    String? searchQuery,
  }) async {
    final key = CacheKeys.marketplace(
      page: page,
      visitType: visitType,
      isUrgent: isUrgent,
      searchQuery: searchQuery,
    );

    final cached = _cache.get<({List<ShiftModel> shifts, int total, int page})>(key);

    // Serve fresh cache immediately
    if (cached != null && !cached.isStale) return cached.data;

    // Fetch from API
    final raw = await _api.fetchMarketplace(
      page: page, limit: limit,
      visitType: visitType, isUrgent: isUrgent,
      minPay: minPay, maxPay: maxPay,
      date: date, searchQuery: searchQuery,
    );
    final data = raw['data'] as List;
    final pagination = raw['pagination'] as Map<String, dynamic>;
    final result = (
    shifts: data.map((j) => ShiftModel.fromJson(j)).toList(),
    total: pagination['total'] as int,
    page: page,
    );
    _cache.set(key, result, CacheTtl.marketplace);

    // If we had stale data, we already returned it above — this updates the store
    return result;
  }

  @override
  Future<({List<ShiftAssignmentModel> assignments, int total, int page})>
  getMyShifts({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final key = CacheKeys.myShifts(page: page, status: status ?? 'ACCEPTED');
    final cached = _cache.get<({List<ShiftAssignmentModel> assignments, int total, int page})>(key);

    if (cached != null && !cached.isStale) return cached.data;

    final raw = await _api.fetchMyShifts(page: page, limit: limit, status: status);
    final data = raw['data'] as List;
    final pagination = raw['pagination'] as Map<String, dynamic>;
    final result = (
    assignments: data.map((j) => ShiftAssignmentModel.fromJson(j)).toList(),
    total: pagination['total'] as int,
    page: page,
    );
    _cache.set(key, result, CacheTtl.myShifts);
    return result;
  }

  @override
  Future<ShiftModel> getShiftById(String id) async {
    final key = CacheKeys.shiftDetail(id);
    final cached = _cache.get<ShiftModel>(key);
    if (cached != null && !cached.isExpired) return cached.data;

    final raw = await _api.fetchShiftById(id);
    // debugPrint(raw['data'].toString());
    final shift = ShiftModel.fromJson(raw['data']);
    _cache.set(key, shift, CacheTtl.shiftDetail);
    return shift;
  }

  @override
  Future<ShiftAssignmentModel> bookShift(String shiftId) async {
    final raw = await _api.bookShift(shiftId);
    // Invalidate affected caches after booking
    _cache.invalidatePrefix(CacheKeys.prefixMarketplace);
    _cache.invalidatePrefix(CacheKeys.prefixMyShifts);
    _cache.invalidate(CacheKeys.shiftDetail(shiftId));
    _cache.invalidatePrefix(CacheKeys.prefixCalendar);
    return ShiftAssignmentModel.fromJson(raw['data']);
  }

  @override
  Future<void> cancelShift(String shiftId, {String? reason}) async {
    await _api.cancelShift(shiftId, reason: reason);
    _cache.invalidatePrefix(CacheKeys.prefixMyShifts);
    _cache.invalidate(CacheKeys.shiftDetail(shiftId));
    _cache.invalidatePrefix(CacheKeys.prefixCalendar);
  }
}