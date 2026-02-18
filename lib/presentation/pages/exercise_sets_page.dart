import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_set_presentation_mapper.dart';
import 'package:exercise_management/presentation/pages/add_exercise_set_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExerciseSetsPage extends StatelessWidget {
  const ExerciseSetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(context),
        Expanded(
          child: Stack(
            children: [
              _exerciseSetsList(),
              Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final viewModel = context.read<ExerciseSetsViewModel>();

                      await viewModel.fetchExerciseTemplates.execute();

                      if (viewModel.exerciseTemplates.isEmpty &&
                          context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Please add an exercise template before adding an exercise set.')));
                        return;
                      } else if (context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const AddExerciseSetPage()));
                      }
                    },
                    child: const Icon(Icons.add),
                  ))
            ],
          ),
        ),
      ],
    );
  }

  Consumer<ExerciseSetsViewModel> _exerciseSetsList() {
    return Consumer<ExerciseSetsViewModel>(
        builder: (context, viewModel, child) {
      if (viewModel.fetchExerciseSets.running) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (viewModel.fetchExerciseSets.error) {
        return Center(
          child: Text((viewModel.fetchExerciseSets.result as Error).toString()),
        );
      }

      if (viewModel.exerciseSets.isEmpty) {
        return const Center(
          child: Text('No exercise sets found'),
        );
      }

      final groupedExercises = _groupExercisesByDate(viewModel.exerciseSets);
      final sortedDates = _getSortedDates(groupedExercises);

      return _buildGroupedListView(
          context, groupedExercises, sortedDates, viewModel);
    });
  }

  Map<String, List<ExerciseSetPresentation>> _groupExercisesByDate(
      List<ExerciseSetPresentation> exercises) {
    final groupedExercises = <String, List<ExerciseSetPresentation>>{};
    for (final exercise in exercises) {
      final dateKey = _formatDate(exercise.dateTime);
      groupedExercises.putIfAbsent(dateKey, () => []).add(exercise);
    }
    return groupedExercises;
  }

  List<String> _getSortedDates(
      Map<String, List<ExerciseSetPresentation>> groupedExercises) {
    return groupedExercises.keys.toList()..sort((a, b) => b.compareTo(a));
  }

  ListView _buildGroupedListView(
      BuildContext context,
      Map<String, List<ExerciseSetPresentation>> groupedExercises,
      List<String> sortedDates,
      ExerciseSetsViewModel viewModel) {
    return ListView.builder(
      itemCount: sortedDates.length + 1, // +1 for "Load More" button
      itemBuilder: (context, index) {
        // Show "Load More" button as last item
        if (index == sortedDates.length) {
          return _buildLoadMoreButton(viewModel);
        }
        final date = sortedDates[index];
        final exercises = groupedExercises[date]!;
        return _buildDateExpansionTile(context, date, exercises, viewModel);
      },
    );
  }

  Widget _buildLoadMoreButton(ExerciseSetsViewModel viewModel) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
            child: viewModel.fetchMoreExerciseSets.running
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: () => viewModel.fetchMoreExerciseSets.execute(),
                    icon: const Icon(Icons.history),
                    label: const Text('Load More History'))));
  }

  Widget _buildDateExpansionTile(
      BuildContext context,
      String date,
      List<ExerciseSetPresentation> exercises,
      ExerciseSetsViewModel viewModel) {
    final allCompleted = exercises.every((set) => set.completedAt != null);
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.leading,
      collapsedBackgroundColor:
          allCompleted ? Colors.green.withValues(alpha: 0.2) : null,
      backgroundColor:
          allCompleted ? Colors.green.withValues(alpha: 0.2) : null,
      title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(_buildExerciseGroupSubtitle(exercises)),
      trailing: IconButton(
        icon: const Icon(Icons.copy_all),
        onPressed: () => _progressSets(exercises, viewModel),
      ),
      children:
          _buildExerciseTemplateExpansionTiles(exercises, context, viewModel),
    );
  }

  List<Widget> _buildExerciseTemplateExpansionTiles(
      List<ExerciseSetPresentation> exercises,
      BuildContext context,
      ExerciseSetsViewModel viewModel) {
    final setsByTemplate = <String, List<ExerciseSetPresentation>>{};
    for (var exercise in exercises) {
      setsByTemplate
          .putIfAbsent(exercise.exerciseTemplateId, () => [])
          .add(exercise);
    }

    final sortedEntries = setsByTemplate.entries.toList()
      ..sort((a, b) {
        final aLatest = _getLatestCompletionTime(a.value);
        final bLatest = _getLatestCompletionTime(b.value);

        if (aLatest == null && bLatest == null) return 0;
        if (aLatest == null) return 1;
        if (bLatest == null) return -1;
        return aLatest.compareTo(bLatest);
      });

    final widgets = <Widget>[];
    for (var entry in sortedEntries) {
      final templateName = entry.value.first.displayName;
      final date = _formatDate(entry.value.first.dateTime);
      final rank = viewModel.getRank(date, entry.key);

      widgets.add(_buildExerciseTemplateExpansionTile(
          templateName, entry.value, context, viewModel, rank));
    }
    return widgets;
  }

  DateTime? _getLatestCompletionTime(List<ExerciseSetPresentation> sets) {
    return sets
        .map((e) => e.completedAt)
        .where((e) => e != null)
        .fold<DateTime?>(null, (prev, curr) {
      if (prev == null) return curr;
      return curr!.isAfter(prev) ? curr : prev;
    });
  }

  String _buildExerciseGroupSubtitle(List<ExerciseSetPresentation> exercises) {
    final exerciseNames = exercises.map((e) => e.displayName).toSet().toList();
    return '${exercises.length} set${exercises.length != 1 ? 's' : ''}, '
        '$exerciseNames';
  }

  Widget _buildExerciseTemplateExpansionTile(
      String templateName,
      List<ExerciseSetPresentation> exercises,
      BuildContext context,
      ExerciseSetsViewModel viewModel,
      int rank) {
    final allCompleted = exercises.every((set) => set.completedAt != null);
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.leading,
      collapsedBackgroundColor:
          allCompleted ? Colors.green.withValues(alpha: 0.2) : null,
      backgroundColor:
          allCompleted ? Colors.green.withValues(alpha: 0.2) : null,
      title: Text(templateName,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(_buildExerciseTemplateSubtitle(exercises, context)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRankBadge(rank),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: () => _progressSets(exercises, viewModel),
          ),
        ],
      ),
      children: (List<ExerciseSetPresentation>.from(exercises)
            ..sort((a, b) {
              // Nulls at the bottom
              if (a.completedAt == null && b.completedAt == null) return 0;
              if (a.completedAt == null) return 1;
              if (b.completedAt == null) return -1;
              // Ascending order (most recent at bottom, just above nulls)
              return a.completedAt!.compareTo(b.completedAt!);
            }))
          .map<Widget>((exercise) =>
              _buildExerciseListTile(context, exercise, viewModel))
          .toList(),
    );
  }

  String _buildExerciseTemplateSubtitle(
      List<ExerciseSetPresentation> exercises, BuildContext context) {
    final maxPlatesWeight = exercises
        .map((set) => set.platesWeight)
        .fold(0.0, (value, element) => value > element ? value : element);
    final totalVolume = ExerciseSetsViewModel.calculateTotalVolume(exercises);
    return "${exercises.length} set${exercises.length != 1 ? 's' : ''}, "
        "reps: ${exercises.map((set) => set.repetitions)}, "
        "plates weight: $maxPlatesWeight, "
        "total volume: ${totalVolume.toStringAsFixed(1)}";
  }

  /// Build a rank badge widget with color gradient from green (#1) to red (higher ranks)
  Widget _buildRankBadge(int rank) {
    // Calculate color based on rank: green for 1, transitioning to red for higher ranks
    // Using a logarithmic scale to make the transition more gradual
    final normalizedRank = (rank - 1).clamp(0, 10) / 10.0;
    final color = Color.lerp(
      Colors.green.shade700,
      Colors.red.shade700,
      normalizedRank,
    )!;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseListTile(BuildContext context,
      ExerciseSetPresentation exercise, ExerciseSetsViewModel viewModel) {
    final isCompleted = exercise.completedAt != null;
    return ListTile(
      tileColor: isCompleted ? Colors.green.withValues(alpha: 0.2) : null,
      title: Text(exercise.displayName),
      subtitle: Text(_buildExerciseSubtitle(exercise)),
      onTap: () => _navigateToEditExerciseSet(context, exercise),
      onLongPress: () => exercise.setId != null
          ? _toggleSetCompletion(exercise, viewModel)
          : null,
      trailing: _buildActionButtons(exercise, viewModel),
    );
  }

  String _buildExerciseSubtitle(ExerciseSetPresentation exercise) {
    return 'Reps: ${exercise.repetitions} (${exercise.repetitionsRange.range.toString()}), '
        'Plates Weight: ${exercise.platesWeight}, '
        'Volume: ${ExerciseSetsViewModel.calculateTotalVolume([exercise])}';
  }

  void _navigateToEditExerciseSet(
      BuildContext context, ExerciseSetPresentation exercise) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => AddExerciseSetPage(exerciseSet: exercise)));
  }

  Row _buildActionButtons(
      ExerciseSetPresentation exercise, ExerciseSetsViewModel viewModel) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () => _duplicateExerciseSet(exercise, viewModel),
      ),
      IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => viewModel.deleteExerciseSet.execute(exercise.setId!),
      )
    ]);
  }

  void _duplicateExerciseSet(
      ExerciseSetPresentation exercise, ExerciseSetsViewModel viewModel) {
    final duplicatedSet = ExerciseSetPresentationMapper.toExerciseSet(exercise)
        .copyWith(
            id: const Value(null),
            dateTime: DateTime.now(),
            completedAt: const Value(null));
    viewModel.addExerciseSet.execute(duplicatedSet);
  }

  void _toggleSetCompletion(
      ExerciseSetPresentation exercise, ExerciseSetsViewModel viewModel) {
    final isCurrentlyCompleted = exercise.completedAt != null;
    final exerciseSet = exercise.toExerciseSet();

    // Use the new copyWith with Value wrapper to handle nullability explicitly
    final updatedSet = exerciseSet.copyWith(
      completedAt:
          isCurrentlyCompleted ? const Value(null) : Value(DateTime.now()),
    );
    viewModel.updateExerciseSet.execute(updatedSet);
  }

  void _progressSets(
      List<ExerciseSetPresentation> sets, ExerciseSetsViewModel viewModel) {
    viewModel.progressSets.execute(sets, DateTime.now());
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}'
        '-${dateTime.month.toString().padLeft(2, '0')}'
        '-${dateTime.day.toString().padLeft(2, '0')}';
  }

  Widget _buildFilterBar(BuildContext context) {
    return Consumer<ExerciseSetsViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 8),
              const Text('Filter by exercise:'),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: viewModel.selectedExerciseTemplateId,
                  hint: const Text('All exercises'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All exercises'),
                    ),
                    ...viewModel.exerciseTemplates.map((template) {
                      return DropdownMenuItem<String?>(
                        value: template.id,
                        child: Text(template.name),
                      );
                    }),
                  ],
                  onChanged: (String? newValue) {
                    viewModel.setSelectedExerciseTemplateId(newValue);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
