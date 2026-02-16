import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/presentation/pages/exercise_picker_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_programs_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddExerciseProgramPage extends StatefulWidget {
  final ExerciseProgram? program;

  const AddExerciseProgramPage({super.key, this.program});

  @override
  State<AddExerciseProgramPage> createState() => _AddExerciseProgramPageState();
}

class _AddExerciseProgramPageState extends State<AddExerciseProgramPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late List<ExerciseProgramSession> _sessions;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.program?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.program?.description ?? '');
    _sessions = widget.program?.sessions.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveProgram() async {
    if (_formKey.currentState!.validate()) {
      final newProgram = ExerciseProgram(
        id: widget.program?.id,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        sessions: _sessions,
        isActive: widget.program?.isActive ?? false,
      );

      final viewModel = context.read<ExerciseProgramsViewModel>();
      if (widget.program == null) {
        await viewModel.addProgram.execute(newProgram);
        if (viewModel.addProgram.completed && mounted) {
          Navigator.pop(context);
        } else if (viewModel.addProgram.error && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Error adding program: ${(viewModel.addProgram.result as Error).error}')));
        }
      } else {
        await viewModel.updateProgram.execute(newProgram);
        if (viewModel.updateProgram.completed && mounted) {
          Navigator.pop(context);
        } else if (viewModel.updateProgram.error && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Error updating program: ${(viewModel.updateProgram.result as Error).error}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program == null ? 'New Program' : 'Edit Program'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProgram,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Program Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sessions', style: Theme.of(context).textTheme.titleLarge),
                IconButton(icon: const Icon(Icons.add), onPressed: _addSession),
              ],
            ),
            if (_sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No sessions added')),
              ),
            ..._sessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              return Card(
                key: ValueKey(session.id ?? index),
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title:
                      Text(session.name.isEmpty ? 'New Session' : session.name),
                  children: [
                    Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                initialValue: session.name,
                                decoration: const InputDecoration(
                                    labelText: 'Session Name'),
                                onChanged: (val) =>
                                    _updateSessionName(index, val),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: session.description,
                                decoration: const InputDecoration(
                                    labelText: 'Description'),
                                onChanged: (val) =>
                                    _updateSessionDescription(index, val),
                              ),
                              const SizedBox(height: 16),
                              Text('Exercises',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              if (session.exercises.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('No exercises in this session'),
                                ),
                              ...session.exercises.asMap().entries.map((eEntry) {
                                final eIndex = eEntry.key;
                                final exercise = eEntry.value;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(exercise.name),
                                  subtitle: Text(exercise.muscleGroup.name),
                                  trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          _removeExerciseFromSession(
                                              index, eIndex)),
                                );
                              }),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                  onPressed: () => _addExerciseToSession(index),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Exercise')),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => _removeSession(index),
                                child: const Text('Remove Session',
                                    style: TextStyle(color: Colors.red)),
                              )
                            ]))
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _addSession() {
    setState(() {
      _sessions
          .add(ExerciseProgramSession(name: 'Session ${_sessions.length + 1}'));
    });
  }

  void _updateSessionName(int index, String name) {
    setState(() {
      _sessions[index] = _sessions[index].copyWith(name: name);
    });
  }

  void _updateSessionDescription(int index, String description) {
    setState(() {
      // Assuming description cannot be cleared to null via copyWith for now
      _sessions[index] = _sessions[index].copyWith(description: description);
    });
  }

  void _addExerciseToSession(int sessionIndex) async {
    final exercise = await Navigator.push<ExerciseTemplate>(context,
        MaterialPageRoute(builder: (_) => const ExercisePickerPage()));

    if (exercise != null) {
      setState(() {
        final currentExercises = _sessions[sessionIndex].exercises.toList();
        currentExercises.add(exercise);
        _sessions[sessionIndex] =
            _sessions[sessionIndex].copyWith(exercises: currentExercises);
      });
    }
  }

  void _removeExerciseFromSession(int sessionIndex, int exerciseIndex) {
    setState(() {
      final currentExercises = _sessions[sessionIndex].exercises.toList();
      currentExercises.removeAt(exerciseIndex);
      _sessions[sessionIndex] =
          _sessions[sessionIndex].copyWith(exercises: currentExercises);
    });
  }

  void _removeSession(int index) {
    setState(() {
      _sessions.removeAt(index);
    });
  }
}
