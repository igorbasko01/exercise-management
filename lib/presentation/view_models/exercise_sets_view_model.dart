import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/presentation/models/exercise_set_presentation.dart';
import 'package:exercise_management/presentation/models/exercise_set_presentation_mapper.dart';
import 'package:flutter/material.dart';

class ExerciseSetsViewModel extends ChangeNotifier {
  ExerciseSetsViewModel({required ExerciseSetRepository exerciseSetRepository, required ExerciseTemplateRepository exerciseTemplateRepository})
      : _exerciseSetRepository = exerciseSetRepository,
        _exerciseTemplateRepository = exerciseTemplateRepository {
    fetchExerciseSets = Command0(_fetchExerciseSets);
  }

  final ExerciseSetRepository _exerciseSetRepository;
  final ExerciseTemplateRepository _exerciseTemplateRepository;

  late final Command0 fetchExerciseSets;

  Future<Result<List<ExerciseSetPresentation>>> _fetchExerciseSets() async {
    final List<ExerciseSetPresentation> exerciseSetsPresentation = [];
    final result = await _exerciseSetRepository.getExercises();
    // for each exercise set, fetch the exercise template
    switch (result) {
      case Ok<List<ExerciseSet>>():
        for (var exerciseSet in result.value) {
          final exerciseTemplateResult = await _exerciseTemplateRepository.getExercise(exerciseSet.exerciseTemplateId);
          switch (exerciseTemplateResult) {
            case Ok<ExerciseTemplate>():
              final exerciseSetPresentation = ExerciseSetPresentationMapper.from(exerciseSet, exerciseTemplateResult.value);
              exerciseSetsPresentation.add(exerciseSetPresentation);
              break;
            case Error():
              return Result.error(exerciseTemplateResult.error);
          }
        }
        break;
      case Error():
        return Result.error(result.error);
    }
    return Result.ok(exerciseSetsPresentation);
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