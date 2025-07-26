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

  List<ExerciseTemplate> _exercises = [];

  List<ExerciseTemplate> get exercises => _exercises;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<void>> _fetchExerciseTemplates() async {
    final result = await _exerciseTemplateRepository.getExercises();
    switch (result) {
      case Ok<List<ExerciseTemplate>>():
        _exercises = result.value;
        return Result.ok(null);
      case Error():
        return Result.error(result.error);
    }
  }

  Future<Result<ExerciseTemplate>> _addExerciseTemplate(
      ExerciseTemplate exerciseTemplate) async {
    final addResult = await _exerciseTemplateRepository.addExercise(exerciseTemplate);
    switch (addResult) {
      case Ok<ExerciseTemplate>():
        await _fetchExerciseTemplates();
        return Result.ok(addResult.value);
      case Error():
        return Result.error(addResult.error);
    }
  }

  Future<Result<ExerciseTemplate>> _deleteExerciseTemplate(String id) async {
    final deleteResult = await _exerciseTemplateRepository.deleteExercise(id);
    switch (deleteResult) {
      case Ok<ExerciseTemplate>():
        await _fetchExerciseTemplates();
        return Result.ok(deleteResult.value);
      case Error():
        return Result.error(deleteResult.error);
    }
  }

  Future<Result<ExerciseTemplate>> _updateExerciseTemplate(
      ExerciseTemplate exerciseTemplate) async {
    final updateResult = await _exerciseTemplateRepository.updateExercise(exerciseTemplate);
    switch (updateResult) {
      case Ok<ExerciseTemplate>():
        await _fetchExerciseTemplates();
        return Result.ok(updateResult.value);
      case Error():
        return Result.error(updateResult.error);
    }
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
