import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/presentation/view_models/exercise_statistics_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AverageWeeklyStatisticsWidget extends StatefulWidget {
  const AverageWeeklyStatisticsWidget({super.key});

  @override
  State<AverageWeeklyStatisticsWidget> createState() => _AverageWeeklyStatisticsWidgetState();
}

class _AverageWeeklyStatisticsWidgetState extends State<AverageWeeklyStatisticsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final viewModel = context.read<ExerciseStatisticsViewModel>();
    viewModel.fetchAverageWeekly30Days.execute();
    viewModel.fetchAverageWeekly90Days.execute();
    viewModel.fetchAverageWeeklyHalfYear.execute();
    viewModel.fetchAverageWeeklyYear.execute();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData();
      },
      child: _averageWeeklyStatistics(),
    );
  }

  Consumer<ExerciseStatisticsViewModel> _averageWeeklyStatistics() {
    return Consumer<ExerciseStatisticsViewModel>(
      builder: (context, viewModel, child) {
        final isLoading = viewModel.fetchAverageWeekly30Days.running ||
            viewModel.fetchAverageWeekly90Days.running ||
            viewModel.fetchAverageWeeklyHalfYear.running ||
            viewModel.fetchAverageWeeklyYear.running;

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final hasError = viewModel.fetchAverageWeekly30Days.error ||
            viewModel.fetchAverageWeekly90Days.error ||
            viewModel.fetchAverageWeeklyHalfYear.error ||
            viewModel.fetchAverageWeeklyYear.error;

        if (hasError) {
          return const Center(
            child: Text('Error loading statistics'),
          );
        }

        final avg30Days = _getAverageValue(viewModel.fetchAverageWeekly30Days.result as Result<double>?);
        final avg90Days = _getAverageValue(viewModel.fetchAverageWeekly90Days.result as Result<double>?);
        final avgHalfYear = _getAverageValue(viewModel.fetchAverageWeeklyHalfYear.result as Result<double>?);
        final avgYear = _getAverageValue(viewModel.fetchAverageWeeklyYear.result as Result<double>?);

        return _buildUI(avg30Days, avg90Days, avgHalfYear, avgYear);
      },
    );
  }

  double _getAverageValue(Result<double>? result) {
    if (result is Ok<double>) {
      return result.value;
    }
    return 0.0;
  }

  Widget _buildUI(double avg30Days, double avg90Days, double avgHalfYear, double avgYear) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Average Weekly Exercise Days',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatisticRow(
                period: '30 days',
                average: avg30Days,
              ),
              _StatisticRow(
                period: '90 days',
                average: avg90Days,
              ),
              _StatisticRow(
                period: '6 months',
                average: avgHalfYear,
              ),
              _StatisticRow(
                period: '1 year',
                average: avgYear,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatisticRow extends StatelessWidget {
  final String period;
  final double average;

  const _StatisticRow({
    required this.period,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          period,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          average.toStringAsFixed(1),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
