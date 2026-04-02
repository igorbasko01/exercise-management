import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:exercise_management/presentation/view_models/program_progression_view_model.dart';
import 'package:exercise_management/presentation/widgets/active_program_widget.dart';
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
          const ActiveProgramWidget(),
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
        onPressed: () async {
          final progressionViewModel = context.read<ProgramProgressionViewModel>();
          final setsViewModel = context.read<ExerciseSetsViewModel>();
          
          if (progressionViewModel.activeProgram != null && progressionViewModel.nextSession != null) {
            final historicalSets = await progressionViewModel.getLatestSetsForNextSession();
            final now = DateTime.now();
            
            if (historicalSets != null && historicalSets.isNotEmpty) {
              await setsViewModel.progressSets.execute(historicalSets, now, progressionViewModel.activeProgram!.progressionType);
            } else {
              // Creating 4 sets per template with 0 weight, using min reps
              final newSets = <ExerciseSet>[];
              for (var template in progressionViewModel.nextSession!.exercises) {
                final templateId = template.id;
                if (templateId == null) continue;
                for (int i = 0; i < 4; i++) {
                   newSets.add(ExerciseSet(
                     exerciseTemplateId: templateId,
                     dateTime: now,
                     equipmentWeight: 0,
                     platesWeight: 0,
                     repetitions: template.repetitionsRangeTarget.range.min,
                   ));
                }
              }
              await setsViewModel.addExerciseSets.execute(newSets);
            }
          }
          
          if (onNavigateToSets != null) {
            onNavigateToSets!();
          }
        },
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
