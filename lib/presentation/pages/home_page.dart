import 'package:exercise_management/presentation/view_models/exercise_programs_view_model.dart';
import 'package:exercise_management/presentation/widgets/average_weekly_statistics_widget.dart';
import 'package:exercise_management/presentation/widgets/exercise_volume_statistic_widget.dart';
import 'package:exercise_management/presentation/widgets/weekly_progress_statistic_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onNavigateToSets;

  const HomePage({super.key, this.onNavigateToSets});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCallToAction(context),
          const SizedBox(height: 24),
          Consumer<ExerciseProgramsViewModel>(
              builder: (context, viewModel, child) {
            final activeProgram = viewModel.activeProgram;
            if (activeProgram == null) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(context, 'Active Program'),
                const SizedBox(height: 8),
                _buildStatCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activeProgram.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (activeProgram.description != null)
                        Text(activeProgram.description!),
                      const SizedBox(height: 8),
                      Text('${activeProgram.sessions.length} sessions',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),
          _buildSectionTitle(context, 'Weekly Progress'),
          const SizedBox(height: 8),
          _buildStatCard(
            child: const WeeklyProgressStatisticWidget(),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Average Weekly Stats'),
          const SizedBox(height: 8),
          _buildStatCard(
            child: const SizedBox(
              height: 200,
              child: AverageWeeklyStatisticsWidget(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Exercise Volume'),
          const SizedBox(height: 8),
          _buildStatCard(
            child: const SizedBox(
              height: 300,
              child: ExerciseVolumeStatisticWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallToAction(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onNavigateToSets,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.fitness_center, size: 28),
        label: const Text(
          'EXERCISE NOW',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }

  Widget _buildStatCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
