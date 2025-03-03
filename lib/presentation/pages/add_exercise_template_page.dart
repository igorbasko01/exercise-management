import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/presentation/view_models/exercise_templates_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddExerciseTemplatePage extends StatefulWidget {
  final ExerciseTemplate? exerciseTemplate;

  const AddExerciseTemplatePage({super.key, this.exerciseTemplate});

  @override
  State<AddExerciseTemplatePage> createState() =>
      _AddExerciseTemplatePageState();
}

class _AddExerciseTemplatePageState extends State<AddExerciseTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late MuscleGroup _selectedMuscleGroup;
  late RepetitionsRange _selectedRepetitionsRange;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.exerciseTemplate?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.exerciseTemplate?.description ?? '');
    _selectedMuscleGroup =
        widget.exerciseTemplate?.muscleGroup ?? MuscleGroup.chest;
    _selectedRepetitionsRange =
        widget.exerciseTemplate?.repetitionsRangeTarget ??
            RepetitionsRange.medium;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.exerciseTemplate == null
              ? 'Add Exercise Template'
              : 'Edit Exercise Template')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildForm(),
      ),
    );
  }

  void _saveExerciseTemplate() {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<ExerciseTemplatesViewModel>();
      if (widget.exerciseTemplate == null) {
        viewModel.addExerciseTemplate(
          _nameController.text,
          _selectedMuscleGroup,
          _selectedRepetitionsRange,
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        final exerciseTemplate = ExerciseTemplate(
          id: widget.exerciseTemplate!.id,
          name: _nameController.text,
          muscleGroup: _selectedMuscleGroup,
          repetitionsRangeTarget: _selectedRepetitionsRange,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        viewModel.updateExerciseTemplate(exerciseTemplate);
      }

      Navigator.pop(context);
    }
  }

  Form _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Exercise Name'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter a name' : null,
          ),
          DropdownButtonFormField<MuscleGroup>(
              value: _selectedMuscleGroup,
              decoration: const InputDecoration(labelText: 'Muscle Group'),
              items: MuscleGroup.values.map((muscleGroup) {
                return DropdownMenuItem(
                    value: muscleGroup,
                    child: Text(muscleGroup.name));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedMuscleGroup = newValue as MuscleGroup;
                });
              }),
          DropdownButtonFormField(
              value: _selectedRepetitionsRange,
              decoration: const InputDecoration(labelText: 'Repetitions Range'),
              items: RepetitionsRange.values.map((repetitionsRange) {
                return DropdownMenuItem(
                    value: repetitionsRange,
                    child: Text(repetitionsRange.range.toString()));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedRepetitionsRange = newValue as RepetitionsRange;
                });
              }),
          TextFormField(
            controller: _descriptionController,
            decoration:
                const InputDecoration(labelText: 'Description (optional)'),
          ),
          ElevatedButton(
            onPressed: _saveExerciseTemplate,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
