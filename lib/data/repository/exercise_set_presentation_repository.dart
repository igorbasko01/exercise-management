import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/services/exercise_ranking_manager.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';

abstract class ExerciseSetPresentationRepository {
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSets({int lastNDays = 7, String? exerciseTemplateId});
  Future<Result<ExerciseSetPresentation>> getExerciseSet(String setId);

  /// All-time rank (1-based; sessions tied on volume share a rank) of every
  /// session — grouped by date and exercise template, ordered by total
  /// volume (weight x reps) descending — optionally filtered by
  /// [exerciseTemplateId]. Computed without materializing every set.
  Future<Result<Map<RankKey, int>>> getSessionVolumeRanks({String? exerciseTemplateId});
  Future<Result<Map<String, DateTime>>> getMostRecentCompletionDate(List<String> templateIds);
  Future<Result<DateTime?>> getStrictMostRecentRoutineCompletionDate(List<String> templateIds);
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSetsByDateAndTemplates(Map<String, DateTime> templateDates);
}
