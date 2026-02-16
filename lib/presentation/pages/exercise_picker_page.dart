import 'package:exercise_management/presentation/view_models/exercise_templates_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExercisePickerPage extends StatelessWidget {
  const ExercisePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Exercise')),
      body: Consumer<ExerciseTemplatesViewModel>(
          builder: (context, viewModel, child) {
        if (viewModel.fetchExerciseTemplates.running) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.fetchExerciseTemplates.error) {
          return Center(
            child: Text(
                (viewModel.fetchExerciseTemplates.result as Error).toString()),
          );
        }

        if (viewModel.exercises.isEmpty) {
          return const Center(
            child: Text('No exercises found'),
          );
        }

        var exercises = viewModel.exercises;
        return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return ListTile(
                title: Text(exercise.name),
                subtitle: Text(exercise.description ??
                    'Muscle group: ${exercise.muscleGroup.name}'),
                onTap: () {
                  Navigator.of(context).pop(exercise);
                },
              );
            });
      }),
    );
  }
}
