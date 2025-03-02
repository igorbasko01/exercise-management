import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/presentation/view_models/exercise_templates_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddExerciseTemplatePage extends StatefulWidget {
  const AddExerciseTemplatePage({super.key});

  @override
  State<AddExerciseTemplatePage> createState() =>
      _AddExerciseTemplatePageState();
}

class _AddExerciseTemplatePageState extends State<AddExerciseTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  MuscleGroup _selectedMuscleGroup = MuscleGroup.chest;
  RepetitionsRange _selectedRepetitionsRange = RepetitionsRange.medium;

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(title: const Text('Add Exercise Template')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildForm(),
      ),
    );
  }

  void _saveExerciseTemplate() {
    if (_formKey.currentState!.validate()) {
      final viewModel = context.read<ExerciseTemplatesViewModel>();
      viewModel.addExerciseTemplate(
        _nameController.text,
        _selectedMuscleGroup,
        _selectedRepetitionsRange,
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

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
                    child: Text(muscleGroup.toString().split('.').last));
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
