import 'package:exercise_management/core/result.dart';

abstract class ExerciseStatisticsRepository {
  /// Returns a list of booleans representing whether an exercise
  /// was performed on each day of the current week.
  /// The week can start from Sunday or Monday based on the
  /// [startFromSunday] parameter.
  /// if [startFromSunday] is true, the week starts from Sunday,
  /// otherwise it starts from Monday.
  /// The list always contains 7 elements, one for each day of the week.
  /// The first element represents Sunday or Monday based on the
  /// [startFromSunday] parameter.
  Future<Result<List<bool>>> getCurrentWeekExerciseDays({bool startFromSunday});
}