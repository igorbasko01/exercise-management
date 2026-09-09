import 'dart:io';

import 'package:archive/archive.dart';
import 'package:exercise_management/core/csv_serializer.dart';
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/services/export_sink.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/presentation/view_models/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;

class MockExerciseTemplateRepository extends Mock
    implements ExerciseTemplateRepository {}

class MockExerciseSetRepository extends Mock implements ExerciseSetRepository {}

class MockExerciseProgramRepository extends Mock
    implements ExerciseProgramRepository {}

/// Stands in for the platform-specific [ExportSink] so the view model can be
/// tested without touching the filesystem or a browser.
class FakeExportSink implements ExportSink {
  Result<ExportLocation>? nextResult;
  String? lastFileName;
  List<int>? lastBytes;

  @override
  Future<Result<ExportLocation>> store(String fileName, List<int> bytes) async {
    lastFileName = fileName;
    lastBytes = bytes;
    return nextResult ??
        Result.ok(const ExportLocation(description: 'fake/downloads'));
  }
}

void main() {
  group('SettingsViewModel exportDataCommand', () {
    late SettingsViewModel viewModel;
    late MockExerciseTemplateRepository mockTemplateRepository;
    late MockExerciseSetRepository mockSetRepository;
    late MockExerciseProgramRepository mockProgramRepository;
    late FakeExportSink fakeExportSink;

    final dummyTemplate = ExerciseTemplate(
        id: '1',
        name: 'Push-up',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium,
        description: 'Basic push-up exercise');

    final dummySet = ExerciseSet(
        id: '1',
        exerciseTemplateId: '1',
        dateTime: DateTime.parse('2023-01-01T10:00:00.000Z'),
        equipmentWeight: 0.0,
        platesWeight: 20.0,
        repetitions: 10);

    setUp(() {
      mockTemplateRepository = MockExerciseTemplateRepository();
      mockSetRepository = MockExerciseSetRepository();
      mockProgramRepository = MockExerciseProgramRepository();
      fakeExportSink = FakeExportSink();
      viewModel = SettingsViewModel(
        templatesRepository: mockTemplateRepository,
        setsRepository: mockSetRepository,
        programsRepository: mockProgramRepository,
        exportSink: fakeExportSink,
      );

      when(() => mockTemplateRepository.getExercises())
          .thenAnswer((_) async => Result.ok([dummyTemplate]));
      when(() => mockSetRepository.getExercises())
          .thenAnswer((_) async => Result.ok([dummySet]));
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok(<ExerciseProgram>[]));
    });

    test('builds a zip in memory and hands it to the sink without touching '
        'the filesystem', () async {
      await viewModel.exportDataCommand.execute();

      expect(viewModel.exportDataCommand.result, isA<Ok<ExportedFile>>());
      expect(fakeExportSink.lastFileName, isNotNull);
      expect(fakeExportSink.lastFileName, endsWith('.zip'));
      expect(fakeExportSink.lastBytes, isNotEmpty);

      final archive = ZipDecoder().decodeBytes(fakeExportSink.lastBytes!);
      final fileNames = archive.map((f) => f.name).toSet();
      expect(
          fileNames,
          containsAll([
            'exercise_templates.csv',
            'exercise_sets.csv',
            'exercise_programs.csv',
            'exercise_program_sessions.csv',
            'session_exercises.csv',
          ]));
    });

    test('surfaces the sink location description and file path on success',
        () async {
      fakeExportSink.nextResult = Result.ok(const ExportLocation(
          description: '/storage/emulated/0/Download',
          filePath: '/storage/emulated/0/Download/backup.zip'));

      await viewModel.exportDataCommand.execute();

      final result =
          viewModel.exportDataCommand.result as Ok<ExportedFile>;
      expect(result.value.locationDescription, '/storage/emulated/0/Download');
      expect(result.value.filePath, '/storage/emulated/0/Download/backup.zip');
    });

    test('returns an error when a repository fetch fails', () async {
      when(() => mockSetRepository.getExercises()).thenAnswer(
          (_) async => Result.error(ExerciseDatabaseException('boom')));

      await viewModel.exportDataCommand.execute();

      expect(viewModel.exportDataCommand.result, isA<Error<ExportedFile>>());
      expect(fakeExportSink.lastBytes, isNull);
    });

    test('returns an error when the sink fails to store the file', () async {
      fakeExportSink.nextResult =
          Result.error(ExportException('disk full'));

      await viewModel.exportDataCommand.execute();

      expect(viewModel.exportDataCommand.result, isA<Error<ExportedFile>>());
    });
  });

  group('SettingsViewModel importDataCommand', () {
    late SettingsViewModel viewModel;
    late MockExerciseTemplateRepository mockTemplateRepository;
    late MockExerciseSetRepository mockSetRepository;
    late MockExerciseProgramRepository mockProgramRepository;
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

    final dummyProgram = ExerciseProgram(
        id: 'fallback',
        name: 'fallback',
        sessions: []);

    setUpAll(() {
      registerFallbackValue(dummyTemplate);
      registerFallbackValue(dummySet);
      registerFallbackValue(dummyProgram);
    });

    setUp(() async {
      mockTemplateRepository = MockExerciseTemplateRepository();
      mockSetRepository = MockExerciseSetRepository();
      mockProgramRepository = MockExerciseProgramRepository();
      viewModel = SettingsViewModel(
        templatesRepository: mockTemplateRepository,
        setsRepository: mockSetRepository,
        programsRepository: mockProgramRepository,
        exportSink: FakeExportSink(),
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

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
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
      verify(() => mockProgramRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.clearAll()).called(1);
      verify(() => mockSetRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.addExercise(any())).called(2);
      verify(() => mockSetRepository.addExercise(any())).called(2);
    });

    test('should successfully import valid zip file with programs', () async {
      final zipFile = await _createValidZipFileWithPrograms(tempDir);

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
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
      when(() => mockProgramRepository.addProgram(any()))
          .thenAnswer((invocation) async {
        return Result.ok(dummyProgram);
      });

      await viewModel.importDataCommand.execute(zipFile.path);

      expect(viewModel.importDataCommand.result, isA<Ok<void>>());
      verify(() => mockProgramRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.clearAll()).called(1);
      verify(() => mockSetRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.addExercise(any())).called(2);
      verify(() => mockSetRepository.addExercise(any())).called(2);
      verify(() => mockProgramRepository.addProgram(any())).called(1);
    });

    test('should return error when zip file does not exist', () async {
      final nonExistentFilePath = path.join(tempDir.path, 'non_existent.zip');

      await viewModel.importDataCommand.execute(nonExistentFilePath);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockProgramRepository.clearAll());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when zip file is invalid', () async {
      final invalidZipFile = File(path.join(tempDir.path, 'invalid.zip'));
      await invalidZipFile.writeAsString('This is not a valid zip file');

      await viewModel.importDataCommand.execute(invalidZipFile.path);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockProgramRepository.clearAll());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when clearing templates fails', () async {
      final zipFile = await _createValidZipFile(tempDir);

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
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
      verify(() => mockProgramRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.clearAll()).called(1);
      verify(() => mockSetRepository.clearAll()).called(1);
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when clearing sets fails', () async {
      final zipFile = await _createValidZipFile(tempDir);

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockSetRepository.clearAll()).thenAnswer((invocation) async {
        return Result.error(ExerciseDatabaseException('Failed to clear sets'));
      });

      await viewModel.importDataCommand.execute(zipFile.path);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verify(() => mockProgramRepository.clearAll()).called(1);
      verifyNever(() => mockTemplateRepository.clearAll());
      verify(() => mockSetRepository.clearAll()).called(1);
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when clearing programs fails', () async {
      final zipFile = await _createValidZipFile(tempDir);

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.error(
            ExerciseDatabaseException('Failed to clear programs'));
      });

      await viewModel.importDataCommand.execute(zipFile.path);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verify(() => mockProgramRepository.clearAll()).called(1);
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when template has invalid enum value', () async {
      final zipFile = await _createInvalidEnumZipFile(tempDir);

      await viewModel.importDataCommand.execute(zipFile.path);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockProgramRepository.clearAll());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
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

