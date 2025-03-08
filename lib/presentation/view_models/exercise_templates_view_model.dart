import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:flutter/material.dart';

class ExerciseTemplatesViewModel extends ChangeNotifier {
  ExerciseTemplatesViewModel(
      {required ExerciseTemplateRepository exerciseTemplateRepository})
      : _exerciseTemplateRepository = exerciseTemplateRepository {
    fetchExerciseTemplates = Command0(_fetchExerciseTemplates);
    addExerciseTemplateCommand = Command1(_addExerciseTemplate);
    deleteExerciseTemplateCommand = Command1(_deleteExerciseTemplate);
    updateExerciseTemplateCommand = Command1(_updateExerciseTemplate);
  }

  final ExerciseTemplateRepository _exerciseTemplateRepository;

  late final Command0 fetchExerciseTemplates;
  late final Command1<ExerciseTemplate, ExerciseTemplate>
      addExerciseTemplateCommand;
  late final Command1<ExerciseTemplate, String> deleteExerciseTemplateCommand;
  late final Command1<ExerciseTemplate, ExerciseTemplate>
      updateExerciseTemplateCommand;

  Future<Result<void>> _fetchExerciseTemplates() async {
    return await _exerciseTemplateRepository.getExercises();
  }

  Future<Result<ExerciseTemplate>> _addExerciseTemplate(
      ExerciseTemplate exerciseTemplate) async {
    return await _exerciseTemplateRepository.addExercise(exerciseTemplate);
  }

  Future<Result<ExerciseTemplate>> _deleteExerciseTemplate(String id) async {
    final result = await _exerciseTemplateRepository.deleteExercise(id);
    notifyListeners();
    return result;
  }

  Future<Result<ExerciseTemplate>> _updateExerciseTemplate(
      ExerciseTemplate exerciseTemplate) async {
    return await _exerciseTemplateRepository.updateExercise(exerciseTemplate);
  }
}
