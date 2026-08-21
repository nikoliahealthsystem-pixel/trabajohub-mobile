import 'survey_model.dart';

class SurveyResponseModel {
  final String id;
  final String surveyId;
  final String nurseProfileId;
  final String visitId;
  final List<SurveyResponseAnswer> answers;

  const SurveyResponseModel({
    required this.id,
    required this.surveyId,
    required this.nurseProfileId,
    required this.visitId,
    required this.answers,
  });

  factory SurveyResponseModel.fromJson(Map<String, dynamic> json) =>
      SurveyResponseModel(
        id: json['id'],
        surveyId: json['surveyId'],
        nurseProfileId: json['nurseProfileId'],
        visitId: json['visitId'],
        answers: (json['answers'] as List<dynamic>? ?? [])
            .map((a) => SurveyResponseAnswer.fromJson(a))
            .toList(),
      );
}