import 'models/case_model.dart';

abstract class CasesRepository {
  Future<({List<CaseModel> cases, int total, bool hasMore})> getCases({
    int page,
    int limit,
    String? visitType,
    bool? isActive,
    String? search,
  });
  Future<CaseModel> getCase(String id);
}