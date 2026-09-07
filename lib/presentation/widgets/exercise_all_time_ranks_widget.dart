import 'package:exercise_management/data/models/exercise_rank_summary.dart';
import 'package:exercise_management/presentation/view_models/home_exercise_ranks_view_model.dart';
import 'package:exercise_management/presentation/view_models/program_progression_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Shows, per exercise of the current program, the all-time rank of its two
/// most recent sessions plus its all-time best session.
class ExerciseAllTimeRanksWidget extends StatefulWidget {
  const ExerciseAllTimeRanksWidget({super.key});

  @override
  State<ExerciseAllTimeRanksWidget> createState() =>
      _ExerciseAllTimeRanksWidgetState();
}

class _ExerciseAllTimeRanksWidgetState
    extends State<ExerciseAllTimeRanksWidget> {
  late final ProgramProgressionViewModel _progressionViewModel;
  String? _loadedProgramId;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _progressionViewModel = context.read<ProgramProgressionViewModel>();
    _progressionViewModel.addListener(_reloadIfProgramChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadIfProgramChanged());
  }

  void _reloadIfProgramChanged() {
    final activeProgram = _progressionViewModel.activeProgram;
    if (_loadedOnce && activeProgram?.id == _loadedProgramId) return;

    _loadedOnce = true;
    _loadedProgramId = activeProgram?.id;
    context.read<HomeExerciseRanksViewModel>().loadRanks.execute(activeProgram);
  }

  @override
  void dispose() {
    _progressionViewModel.removeListener(_reloadIfProgramChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeExerciseRanksViewModel>(
      builder: (context, viewModel, child) {
        final summaries = viewModel.exerciseRankSummaries;
        if (summaries.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(context, 'Personal Records'),
            const SizedBox(height: 8),
            for (final summary in summaries) ...[
              _buildExerciseCard(context, summary),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseRankSummary summary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.exerciseName,
                style: Theme.of(context).textTheme.titleMedium),
            if (summary.recentSessions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('No completed sets yet',
                    style: Theme.of(context).textTheme.bodySmall),
              )
            else ...[
              const SizedBox(height: 8),
              for (final session in summary.recentSessions)
                _buildSessionRow(context, session),
              if (summary.bestSession != null) ...[
                const Divider(height: 20),
                _buildBestRow(context, summary.bestSession!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionRow(BuildContext context, ExerciseSessionSummary session) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_formatDate(session.date),
              style: Theme.of(context).textTheme.bodyMedium),
          Text('${session.totalVolume.round()} kg',
              style: Theme.of(context).textTheme.bodyMedium),
          Text('#${session.rank}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildBestRow(BuildContext context, ExerciseSessionSummary best) {
    return Text(
      'Best: ${best.totalVolume.round()} kg  ·  ${_formatDate(best.date)}  ·  ${best.setsLabel}',
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.secondary),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
}
