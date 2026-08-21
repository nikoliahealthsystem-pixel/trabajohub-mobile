import 'models/calendar_event_model.dart';

abstract class CalendarRepository {
  Future<List<CalendarEventModel>> getEvents({
    required DateTime from,
    required DateTime to,
    List<CalendarEventType>? types,
    String? facilityId,
    String? nurseProfileId,
  });

  Future<List<CalendarEventModel>> getUpcomingEvents({int limit});
}