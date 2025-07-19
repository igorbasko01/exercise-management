import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
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
              onPressed: () {},
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

      if (viewModel.fetchExerciseSets.completed &&
          (viewModel.fetchExerciseSets.result
                  as Ok<List<ExerciseSetPresentation>>)
              .value
              .isEmpty) {
        return const Center(
          child: Text('No exercises found'),
        );
      }

      var exercises = (viewModel.fetchExerciseSets.result
              as Ok<List<ExerciseSetPresentation>>)
          .value;
      return ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return ListTile(
              title: Text(exercise.displayName),
              subtitle: Text('Repetitions done: ${exercise.repetitions}, '
                  'Plates Weight: ${exercise.platesWeight}'),
              onTap: () {},
            );
          });
    });
  }
}
