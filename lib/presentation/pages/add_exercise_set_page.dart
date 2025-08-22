import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddExerciseSetPage extends StatefulWidget {
  final ExerciseSetPresentation? exerciseSet;

  const AddExerciseSetPage({super.key, this.exerciseSet});

  @override
  State<AddExerciseSetPage> createState() => _AddExerciseSetPageState();
}

class _AddExerciseSetPageState extends State<AddExerciseSetPage> {
  final _formKey = GlobalKey<FormState>();
  late ExerciseTemplate? _selectedExerciseTemplate;

  late ExerciseSetsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ExerciseSetsViewModel>();
    _selectedExerciseTemplate = _viewModel.exerciseTemplates.isNotEmpty
        ? _viewModel.exerciseTemplates.first
        : null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseSet == null
            ? 'Add Exercise Set'
            : 'Edit Exercise Set'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildForm(),
      ),
    );
  }

  void _saveExerciseSet() {
    Navigator.pop(context);
  }

  Form _buildForm() {
    return Form(
        key: _formKey,
        child: Column(children: [
          DropdownButtonFormField(
              value: _selectedExerciseTemplate,
              decoration: const InputDecoration(labelText: 'Exercise Template'),
              items: _viewModel.exerciseTemplates
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedExerciseTemplate = value;
                  });
                }
              }),
          ElevatedButton(
              onPressed: _saveExerciseSet, child: const Text('Save')),
        ]));
  }
}
