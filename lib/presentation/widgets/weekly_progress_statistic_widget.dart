import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/presentation/view_models/exercise_statistics_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WeeklyProgressStatisticWidget extends StatefulWidget {
  const WeeklyProgressStatisticWidget({super.key});

  @override
  State<WeeklyProgressStatisticWidget> createState() =>
      _WeeklyProgressStatisticWidgetState();
}

class _WeeklyProgressStatisticWidgetState
    extends State<WeeklyProgressStatisticWidget> {
  static const List<String> _days = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final viewModel = context.read<ExerciseStatisticsViewModel>();
    viewModel.fetchCurrentWeekExerciseDaysStatistic.execute();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData();
      },
      child: _exerciseStatistics(),
    );
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
          child: Text(
              (viewModel.fetchCurrentWeekExerciseDaysStatistic.result as Error)
                  .toString()),
        );
      }

      final daysExercised = viewModel
              .fetchCurrentWeekExerciseDaysStatistic.result is Ok
          ? (viewModel.fetchCurrentWeekExerciseDaysStatistic.result as Ok).value
          : List.filled(viewModel.daysInWeek, false);

      return _buildUI(context, daysExercised);
    });
  }

  Widget _buildUI(BuildContext context, List<bool> daysExercised) {
    final completedDays = daysExercised.where((e) => e).length;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _days.asMap().entries.map((entry) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: entry.key == 0 ? 0 : 2.0,
                    right: entry.key == 6 ? 0 : 2.0,
                  ),
                  child: _DaySegment(
                    day: entry.value,
                    exercised: daysExercised[entry.key],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 24),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$completedDays/7',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'Days',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DaySegment extends StatelessWidget {
  final String day;
  final bool exercised;

  const _DaySegment({
    required this.day,
    required this.exercised,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: exercised 
                ? theme.colorScheme.primary 
                : theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day.substring(0, 1),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: exercised ? FontWeight.bold : FontWeight.normal,
            color: exercised 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
