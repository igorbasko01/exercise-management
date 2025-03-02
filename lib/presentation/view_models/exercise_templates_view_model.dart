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
  }

  final ExerciseTemplateRepository _exerciseTemplateRepository;

  late final Command0 fetchExerciseTemplates;

  Future<Result<void>> _fetchExerciseTemplates() async {
    final result = await _exerciseTemplateRepository.getExercises();
    notifyListeners();
    return result;
  }

  Future<Result<ExerciseTemplate>> addExerciseTemplate(
      String name,
      MuscleGroup muscleGroup,
      RepetitionsRange repetitionsRangeTarget,
      String? description) async {
    final exerciseTemplate = ExerciseTemplate(
        name: name,
        muscleGroup: muscleGroup,
        repetitionsRangeTarget: repetitionsRangeTarget,
        description: description);
    final result = await _exerciseTemplateRepository.addExercise(exerciseTemplate);
    notifyListeners();
    return result;
  }
}
