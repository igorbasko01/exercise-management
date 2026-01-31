import 'dart:io';

import 'package:archive/archive.dart';
import 'package:exercise_management/core/csv_serializer.dart';
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/presentation/view_models/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

class MockExerciseTemplateRepository extends Mock
    implements ExerciseTemplateRepository {}

class MockExerciseSetRepository extends Mock implements ExerciseSetRepository {}

void main() {
  group('SettingsViewModel importDataCommand', () {
    late SettingsViewModel viewModel;
    late MockExerciseTemplateRepository mockTemplateRepository;
    late MockExerciseSetRepository mockSetRepository;
    late Directory tempDir;

    final dummyTemplate = ExerciseTemplate(
        id: 'fallback',
        name: 'fallback',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.low,
        description: '');

    final dummySet = ExerciseSet(
        id: 'fallback',
        exerciseTemplateId: 'fallback',
        dateTime: DateTime.now(),
        equipmentWeight: 0.0,
        platesWeight: 0.0,
        repetitions: 0);

    setUpAll(() {
      registerFallbackValue(dummyTemplate);
      registerFallbackValue(dummySet);
    });

    setUp(() async {
      mockTemplateRepository = MockExerciseTemplateRepository();
      mockSetRepository = MockExerciseSetRepository();
      viewModel = SettingsViewModel(
        templatesRepository: mockTemplateRepository,
        setsRepository: mockSetRepository,
      );
      tempDir = await Directory.systemTemp.createTemp('test_import_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should successfully import valid zip file with templates and sets',
        () async {
      final zipFile = await _createValidZipFile(tempDir);

      when(() => mockTemplateRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockSetRepository.clearAll()).thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.addExercise(any()))
          .thenAnswer((invocation) async {
        return Result.ok(dummyTemplate);
      });
      when(() => mockSetRepository.addExercise(any()))
          .thenAnswer((invocation) async {
        return Result.ok(dummySet);
      });

      await viewModel.importDataCommand.execute(zipFile.path);

      expect(viewModel.importDataCommand.result, isA<Ok<void>>());
      verify(() => mockTemplateRepository.clearAll()).called(1);
      verify(() => mockSetRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.addExercise(any())).called(2);
      verify(() => mockSetRepository.addExercise(any())).called(2);
    });

    test('should return error when zip file does not exist', () async {
      final nonExistentFilePath = path.join(tempDir.path, 'non_existent.zip');

      await viewModel.importDataCommand.execute(nonExistentFilePath);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
    });

    test('should return error when zip file is invalid', () async {
      final invalidZipFile = File(path.join(tempDir.path, 'invalid.zip'));
      await invalidZipFile.writeAsString('This is not a valid zip file');

      await viewModel.importDataCommand.execute(invalidZipFile.path);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
    });

    test('should return error when clearing templates fails', () async {
      final zipFile = await _createValidZipFile(tempDir);

      when(() => mockSetRepository.clearAll()).thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.error(
            ExerciseDatabaseException('Failed to clear templates'));
      });

      await viewModel.importDataCommand.execute(zipFile.path);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verify(() => mockTemplateRepository.clearAll()).called(1);
      verify(() => mockSetRepository.clearAll()).called(1);
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
    });

    test('should return error when clearing sets fails', () async {
      final zipFile = await _createValidZipFile(tempDir);

      when(() => mockTemplateRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockSetRepository.clearAll()).thenAnswer((invocation) async {
        return Result.error(ExerciseDatabaseException('Failed to clear sets'));
      });

      await viewModel.importDataCommand.execute(zipFile.path);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockTemplateRepository.clearAll());
      verify(() => mockSetRepository.clearAll()).called(1);
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
    });

    test('should return error when template has invalid enum value', () async {
      final zipFile = await _createInvalidEnumZipFile(tempDir);

      await viewModel.importDataCommand.execute(zipFile.path);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
    });
  });
}

Future<File> _createValidZipFile(Directory tempDir) async {
  final archive = Archive();

  // Create templates using the same format as SettingsViewModel export
  final templates = [
    ExerciseTemplate(
      id: '1',
      name: 'Push-up',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
      description: 'Basic push-up exercise',
    ),
    ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.medium,
      description: null,
    ),
  ];
  final templatesCSV =
      CsvSerializer.toCSV(templates.map((t) => t.toMap()).toList());
  archive.addFile(ArchiveFile(
      'exercise_templates.csv', templatesCSV.length, templatesCSV.codeUnits));

  // Create sets using the same format as SettingsViewModel export
  final sets = [
    ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: DateTime.parse('2023-01-01T10:00:00.000Z'),
      equipmentWeight: 0.0,
      platesWeight: 20.0,
      repetitions: 10,
      completedAt: null,
    ),
    ExerciseSet(
      id: '2',
      exerciseTemplateId: '2',
      dateTime: DateTime.parse('2023-01-02T11:00:00.000Z'),
      equipmentWeight: 0.0,
      platesWeight: 30.0,
      repetitions: 15,
      completedAt: DateTime.parse('2023-01-02T11:30:00.000Z'),
    ),
  ];
  final setsCSV = CsvSerializer.toCSV(sets.map((s) => s.toMap()).toList());
  archive.addFile(
      ArchiveFile('exercise_sets.csv', setsCSV.length, setsCSV.codeUnits));

  final zipFile = File(path.join(tempDir.path, 'test_data.zip'));
  await zipFile.writeAsBytes(ZipEncoder().encode(archive));
  return zipFile;
}

Future<File> _createInvalidEnumZipFile(Directory tempDir) async {
  final archive = Archive();

  // Create an invalid template with out-of-range enum value
  final templatesCSV =
      'id,name,muscle_group,repetitions_range,description\n1,Push-up,99999,1,Basic push-up exercise';
  archive.addFile(ArchiveFile(
      'exercise_templates.csv', templatesCSV.length, templatesCSV.codeUnits));

  final zipFile = File(path.join(tempDir.path, 'invalid_enum_data.zip'));
  await zipFile.writeAsBytes(ZipEncoder().encode(archive));
  return zipFile;
}
