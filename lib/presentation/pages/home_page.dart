import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:exercise_management/presentation/view_models/exercise_programs_view_model.dart';
import 'package:exercise_management/presentation/view_models/program_progression_view_model.dart';
import 'package:exercise_management/presentation/widgets/active_program_widget.dart';
import 'package:exercise_management/presentation/widgets/average_weekly_statistics_widget.dart';
import 'package:exercise_management/presentation/widgets/exercise_volume_statistic_widget.dart';
import 'package:exercise_management/presentation/widgets/weekly_progress_statistic_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import 'package:exercise_management/core/services/auth_service.dart';
import 'package:exercise_management/presentation/pages/auth_page.dart';

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
          Consumer<AuthService>(
            builder: (context, auth, _) {
              if (auth.currentUser == null) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Not logged in', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text('Sign in to sync your data across devices.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
                          },
                          child: const Text('Login / Register'),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Card(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Logged in as ${auth.currentUser?.email}', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            auth.signOut();
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
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
          const AverageWeeklyStatisticsWidget(),
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
    final programsViewModel = context.watch<ExerciseProgramsViewModel>();
    final progressionViewModel = context.watch<ProgramProgressionViewModel>();
    final programs = programsViewModel.programs;

    String? currentDropdownValue = progressionViewModel.selectedProgramId ?? programsViewModel.activeProgram?.id;
    if (currentDropdownValue != null && !programs.any((p) => p.id == currentDropdownValue)) {
      currentDropdownValue = null;
    }

    Widget actionButton = SizedBox(
      height: 60,
      width: double.infinity,
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

    if (programs.length <= 1) {
      return actionButton;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Select Program',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: currentDropdownValue,
              items: programs.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Text(p.name + (p.isActive ? ' (Active)' : '')),
                );
              }).toList(),
              onChanged: (value) {
                context.read<ProgramProgressionViewModel>().selectProgram(value);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        actionButton,
      ],
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
