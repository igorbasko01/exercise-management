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
  }

  final ExerciseSetRepository _exerciseSetRepository;
  final ExerciseTemplateRepository _exerciseTemplateRepository;

  late final Command0<List<ExerciseSetPresentation>> fetchExerciseSets;

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

  Future<Result<ExerciseSet>> addExerciseSet(ExerciseSet exerciseSet) async {
    final result = await _exerciseSetRepository.addExercise(exerciseSet);
    notifyListeners();
    return result;
  }

  Future<Result<ExerciseSet>> deleteExerciseSet(String id) async {
    final result = await _exerciseSetRepository.deleteExercise(id);
    notifyListeners();
    return result;
  }

  Future<Result<ExerciseSet>> updateExerciseSet(ExerciseSet exerciseSet) async {
    final result = await _exerciseSetRepository.updateExercise(exerciseSet);
    notifyListeners();
    return result;
  }
}
