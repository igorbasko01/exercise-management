import 'package:exercise_management/presentation/view_models/program_progression_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ActiveProgramWidget extends StatelessWidget {
  const ActiveProgramWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProgressionViewModel>(
        builder: (context, viewModel, child) {
      final activeProgram = viewModel.activeProgram;
      if (activeProgram == null) {
        return const SizedBox.shrink();
      }
      final nextSession = viewModel.nextSession;

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
                if (nextSession != null) ...[
                  const Divider(height: 24),
                  Text('Next Session',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 4),
                  Text(nextSession.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (nextSession.description != null)
                    Text(nextSession.description!),
                  const SizedBox(height: 4),
                  Text('${nextSession.exercises.length} exercises',
                      style: Theme.of(context).textTheme.bodySmall),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
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
