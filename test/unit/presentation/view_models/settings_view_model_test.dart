import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
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
        return Result.error(
            ExerciseDatabaseException('Failed to clear sets'));
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

  final templatesRows = [
    ['id', 'name', 'muscle_group', 'repetitions_range', 'description'],
    ['1', 'Push-up', '2', '1', 'Basic push-up exercise'],
    ['2', 'Squat', '0', '1', ''],
  ];
  final templatesCSV = const ListToCsvConverter().convert(templatesRows);
  archive.addFile(ArchiveFile(
      'exercise_templates.csv', templatesCSV.length, templatesCSV.codeUnits));

  final setsRows = [
    [
      'id',
      'exercise_template_id',
      'date_time',
      'equipment_weight',
      'plates_weight',
      'repetitions'
    ],
    ['1', '1', '2023-01-01T10:00:00.000Z', '0.0', '20.0', '10'],
    ['2', '2', '2023-01-02T11:00:00.000Z', '0.0', '30.0', '15'],
  ];
  final setsCSV = const ListToCsvConverter().convert(setsRows);
  archive.addFile(
      ArchiveFile('exercise_sets.csv', setsCSV.length, setsCSV.codeUnits));

  final zipFile = File(path.join(tempDir.path, 'test_data.zip'));
  await zipFile.writeAsBytes(ZipEncoder().encode(archive));
  return zipFile;
}

Future<File> _createInvalidEnumZipFile(Directory tempDir) async {
  final archive = Archive();

  final templatesRows = [
    ['id', 'name', 'muscle_group', 'repetitions_range', 'description'],
    ['1', 'Push-up', '99999', '1', 'Basic push-up exercise'],
  ];
  final templatesCSV = const ListToCsvConverter().convert(templatesRows);
  archive.addFile(ArchiveFile(
      'exercise_templates.csv', templatesCSV.length, templatesCSV.codeUnits));

  final zipFile = File(path.join(tempDir.path, 'invalid_enum_data.zip'));
  await zipFile.writeAsBytes(ZipEncoder().encode(archive));
  return zipFile;
}
