import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/repository/exercise_statistics_repository.dart';
import 'package:flutter/material.dart';

class ExerciseStatisticsViewModel extends ChangeNotifier {
  ExerciseStatisticsViewModel(
      {required ExerciseStatisticsRepository statisticsRepository})
      : _statisticsRepository = statisticsRepository {
    fetchCurrentWeekExerciseDaysStatistic =
        Command0<List<bool>>(_fetchCurrentWeekExerciseDaysStatistic)
          ..addListener(_onCommandExecuted);
  }

  final ExerciseStatisticsRepository _statisticsRepository;

  late final Command0<List<bool>> fetchCurrentWeekExerciseDaysStatistic;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<List<bool>>> _fetchCurrentWeekExerciseDaysStatistic() async {
    final result =
        await _statisticsRepository.getCurrentWeekExerciseDays(startFromSunday: true);
    switch (result) {
      case Ok<List<bool>>():
        return result;
      case Error<List<bool>>():
        return Result.ok(List.filled(7, false));
    }
  }

  @override void dispose() {
    fetchCurrentWeekExerciseDaysStatistic.removeListener(_onCommandExecuted);
    fetchCurrentWeekExerciseDaysStatistic.dispose();
    super.dispose();
  }
}
