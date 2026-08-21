import 'models/visit_model.dart';

abstract class VisitsRepository {
  Future<({List<VisitModel> visits, int total, bool hasMore})> getVisits({
    int page, int limit, String? status, bool flaggedOnly,
  });
  Future<VisitModel> getVisit(String id);

  Future<VisitModel> checkIn({
    required String visitId,
    required double latitude,
    required double longitude,
    String? qrCode,
  });

  Future<VisitModel> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  });
}