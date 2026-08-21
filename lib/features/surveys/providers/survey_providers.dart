import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/cache_provider.dart';
import '../../../core/network/dio_client.dart';
import '../data/models/survey_model.dart';
import '../data/surveys_api.dart';
import '../data/surveys_repository.dart';
import '../data/surveys_repository_impl.dart';

final surveysApiProvider = Provider<SurveysApi>((ref) {
  return SurveysApi(ref.watch(dioClientProvider));
});

final surveysRepositoryProvider = Provider<SurveysRepository>((ref) {
  return SurveysRepositoryImpl(ref.watch(surveysApiProvider),ref.watch(appCacheProvider),);
});

final surveyProvider = FutureProvider.family<SurveyModel, String>((ref, shiftId) async {
  final repo = ref.watch(surveysRepositoryProvider);
  return repo.getSurveyForShift(shiftId);
});