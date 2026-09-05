import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';

abstract class ExerciseSetPresentationRepository {
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSets({int lastNDays = 7, String? exerciseTemplateId});
  Future<Result<ExerciseSetPresentation>> getExerciseSet(String setId);

  /// All sets ever recorded, optionally filtered by [exerciseTemplateId].
  /// Used for all-time ranking, independent of any pagination window.
  Future<Result<List<ExerciseSetPresentation>>> getAllExerciseSets({String? exerciseTemplateId});
  Future<Result<Map<String, DateTime>>> getMostRecentCompletionDate(List<String> templateIds);
  Future<Result<DateTime?>> getStrictMostRecentRoutineCompletionDate(List<String> templateIds);
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSetsByDateAndTemplates(Map<String, DateTime> templateDates);
}
