import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'models/survey_model.dart';
import 'models/survey_response_model.dart';

class SurveysApi {
  final DioClient _client;
  SurveysApi(this._client);

  Future<Map<String, dynamic>> getSurveyForShift(String shiftId) async {
    final response = await _client.instance.get('/Surveys/shifts/$shiftId/survey');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitSurveyResponse({
    required String shiftId,
    required String visitId,
    required List<Map<String, String>> answers,
  }) async {
    final response = await _client.instance.post(
      '/Surveys/shifts/$shiftId/survey/respond',
      data: {
        'visitId': visitId,
        'answers': answers,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}