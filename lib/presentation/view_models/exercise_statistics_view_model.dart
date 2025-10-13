import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_volume_statistic.dart';
import 'package:exercise_management/data/repository/exercise_statistics_repository.dart';
import 'package:flutter/material.dart';

class ExerciseStatisticsViewModel extends ChangeNotifier {
  ExerciseStatisticsViewModel(
      {required ExerciseStatisticsRepository statisticsRepository})
      : _statisticsRepository = statisticsRepository {
    fetchCurrentWeekExerciseDaysStatistic =
        Command0<List<bool>>(_fetchCurrentWeekExerciseDaysStatistic)
          ..addListener(_onCommandExecuted);

    fetchAverageWeekly30Days =
        Command0<double>(() => _fetchAverageWeeklyExerciseDays(30))
          ..addListener(_onCommandExecuted);
    fetchAverageWeekly90Days =
        Command0<double>(() => _fetchAverageWeeklyExerciseDays(90))
          ..addListener(_onCommandExecuted);
    fetchAverageWeeklyHalfYear =
        Command0<double>(() => _fetchAverageWeeklyExerciseDays(182))
          ..addListener(_onCommandExecuted);
    fetchAverageWeeklyYear =
        Command0<double>(() => _fetchAverageWeeklyExerciseDays(365))
          ..addListener(_onCommandExecuted);

    fetchExerciseVolumeStatistics =
        Command0<List<ExerciseVolumeStatistics>>(_fetchExerciseVolumeStatistics)
          ..addListener(_onCommandExecuted);
  }

  final int daysInWeek = 7;

  final ExerciseStatisticsRepository _statisticsRepository;

  late final Command0<List<bool>> fetchCurrentWeekExerciseDaysStatistic;
  late final Command0<double> fetchAverageWeekly30Days;
  late final Command0<double> fetchAverageWeekly90Days;
  late final Command0<double> fetchAverageWeeklyHalfYear;
  late final Command0<double> fetchAverageWeeklyYear;

  late final Command0<List<ExerciseVolumeStatistics>>
      fetchExerciseVolumeStatistics;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<List<bool>>> _fetchCurrentWeekExerciseDaysStatistic() async {
    final result = await _statisticsRepository.getCurrentWeekExerciseDays(
        startFromSunday: true);
    switch (result) {
      case Ok<List<bool>>():
        return result;
      case Error<List<bool>>():
        return Result.ok(List.filled(daysInWeek, false));
    }
  }

  Future<Result<double>> _fetchAverageWeeklyExerciseDays(
      int daysLookBack) async {
    final result =
        await _statisticsRepository.getAverageWeeklyExerciseDays(daysLookBack);
    switch (result) {
      case Ok<double>():
        return result;
      case Error<double>():
        return Result.ok(0.0);
    }
  }

  Future<Result<List<ExerciseVolumeStatistics>>>
      _fetchExerciseVolumeStatistics() async {
    final result = await _statisticsRepository.getExerciseVolumeStatistics(numberOfExercises: 8);
    switch (result) {
      case Ok<List<ExerciseVolumeStatistics>>():
        return result;
      case Error<List<ExerciseVolumeStatistics>>():
        return Result.ok([]);
    }
  }

  @override
  void dispose() {
    fetchCurrentWeekExerciseDaysStatistic.removeListener(_onCommandExecuted);
    fetchCurrentWeekExerciseDaysStatistic.dispose();
    fetchAverageWeekly30Days.removeListener(_onCommandExecuted);
    fetchAverageWeekly30Days.dispose();
    fetchAverageWeekly90Days.removeListener(_onCommandExecuted);
    fetchAverageWeekly90Days.dispose();
    fetchAverageWeeklyHalfYear.removeListener(_onCommandExecuted);
    fetchAverageWeeklyHalfYear.dispose();
    fetchAverageWeeklyYear.removeListener(_onCommandExecuted);
    fetchAverageWeeklyYear.dispose();
    fetchExerciseVolumeStatistics.removeListener(_onCommandExecuted);
    fetchExerciseVolumeStatistics.dispose();
    super.dispose();
  }
}
