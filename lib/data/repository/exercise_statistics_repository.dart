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

  /// Returns the average number of exercise days per week for the specified number of days
  /// looking back from today. For example, if [daysLookback] is 30, it will calculate
  /// the average weekly exercise days for the last 30 days.
  Future<Result<double>> getAverageWeeklyExerciseDays(int daysLookback);
}