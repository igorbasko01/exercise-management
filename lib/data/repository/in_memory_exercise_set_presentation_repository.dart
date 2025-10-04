import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_set_presentation_mapper.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_repository.dart';

class InMemoryExerciseSetPresentationRepository
    extends ExerciseSetPresentationRepository {
  final InMemoryExerciseSetRepository _exerciseSetRepository;
  final ExerciseTemplateRepository _exerciseTemplateRepository;

  InMemoryExerciseSetPresentationRepository(
      {required InMemoryExerciseSetRepository exerciseSetRepository,
      required ExerciseTemplateRepository exerciseTemplateRepository})
      : _exerciseSetRepository = exerciseSetRepository,
        _exerciseTemplateRepository = exerciseTemplateRepository;

  @override
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSets({int lastNDays = 7}) async {
    final result = await _exerciseSetRepository.getExercises();

    switch (result) {
      case Ok<List<ExerciseSet>>():
        final now = DateTime.now();
        final startDate = now.subtract(Duration(days: lastNDays));
        
        // Filter exercise sets by date
        final filteredSets = result.value.where((set) {
          return set.dateTime.isAfter(startDate) || 
                 set.dateTime.isAtSameMomentAs(startDate);
        }).toList();
        
        final exerciseSetsPresentation =
            await _processExerciseSets(filteredSets);
        return Result.ok(exerciseSetsPresentation);
      case Error():
        return Result.error(result.error);
    }
  }

  @override
  Future<Result<ExerciseSetPresentation>> getExerciseSet(String setId) async {
    final result = await _exerciseSetRepository.getExercise(setId);

    switch (result) {
      case Ok<ExerciseSet>():
        final exercisePresentation = await _processExerciseSets([result.value]);
        if (exercisePresentation.isNotEmpty) {
          return Result.ok(exercisePresentation.first);
        } else {
          return Result.error(ExerciseNotFoundException(
              'Exercise template for exercise set $setId not found'));
        }
      case Error():
        return Result.error(result.error);
    }
  }

  Future<List<ExerciseSetPresentation>> _processExerciseSets(
      List<ExerciseSet> exerciseSets) async {
    final List<ExerciseSetPresentation> exerciseSetsPresentation = [];
    // for each exercise set, fetch the exercise template
    for (var exerciseSet in exerciseSets) {
      final exerciseTemplateResult = await _exerciseTemplateRepository
          .getExercise(exerciseSet.exerciseTemplateId);

      switch (exerciseTemplateResult) {
        case Ok<ExerciseTemplate>():
          final exerciseSetPresentation = ExerciseSetPresentationMapper.from(
              exerciseSet, exerciseTemplateResult.value);
          exerciseSetsPresentation.add(exerciseSetPresentation);
          break;
        case Error():
          continue;
      }
    }

    return exerciseSetsPresentation;
  }
}
