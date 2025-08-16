import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:flutter/material.dart';

class AddExerciseSetPage extends StatefulWidget {
  final ExerciseSetPresentation? exerciseSet;

  const AddExerciseSetPage({super.key, this.exerciseSet});

  @override
  State<AddExerciseSetPage> createState() => _AddExerciseSetPageState();
}

class _AddExerciseSetPageState extends State<AddExerciseSetPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
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
        child: Column(
            children: [
              ElevatedButton(
                  onPressed: _saveExerciseSet, child: const Text('Save')),
            ]
        )
    );
  }
}