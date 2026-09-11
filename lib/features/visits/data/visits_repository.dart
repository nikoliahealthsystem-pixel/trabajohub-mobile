import 'models/visit_model.dart';

abstract class VisitsRepository {
  Future<({List<VisitModel> visits, int total, bool hasMore})> getVisits({
    int page,
    int limit,
    String? status,
    bool flaggedOnly,
  });

  Future<VisitModel> getVisit(String id);

  Future<VisitModel> checkIn({
    required String visitId,
    required String verificationMethod,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? qrCode,
    String? pin,
    String? reason,
  });

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
  });
}
