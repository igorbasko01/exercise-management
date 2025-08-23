import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/presentation/pages/add_exercise_set_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
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

      var exercises = viewModel.exerciseSets;
      return ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return ListTile(
                title: Text(exercise.displayName),
                subtitle: Text('${_formatDate(exercise.dateTime)}, '
                    'Reps: ${exercise.repetitions}, '
                    'Plates Weight: ${exercise.platesWeight}, '
                    'Load: ${(exercise.equipmentWeight + exercise.platesWeight) * exercise.repetitions}'),
                onTap: () {},
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    viewModel.deleteExerciseSet.execute(exercise.setId!);
                  },
                ));
          });
    });
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}'
        '-${dateTime.month.toString().padLeft(2, '0')}'
        '-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
