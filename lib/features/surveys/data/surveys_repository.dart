import 'models/survey_model.dart';
import 'models/survey_response_model.dart';

abstract class SurveysRepository {
  Future<SurveyModel> getSurveyForShift(String shiftId);
  Future<SurveyResponseModel> submitResponse({
    required String shiftId,
    required String visitId,
    required List<Map<String, String>> answers,
  });
}