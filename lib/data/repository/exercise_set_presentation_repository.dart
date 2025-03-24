import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';

abstract class ExerciseSetPresentationRepository {
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSets();
  Future<Result<ExerciseSetPresentation>> getExerciseSet(String setId);
}
