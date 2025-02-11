import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/exercise_repository.dart';

class ExerciseTemplateService {
  final ExerciseTemplateRepository _exerciseTemplateRepository;

  ExerciseTemplateService(this._exerciseTemplateRepository);

  Future<Result<ExerciseTemplate>> addExerciseTemplate(ExerciseTemplate exercise) async {
    return _exerciseTemplateRepository.addExercise(exercise.copyWithoutId());
  }

  Future<Result<List<ExerciseTemplate>>> getExerciseTemplates() async {
    return _exerciseTemplateRepository.getExercises();
  }

  Future<Result<ExerciseTemplate>> getExerciseTemplateById(String id) async {
    return _exerciseTemplateRepository.getExercise(id);
  }
}