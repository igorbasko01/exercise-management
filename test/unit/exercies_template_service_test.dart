import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_template_repository.dart';
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

  test('getExerciseTemplates should return all exercises from the repository', () async {
    var exercise1 = ExerciseTemplate(
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.high,
      description: 'Lie on a bench and press the barbell away from your chest'
    );

    var exercise2 = ExerciseTemplate(
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
      description: 'Stand with a barbell on your shoulders and squat down'
    );

    await exerciseTemplateService.addExerciseTemplate(exercise1);
    await exerciseTemplateService.addExerciseTemplate(exercise2);

    var result = await exerciseTemplateService.getExerciseTemplates();

    expect(result.isSuccess, true);
    expect(result.data?.length, 2);
    expect(result.data?[0].name, exercise1.name);
    expect(result.data?[1].name, exercise2.name);
  });

  test('getExerciseTemplates should return empty list if no exercises are added', () async {
    var result = await exerciseTemplateService.getExerciseTemplates();

    expect(result.isSuccess, true);
    expect(result.data?.length, 0);
  });

  test('getExerciseTemplateById should return the exercise with the given id', () async {
    var exercise1 = ExerciseTemplate(
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.high,
      description: 'Lie on a bench and press the barbell away from your chest'
    );

    var exercise2 = ExerciseTemplate(
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
      description: 'Stand with a barbell on your shoulders and squat down'
    );

    var addedExercise1 = await exerciseTemplateService.addExerciseTemplate(exercise1);
    await exerciseTemplateService.addExerciseTemplate(exercise2);

    var result = await exerciseTemplateService.getExerciseTemplateById(addedExercise1.data?.id ?? '');

    expect(result.isSuccess, true);
    expect(result.data?.name, exercise1.name);
  });

  test('getExerciseTemplateById should return failure if no exercise with the given id is found', () async {
    var result = await exerciseTemplateService.getExerciseTemplateById('1');

    expect(result.isFailure, true);
    expect(result.error, isA<ExerciseNotFoundException>());
  });
}