import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/exercise_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_repository.dart';
import 'package:exercise_management/service/exercise_template_service.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  late ExerciseTemplateRepository exerciseRepository;
  late ExerciseTemplateService exerciseTemplateService;

  setUp(() {
    exerciseRepository = InMemoryExerciseRepository();
    exerciseTemplateService = ExerciseTemplateService(exerciseRepository);
  });

  test('addExerciseTemplate add exercise to the repository', () async {
    var exercise = ExerciseTemplate(
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.high,
      description: 'Lie on a bench and press the barbell away from your chest'
    );

    var result = await exerciseTemplateService.addExerciseTemplate(exercise);

    expect(result.isSuccess, true);
    expect(result.data?.name, exercise.name);
    expect(result.data?.muscleGroup, exercise.muscleGroup);
    expect(result.data?.repetitionsRangeTarget, exercise.repetitionsRangeTarget);
    expect(result.data?.description, exercise.description);
  });

  test('addExerciseTemplate should ignore id and pass without id to the repository', () async {
    var exercise = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.high,
      description: 'Lie on a bench and press the barbell away from your chest'
    );

    var result = await exerciseTemplateService.addExerciseTemplate(exercise);

    expect(result.isSuccess, true);
    expect(result.data?.id, isNotNull);
    expect(result.data?.id, isNot('1'));
  });
}