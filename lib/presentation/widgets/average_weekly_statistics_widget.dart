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

        final avg30Days = _getAverageValue(viewModel.fetchAverageWeekly30Days.result);
        final avg90Days = _getAverageValue(viewModel.fetchAverageWeekly90Days.result);
        final avgHalfYear = _getAverageValue(viewModel.fetchAverageWeeklyHalfYear.result);
        final avgYear = _getAverageValue(viewModel.fetchAverageWeeklyYear.result);

        return _buildUI(avg30Days, avg90Days, avgHalfYear, avgYear);
      },
    );
  }

  double _getAverageValue(Result<dynamic>? result) {
    if (result is Ok<double>) {
      return result.value;
    }
    return 0.0;
  }

  Widget _buildUI(double avg30Days, double avg90Days, double avgHalfYear, double avgYear) {
    return Row(
      children: [
        _StatisticCard(period: '30 days', average: avg30Days),
        _StatisticCard(period: '90 days', average: avg90Days),
        _StatisticCard(period: '6 months', average: avgHalfYear),
        _StatisticCard(period: '1 year', average: avgYear),
      ],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String period;
  final double average;

  const _StatisticCard({
    required this.period,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                period,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
