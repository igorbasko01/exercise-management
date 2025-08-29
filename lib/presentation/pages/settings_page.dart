import 'package:csv/csv.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:exercise_management/presentation/view_models/exercise_templates_view_model.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton.icon(
              onPressed: () => _exportData(context),
              icon: const Icon(Icons.save_alt),
              label: const Text('Export Data')),
          ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.upload),
              label: const Text('Import Data')),
        ]));
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
                content: Row(children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Exporting data...')
                ]),
              ));

      final exerciseTemplatesViewModel =
          context.read<ExerciseTemplatesViewModel>();
      final exerciseSetsViewModel = context.read<ExerciseSetsViewModel>();

      await exerciseTemplatesViewModel.fetchExerciseTemplates.execute();
      await exerciseSetsViewModel.fetchExerciseSets.execute();

      final templates = exerciseTemplatesViewModel.exercises;
      final sets = exerciseSetsViewModel.exerciseSets;

      final templatesCSV = _createTemplatesCSV(templates);
      final setsCSV = _createSetsCSV(sets);

      final tempDir = await getTemporaryDirectory();
    } catch (e) {
      if (context.mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        _showErrorDialog(context, 'Failed to export data: $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Error'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  )
                ]));
  }

  String _createTemplatesCSV(List<ExerciseTemplate> templates) {
    final rows = <List<String>>[];

    rows.add(
        ['id', 'name', 'muscle_group', 'repetitions_range', 'description']);

    for (final template in templates) {
      rows.add([
        template.id ?? '',
        template.name,
        template.description ?? '',
        template.muscleGroup.index.toString(),
        template.repetitionsRangeTarget.index.toString()
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _createSetsCSV(List<ExerciseSetPresentation> sets) {
    final rows = <List<String>>[];

    rows.add([
      'id',
      'exercise_template_id',
      'date_time',
      'equipment_weight',
      'plates_weight',
      'repetitions'
    ]);

    for (final set in sets) {
      rows.add([
        set.setId ?? '',
        set.exerciseTemplateId,
        set.dateTime.toIso8601String(),
        set.equipmentWeight.toString(),
        set.platesWeight.toString(),
        set.repetitions.toString(),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}