Future<File> _createValidZipFileWithPrograms(Directory tempDir) async {
  final archive = Archive();

  // Create templates
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

  // Create sets
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

  // Create programs
  final programsMaps = [
    {'id': '1', 'name': 'Strength Program', 'description': 'A strength training program', 'is_active': '1'},
  ];
  final programsCSV = CsvSerializer.toCSV(programsMaps);
  archive.addFile(ArchiveFile(
      'exercise_programs.csv', programsCSV.length, programsCSV.codeUnits));

  // Create program sessions
  final sessionsMaps = [
    {'id': '10', 'program_id': '1', 'name': 'Day 1 - Upper Body', 'description': 'Upper body workout'},
    {'id': '11', 'program_id': '1', 'name': 'Day 2 - Lower Body', 'description': null},
  ];
  final sessionsCSV = CsvSerializer.toCSV(sessionsMaps);
  archive.addFile(ArchiveFile('exercise_program_sessions.csv',
      sessionsCSV.length, sessionsCSV.codeUnits));

  // Create session exercises links
  final linksMaps = [
    {'session_id': '10', 'exercise_template_id': '1', 'ordering': 0},
    {'session_id': '11', 'exercise_template_id': '2', 'ordering': 0},
  ];
  final linksCSV = CsvSerializer.toCSV(linksMaps);
  archive.addFile(ArchiveFile(
      'session_exercises.csv', linksCSV.length, linksCSV.codeUnits));

  final zipFile = File(path.join(tempDir.path, 'test_data_with_programs.zip'));
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
