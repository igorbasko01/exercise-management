import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/logger.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/presentation/models/exercise_set_presentation.dart';
import 'package:exercise_management/presentation/models/exercise_set_presentation_mapper.dart';
import 'package:flutter/material.dart';

class ExerciseSetsViewModel extends ChangeNotifier {
  ExerciseSetsViewModel(
      {required ExerciseSetRepository exerciseSetRepository,
      required ExerciseTemplateRepository exerciseTemplateRepository})
      : _exerciseSetRepository = exerciseSetRepository,
        _exerciseTemplateRepository = exerciseTemplateRepository {
    fetchExerciseSets =
        Command0<List<ExerciseSetPresentation>>(_fetchExerciseSets);
    addExerciseSet = Command1<ExerciseSet, ExerciseSet>(_addExerciseSet);
    deleteExerciseSet = Command1<ExerciseSet, String>(_deleteExerciseSet);
    updateExerciseSet = Command1<ExerciseSet, ExerciseSet>(_updateExerciseSet);
  }

  final ExerciseSetRepository _exerciseSetRepository;
  final ExerciseTemplateRepository _exerciseTemplateRepository;

  late final Command0<List<ExerciseSetPresentation>> fetchExerciseSets;
  late final Command1<ExerciseSet, ExerciseSet> addExerciseSet;
  late final Command1<ExerciseSet, String> deleteExerciseSet;
  late final Command1<ExerciseSet, ExerciseSet> updateExerciseSet;

  Future<Result<List<ExerciseSetPresentation>>> _fetchExerciseSets() async {
    final result = await _exerciseSetRepository.getExercises();

    switch (result) {
      case Ok<List<ExerciseSet>>():
        final exerciseSetsPresentation = await _processExerciseSets(result);
        return Result.ok(exerciseSetsPresentation);
      case Error():
        return Result.error(result.error);
    }
  }

  Future<List<ExerciseSetPresentation>> _processExerciseSets(
      Ok<List<ExerciseSet>> result) async {
    final List<ExerciseSetPresentation> exerciseSetsPresentation = [];
    // for each exercise set, fetch the exercise template
    for (var exerciseSet in result.value) {
      final exerciseTemplateResult = await _exerciseTemplateRepository
          .getExercise(exerciseSet.exerciseTemplateId);

      switch (exerciseTemplateResult) {
        case Ok<ExerciseTemplate>():
          final exerciseSetPresentation = ExerciseSetPresentationMapper.from(
              exerciseSet, exerciseTemplateResult.value);
          exerciseSetsPresentation.add(exerciseSetPresentation);
          break;
        case Error():
          logger.e(
              'Error fetching exercise template id: ${exerciseSet.exerciseTemplateId}');
          break;
      }
    }

    return exerciseSetsPresentation;
  }

  Future<Result<ExerciseSet>> _addExerciseSet(ExerciseSet exerciseSet) async {
    return await _exerciseSetRepository.addExercise(exerciseSet);
  }

  Future<Result<ExerciseSet>> _deleteExerciseSet(String id) async {
    return await _exerciseSetRepository.deleteExercise(id);
  }

  Future<Result<ExerciseSet>> _updateExerciseSet(
      ExerciseSet exerciseSet) async {
    return await _exerciseSetRepository.updateExercise(exerciseSet);
  }
}
