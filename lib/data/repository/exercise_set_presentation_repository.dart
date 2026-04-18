import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';

abstract class ExerciseSetPresentationRepository {
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSets({int lastNDays = 7, String? exerciseTemplateId});
  Future<Result<ExerciseSetPresentation>> getExerciseSet(String setId);
  Future<Result<Map<String, DateTime>>> getMostRecentCompletionDate(List<String> templateIds);
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSetsByDateAndTemplates(Map<String, DateTime> templateDates);
}
