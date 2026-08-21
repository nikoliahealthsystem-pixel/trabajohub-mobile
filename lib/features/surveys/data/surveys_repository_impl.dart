import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'models/survey_model.dart';
import 'models/survey_response_model.dart';
import 'surveys_api.dart';
import 'surveys_repository.dart';

class SurveysRepositoryImpl implements SurveysRepository {
  final SurveysApi _api;
  final AppCache _cache;

  SurveysRepositoryImpl(this._api, this._cache);

  @override
  Future<SurveyModel> getSurveyForShift(String shiftId) async {
    final key = CacheKeys.survey(shiftId);

    final cached = _cache.get<SurveyModel>(key);
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    final raw = await _api.getSurveyForShift(shiftId);
    final data = raw['data'] as Map<String, dynamic>;
    final survey = SurveyModel.fromJson(data);

    _cache.set(key, survey, CacheTtl.survey);
    return survey;
  }

  @override
  Future<SurveyResponseModel> submitResponse({
    required String shiftId,
    required String visitId,
    required List<Map<String, String>> answers,
  }) async {
    final raw = await _api.submitSurveyResponse(
      shiftId: shiftId,
      visitId: visitId,
      answers: answers,
    );

    // Invalidate cache after submission
    _cache.invalidate(CacheKeys.survey(shiftId));

    return SurveyResponseModel.fromJson(raw['data']);
  }
}