import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/presentation/view_models/exercise_statistics_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeeklyProgressStatisticWidget extends StatelessWidget {
  static const List<String> _days = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  const WeeklyProgressStatisticWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _exerciseStatistics();
  }

  Consumer<ExerciseStatisticsViewModel> _exerciseStatistics() {
    return Consumer<ExerciseStatisticsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.fetchCurrentWeekExerciseDaysStatistic.running) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.fetchCurrentWeekExerciseDaysStatistic.error) {
            return Center(
              child: Text((viewModel.fetchCurrentWeekExerciseDaysStatistic.result as Error).toString()),
            );
          }

          final daysExercised = viewModel.fetchCurrentWeekExerciseDaysStatistic.result is Ok
              ? (viewModel.fetchCurrentWeekExerciseDaysStatistic.result as Ok).value
              : List.filled(viewModel.daysInWeek, false);

          return _buildUI(daysExercised);
        });
  }

  Widget _buildUI(List<bool> daysExercised) {
    return Column(
      children: [
        const Text('Weekly Progress'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _days
              .sublist(0, 5)
              .asMap()
              .entries
              .map((entry) => _DayIndicator(
            day: entry.value,
            exercised: daysExercised[entry.key],
          ))
              .toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _days
              .sublist(5)
              .asMap()
              .entries
              .map((entry) => _DayIndicator(
            day: entry.value,
            exercised: daysExercised[entry.key + 5],
          ))
              .toList(),
        ),
        const SizedBox(height: 15),
        Text(
          '${daysExercised.where((e) => e).length}',
          style: const TextStyle(fontSize: 38),
        ),
      ],
    );
  }
}

class _DayIndicator extends StatelessWidget {
  final String day;
  final bool exercised;

  const _DayIndicator({
    required this.day,
    required this.exercised,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: exercised
                ? Colors.green
                : Colors.grey,
          ),
        ),
      ],
    );
  }
}
