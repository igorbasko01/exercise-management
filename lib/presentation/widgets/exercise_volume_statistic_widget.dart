import 'package:flutter/material.dart';

class ExerciseVolumeStatisticWidget extends StatefulWidget {
  const ExerciseVolumeStatisticWidget({super.key});

  @override
  State<ExerciseVolumeStatisticWidget> createState() =>
      _ExerciseVolumeStatisticWidgetState();
}

class _ExerciseVolumeStatisticWidgetState
    extends State<ExerciseVolumeStatisticWidget> {
  final List<ExerciseData> exercises = [
    ExerciseData('Bench Press', [960, 1000, 1600, 500, 600, 700, 2000, 300, 400, 500]),
    ExerciseData('Squat', [10, 20, 30, 40, 50, 60, 70]),
    ExerciseData('Seated Row Very Long Name', [70, 50, 30, 20, 10, 40, 60, 80, 70, 20]),
  ];

  @override
  Widget build(BuildContext context) {
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
                  exercises[index].name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )),
                _buildSimpleBarChart(exercises[index].volumes)
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
          color: Colors.blue,
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
