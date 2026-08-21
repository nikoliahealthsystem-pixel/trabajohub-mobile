import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/calendar_api.dart';
import '../data/calendar_repository.dart';
import '../data/calendar_repository_impl.dart';
import '../state/calendar_notifier.dart';
import '../state/calendar_state.dart';

final calendarApiProvider = Provider<CalendarApi>((ref) {
  return CalendarApi(ref.watch(dioClientProvider));
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepositoryImpl(ref.watch(calendarApiProvider), ref.watch(appCacheProvider));
});

final calendarProvider =
StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier(ref.watch(calendarRepositoryProvider));
});