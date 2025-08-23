import 'package:exercise_management/data/models/exercise_set.dart';
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
  late final TextEditingController _equipmentWeightController;
  late final TextEditingController _platesWeightController;
  late final TextEditingController _repetitionsController;

  late ExerciseSetsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<ExerciseSetsViewModel>();
    _selectedExerciseTemplate = _viewModel.exerciseTemplates.isNotEmpty
        ? _viewModel.exerciseTemplates.first
        : null;
    _equipmentWeightController = TextEditingController(
        text: widget.exerciseSet?.equipmentWeight.toString() ?? '0');
    _platesWeightController = TextEditingController(
        text: widget.exerciseSet?.platesWeight.toString() ?? '0');
    _repetitionsController = TextEditingController(
        text: widget.exerciseSet?.repetitions.toString() ?? '0');
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedExerciseTemplate == null || _selectedExerciseTemplate?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an exercise template.')));
      return;
    }
    final exerciseSet = ExerciseSet(
      exerciseTemplateId: _selectedExerciseTemplate!.id!,
      dateTime: DateTime.now(),
      equipmentWeight: double.parse(_equipmentWeightController.text),
      platesWeight: double.parse(_platesWeightController.text),
      repetitions: int.parse(_repetitionsController.text),
    );
    _viewModel.addExerciseSet.execute(exerciseSet);
    Navigator.pop(context);
  }

  Form _buildForm() {
    return Form(
        key: _formKey,
        child: Column(children: [
          DropdownButtonFormField(
              initialValue: _selectedExerciseTemplate,
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
          TextFormField(
            controller: _equipmentWeightController,
            decoration: const InputDecoration(labelText: 'Equipment Weight'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter equipment weight';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) < 0) {
                return 'Please enter a non-negative number';
              }
              return null;
            }
          ),
          TextFormField(
            controller: _platesWeightController,
            decoration: const InputDecoration(labelText: 'Plates Weight'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter plates weight';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) < 0) {
                return 'Please enter a non-negative number';
              }
              return null;
            }
          ),
          TextFormField(
            controller: _repetitionsController,
            decoration: const InputDecoration(labelText: 'Repetitions'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter number of repetitions';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid integer';
              }
              if (int.parse(value) < 0) {
                return 'Please enter a non-negative integer';
              }
              return null;
            }
          ),
          ElevatedButton(
              onPressed: _saveExerciseSet, child: const Text('Save')),
        ]));
  }
}
