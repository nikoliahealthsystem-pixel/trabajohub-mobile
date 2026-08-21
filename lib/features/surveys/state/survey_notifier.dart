import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/surveys_repository.dart';
import '../data/models/survey_model.dart';
import '../data/models/survey_response_model.dart';
import '../providers/survey_providers.dart';

class SurveyState {
  final bool isLoading;
  final bool isSubmitting;
  final SurveyModel? survey;
  final String? error;
  final String? successMessage;
  final Map<String, String> answers; // questionId -> answer

  const SurveyState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.survey,
    this.error,
    this.successMessage,
    this.answers = const {},
  });

  SurveyState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    SurveyModel? survey,
    String? error,
    String? successMessage,
    Map<String, String>? answers,
  }) {
    return SurveyState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      survey: survey ?? this.survey,
      error: error,
      successMessage: successMessage,
      answers: answers ?? this.answers,
    );
  }
}

class SurveyNotifier extends StateNotifier<SurveyState> {
  final SurveysRepository _repo;

  SurveyNotifier(this._repo) : super(const SurveyState());

  Future<void> loadSurvey(String shiftId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final survey = await _repo.getSurveyForShift(shiftId);
      state = state.copyWith(survey: survey, isLoading: false);
    } catch (e) {
      final msg = e is DioException ? (e.message ?? 'Something went wrong') : e.toString();
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  void updateAnswer(String questionId, String answer) {
    final newAnswers = Map<String, String>.from(state.answers);
    newAnswers[questionId] = answer;
    state = state.copyWith(answers: newAnswers);
  }

  Future<bool> submitSurvey(String shiftId, String visitId) async {
    if (state.survey == null) return false;

    state = state.copyWith(isSubmitting: true, error: null);

    final answersList = state.answers.entries
        .map((e) => {'questionId': e.key, 'answer': e.value})
        .toList();

    try {
      await _repo.submitResponse(
        shiftId: shiftId,
        visitId: visitId,
        answers: answersList,
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Survey submitted successfully!',
      );
      return true;
    } catch (e) {
      final msg = e is DioException ? (e.message ?? 'Something went wrong') : e.toString();
      state = state.copyWith(isSubmitting: false, error: msg);
      return false;
    }
  }
}

final surveyNotifierProvider = StateNotifierProvider.family<SurveyNotifier, SurveyState, String>(
      (ref, shiftId) => SurveyNotifier(ref.watch(surveysRepositoryProvider)),
);