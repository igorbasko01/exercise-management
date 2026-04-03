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
        const Text(
          'Exercise Volume',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Expanded(
            child: ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      exercises[index].exerciseName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildSparkline(
                        exercises[index].volumePerDay, context),
                  ),
                ],
              ),
            );
          },
        ))
      ],
    );
  }

  Widget _buildSparkline(List<int> volumes, BuildContext context) {
    if (volumes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SizedBox(
      height: 24,
      width: double.infinity,
      child: CustomPaint(
        painter: SparklinePainter(
          data: volumes,
          lineColor: primaryColor,
          fillColor: primaryColor,
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<int> data;
  final Color lineColor;
  final Color fillColor;

  SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;
    
    final path = Path();
    final fillPath = Path();

    final stepX = data.length > 1 ? size.width / (data.length - 1) : size.width;
    
    double getX(int index) => index * stepX;
    double getY(int val) => range == 0 ? size.height / 2 : size.height - ((val - minVal) / range) * size.height;

    path.moveTo(getX(0), getY(data[0]));
    fillPath.moveTo(getX(0), size.height);
    fillPath.lineTo(getX(0), getY(data[0]));

    for (int i = 1; i < data.length; i++) {
        // Curve using bezier or simple line - using line for a trend
        path.lineTo(getX(i), getY(data[i]));
        fillPath.lineTo(getX(i), getY(data[i]));
    }

    fillPath.lineTo(getX(data.length - 1), size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [fillColor.withValues(alpha: 0.5), fillColor.withValues(alpha: 0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
    
    // Draw dot at the end
    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(Offset(getX(data.length - 1), getY(data.last)), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data || 
           oldDelegate.lineColor != lineColor || 
           oldDelegate.fillColor != fillColor;
  }
}
