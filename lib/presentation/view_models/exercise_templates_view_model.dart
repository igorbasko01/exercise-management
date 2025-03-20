import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:flutter/material.dart';

class ExerciseTemplatesViewModel extends ChangeNotifier {
  ExerciseTemplatesViewModel(
      {required ExerciseTemplateRepository exerciseTemplateRepository})
      : _exerciseTemplateRepository = exerciseTemplateRepository {
    fetchExerciseTemplates = Command0(_fetchExerciseTemplates)
      ..addListener(_onCommandExecuted);
    addExerciseTemplateCommand = Command1(_addExerciseTemplate)
      ..addListener(_onCommandExecuted);
    deleteExerciseTemplateCommand = Command1(_deleteExerciseTemplate)
      ..addListener(_onCommandExecuted);
    updateExerciseTemplateCommand = Command1(_updateExerciseTemplate)
      ..addListener(_onCommandExecuted);
  }

  final ExerciseTemplateRepository _exerciseTemplateRepository;

  late final Command0 fetchExerciseTemplates;
  late final Command1<ExerciseTemplate, ExerciseTemplate>
      addExerciseTemplateCommand;
  late final Command1<ExerciseTemplate, String> deleteExerciseTemplateCommand;
  late final Command1<ExerciseTemplate, ExerciseTemplate>
      updateExerciseTemplateCommand;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<void>> _fetchExerciseTemplates() async {
    return await _exerciseTemplateRepository.getExercises();
  }

  Future<Result<ExerciseTemplate>> _addExerciseTemplate(
      ExerciseTemplate exerciseTemplate) async {
    return await _exerciseTemplateRepository.addExercise(exerciseTemplate);
  }

  Future<Result<ExerciseTemplate>> _deleteExerciseTemplate(String id) async {
    return await _exerciseTemplateRepository.deleteExercise(id);
  }

  Future<Result<ExerciseTemplate>> _updateExerciseTemplate(
      ExerciseTemplate exerciseTemplate) async {
    return await _exerciseTemplateRepository.updateExercise(exerciseTemplate);
  }

  @override
  void dispose() {
    fetchExerciseTemplates.removeListener(_onCommandExecuted);
    addExerciseTemplateCommand.removeListener(_onCommandExecuted);
    deleteExerciseTemplateCommand.removeListener(_onCommandExecuted);
    updateExerciseTemplateCommand.removeListener(_onCommandExecuted);

    fetchExerciseTemplates.dispose();
    addExerciseTemplateCommand.dispose();
    deleteExerciseTemplateCommand.dispose();
    updateExerciseTemplateCommand.dispose();
    super.dispose();
  }
}
