import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/presentation/view_models/exercise_templates_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExerciseTemplatesPage extends StatelessWidget {
  const ExerciseTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _exerciseTemplatesList(),
        Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            )
        )
      ],
    );
  }

  Consumer<ExerciseTemplatesViewModel> _exerciseTemplatesList() {
    return Consumer<ExerciseTemplatesViewModel>(
        builder: (context, viewModel, child) {
      if (viewModel.fetchExerciseTemplates.running) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (viewModel.fetchExerciseTemplates.error) {
        return Center(
          child: Text((viewModel.fetchExerciseTemplates.result as Error).toString()),
        );
      }

      if (viewModel.fetchExerciseTemplates.completed
          && (viewModel.fetchExerciseTemplates.result as Ok<List<ExerciseTemplate>>).value.isEmpty) {
        return const Center(
          child: Text('No exercises found'),
        );
      }

      var exercises = (viewModel.fetchExerciseTemplates.result as Ok<List<ExerciseTemplate>>).value;
      return ListView.builder(
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return ListTile(
              title: Text(exercise.name),
              subtitle: Text(exercise.description ??
                  'Main muscle group: ${exercise.muscleGroup}'),
            );
          });
    });
  }
}
