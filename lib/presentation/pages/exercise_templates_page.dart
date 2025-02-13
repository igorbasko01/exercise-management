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
      if (viewModel.isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (viewModel.errorMessage != null) {
        return Center(
          child: Text(viewModel.errorMessage!),
        );
      }

      if (viewModel.exerciseTemplates.isEmpty) {
        return const Center(
          child: Text('No exercises found'),
        );
      }

      return ListView.builder(
          itemCount: viewModel.exerciseTemplates.length,
          itemBuilder: (context, index) {
            final exercise = viewModel.exerciseTemplates[index];
            return ListTile(
              title: Text(exercise.name),
              subtitle: Text(exercise.description ??
                  'Main muscle group: ${exercise.muscleGroup}'),
            );
          });
    });
  }
}
