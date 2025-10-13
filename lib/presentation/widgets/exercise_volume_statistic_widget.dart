import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_volume_statistic.dart';
import 'package:exercise_management/presentation/view_models/exercise_statistics_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExerciseVolumeStatisticWidget extends StatefulWidget {
  const ExerciseVolumeStatisticWidget({super.key});

  @override
  State<ExerciseVolumeStatisticWidget> createState() =>
      _ExerciseVolumeStatisticWidgetState();
}

class _ExerciseVolumeStatisticWidgetState
    extends State<ExerciseVolumeStatisticWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final viewModel = context.read<ExerciseStatisticsViewModel>();
    viewModel.fetchExerciseVolumeStatistics.execute();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExerciseStatisticsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.fetchExerciseVolumeStatistics.running) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.fetchExerciseVolumeStatistics.error) {
          return const Center(
            child: Text('Error loading data'),
          );
        }

        final exercises = viewModel.fetchExerciseVolumeStatistics.result
            as Ok<List<ExerciseVolumeStatistics>>?;

        if (exercises == null) {
          return const Center(
            child: Text('No data available'),
          );
        }

        return _buildUI(exercises.value);
      },
    );
  }

  Widget _buildUI(List<ExerciseVolumeStatistics> exercises) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Exercise Volume',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 15),
        Expanded(
            child: ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(
                  exercises[index].exerciseName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )),
                // Take last 20 days
                _buildSimpleBarChart(exercises[index].volumePerDay
                    .sublist(
                        exercises[index].volumePerDay.length > 20
                            ? exercises[index].volumePerDay.length - 20
                            : 0)),
              ],
            );
          },
        ))
      ],
    );
  }

  Widget _buildSimpleBarChart(List<int> volumes) {
    final maxVolume = volumes.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: volumes.map((volume) {
        return Container(
          width: 5,
          height: (volume / maxVolume) * 12,
          color: volume == maxVolume ? Colors.green : Colors.blue,
        );
      }).toList(),
    );
  }
}

class ExerciseData {
  final String name;
  final List<int> volumes;

  ExerciseData(this.name, this.volumes);
}
