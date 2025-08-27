import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_set_presentation_mapper.dart';
import 'package:exercise_management/presentation/pages/add_exercise_set_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:exercise_management/presentation/view_models/training_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExerciseSetsPage extends StatelessWidget {
  const ExerciseSetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _exerciseSetsList(),
        Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () async {
                final viewModel = context.read<ExerciseSetsViewModel>();

                await viewModel.fetchExerciseTemplates.execute();

                if (viewModel.exerciseTemplates.isEmpty && context.mounted) {
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
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final exercises = groupedExercises[date]!;
        return _buildExpansionTile(context, date, exercises, viewModel);
      },
    );
  }

  ExpansionTile _buildExpansionTile(
      BuildContext context,
      String date,
      List<ExerciseSetPresentation> exercises,
      ExerciseSetsViewModel viewModel) {
    return ExpansionTile(
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(_buildExerciseGroupSubtitle(exercises)),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        onPressed: () => _duplicateExerciseSets(exercises, viewModel),
      ),
      children: exercises
          .map<Widget>((exercise) =>
              _buildExerciseListTile(context, exercise, viewModel))
          .toList(),
    );
  }

  String _buildExerciseGroupSubtitle(List<ExerciseSetPresentation> exercises) {
    final exerciseNames = exercises.map((e) => e.displayName).toSet().toList();
    return '${exercises.length} set${exercises.length != 1 ? 's' : ''}, '
        '$exerciseNames';
  }

  Widget _buildExerciseListTile(BuildContext context,
      ExerciseSetPresentation exercise, ExerciseSetsViewModel viewModel) {
    return Consumer<TrainingSessionManager>(
        builder: (context, trainingManager, child) {
      final setId = exercise.setId;
      final isCompleted = setId != null
          ? trainingManager.isSetCompleted(exercise.setId!)
          : false;
      return ListTile(
        tileColor: isCompleted ? Colors.green.withValues(alpha: 0.2) : null,
        title: Text(exercise.displayName),
        subtitle: Text(_buildExerciseSubtitle(exercise)),
        onTap: () => _navigateToEditExerciseSet(context, exercise),
        onLongPress: () => setId != null
            ? trainingManager.toggleSetCompletion(exercise.setId!)
            : null,
        trailing: _buildActionButtons(exercise, viewModel),
      );
    });
  }

  String _buildExerciseSubtitle(ExerciseSetPresentation exercise) {
    return 'Reps: ${exercise.repetitions} (${exercise.repetitionsRange.range.toString()}), '
        'Plates Weight: ${exercise.platesWeight}, '
        'Load: ${(exercise.equipmentWeight + exercise.platesWeight) * exercise.repetitions}';
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
        .copyWithoutId(dateTime: DateTime.now());
    viewModel.addExerciseSet.execute(duplicatedSet);
  }

  void _duplicateExerciseSets(List<ExerciseSetPresentation> exercises,
      ExerciseSetsViewModel viewModel) {
    final duplicatedSets = exercises
        .map((exercise) => ExerciseSetPresentationMapper.toExerciseSet(exercise)
            .copyWithoutId(dateTime: DateTime.now()))
        .toList();
    viewModel.addExerciseSets.execute(duplicatedSets);
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}'
        '-${dateTime.month.toString().padLeft(2, '0')}'
        '-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
